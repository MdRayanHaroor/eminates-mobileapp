import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.0.0";
import { create, getNumericDate } from "https://deno.land/x/djwt@v2.8/mod.ts";
import { Resend } from "https://esm.sh/resend";

console.log("Hello from send-fcm!");

interface NotificationPayload {
    user_id: string;
    title: string;
    body: string;
    data?: Record<string, string>;
}

async function getAccessToken(serviceAccount: any) {
    const now = Math.floor(Date.now() / 1000);
    const claim = {
        iss: serviceAccount.client_email,
        scope: "https://www.googleapis.com/auth/firebase.messaging",
        aud: "https://oauth2.googleapis.com/token",
        exp: getNumericDate(3600), // Updated to use djwt helper
        iat: getNumericDate(0),
    };

    // --- FIX: Convert PEM string to CryptoKey ---
    const pem = serviceAccount.private_key;

    // Remove headers, footers, and newlines to get the base64 body
    const binaryDerString = atob(
        pem.replace(/-----(BEGIN|END) PRIVATE KEY-----/g, "").replace(/\s/g, "")
    );

    // Convert base64 to byte array
    const binaryDer = new Uint8Array(binaryDerString.length);
    for (let i = 0; i < binaryDerString.length; i++) {
        binaryDer[i] = binaryDerString.charCodeAt(i);
    }

    // Import the key specifically for RSA-256 signing
    const key = await crypto.subtle.importKey(
        "pkcs8",
        binaryDer,
        { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
        true,
        ["sign"]
    );
    // --------------------------------------------

    // Sign the JWT using the CryptoKey object
    const jwt = await create({ alg: "RS256", typ: "JWT" }, claim, key);

    // Exchange JWT for access token
    const url = "https://oauth2.googleapis.com/token";
    const params = new URLSearchParams();
    params.append("grant_type", "urn:ietf:params:oauth:grant-type:jwt-bearer");
    params.append("assertion", jwt);

    const res = await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: params,
    });

    const data = await res.json();
    return data.access_token;
}

serve(async (req) => {
    try {
        // Parse body
        const input = await req.json();
        console.log("Incoming Payload:", JSON.stringify(input));

        let user_id, title, body, data;

        // Check if called via Supabase Webhook (which wraps data in 'record')
        if (input.record) {
            console.log("Detected Webhook Payload");
            user_id = input.record.user_id;
            title = input.record.title;
            body = input.record.message; // Mapping 'message' col to 'body'
            // Custom data could be entity details
            data = {
                entity_id: input.record.related_entity_id,
                entity_type: input.record.related_entity_type
            };
        } else {
            console.log("Detected Direct Payload");
            // Direct call
            user_id = input.user_id;
            title = input.title;
            body = input.body;
            data = input.data;
        }

        console.log(`Parsed Targets -> User: ${user_id}, Title: ${title}`);

        const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
        const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
        const supabase = createClient(supabaseUrl, supabaseServiceKey);

        const resendApiKey = Deno.env.get("RESEND_API_KEY");

        // Helper to determine sender email
        const getSenderEmail = (title: string): string => {
            const lowerTitle = title.toLowerCase();
            if (lowerTitle.includes("welcome")) {
                return "hello@eminates.com";
            } else if (
                lowerTitle.includes("new user signup") ||
                lowerTitle.includes("new investment request") ||
                lowerTitle.includes("utr submitted")
            ) {
                return "support@eminates.com";
            } else {
                return "admin@eminates.com";
            }
        };

        const resendFromEmail = getSenderEmail(title);

        console.log(`Determined Sender: ${resendFromEmail} for Title: "${title}"`);

        // Parallel Fetch: FCM Tokens & User Email
        const [tokensResult, userResult] = await Promise.all([
            supabase
                .from("user_fcm_tokens")
                .select("fcm_token")
                .eq("user_id", user_id),
            supabase.auth.admin.getUserById(user_id)
        ]);

        console.log("Tokens Result:", tokensResult);
        console.log("User Result:", userResult);

        const tokens = tokensResult.data;
        const tokensError = tokensResult.error;
        const user = userResult.data?.user;
        const userError = userResult.error;

        if (tokensError) console.error("Error fetching tokens:", tokensError);
        if (userError) console.error("Error fetching user:", userError);

        const promises = [];

        // 1. Initialize FCM Promises
        if (tokens && tokens.length > 0) {
            console.log(`Found ${tokens.length} FCM tokens for user ${user_id}`);
            const serviceAccountStr = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");

            if (serviceAccountStr) {
                const serviceAccount = JSON.parse(serviceAccountStr);
                // We get the access token once to reuse
                const accessTokenPromise = getAccessToken(serviceAccount).then(accessToken => {
                    const projectId = serviceAccount.project_id;
                    return tokens.map(async (t) => {
                        const message = {
                            message: {
                                token: t.fcm_token,
                                notification: {
                                    title: title,
                                    body: body,
                                },
                                data: data || {},
                            },
                        };

                        const res = await fetch(
                            `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
                            {
                                method: "POST",
                                headers: {
                                    "Content-Type": "application/json",
                                    Authorization: `Bearer ${accessToken}`,
                                },
                                body: JSON.stringify(message),
                            }
                        );
                        return res.json();
                    });
                });

                promises.push(accessTokenPromise.then(p => Promise.all(p)));
            } else {
                console.error("Missing FIREBASE_SERVICE_ACCOUNT environment variable");
            }
        } else {
            console.log(`No tokens found for user ${user_id}`);
        }

        // 2. Initialize Resend Email Promise
        if (resendApiKey && user && user.email) {
            const resend = new Resend(resendApiKey);
            console.log(`Sending email to ${user.email} from ${resendFromEmail}`);

            const emailPromise = resend.emails.send({
                from: resendFromEmail,
                to: user.email,
                subject: title,
                html: `<p>${body}</p>`
            })
                .then(data => {
                    console.log("Email sent successfully:", data);
                    return { type: 'email', result: data };
                })
                .catch(err => {
                    console.error("Error sending email:", err);
                    return { type: 'email', error: err };
                });

            promises.push(emailPromise);
        } else {
            if (!resendApiKey) console.log("RESEND_API_KEY not set, skipping email.");
            else if (!user || !user.email) console.log(`User ${user_id} has no email, skipping email.`);
        }

        // Wait for all notifications (FCM & Email)
        const results = await Promise.all(promises);

        return new Response(JSON.stringify(results), {
            headers: { "Content-Type": "application/json" },
        });

    } catch (error) {
        console.error(error);
        return new Response(JSON.stringify({ error: error.message }), {
            status: 500,
            headers: { "Content-Type": "application/json" },
        });
    }
});
