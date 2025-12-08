import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.0.0";
import { create, getNumericDate } from "https://deno.land/x/djwt@v2.8/mod.ts";

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

        // Fetch FCM Tokens
        const { data: tokens, error } = await supabase
            .from("user_fcm_tokens")
            .select("fcm_token")
            .eq("user_id", user_id);

        if (error || !tokens || tokens.length === 0) {
            console.log(`No tokens found for user ${user_id}`);
            return new Response(JSON.stringify({ message: "No tokens found" }), {
                headers: { "Content-Type": "application/json" },
            });
        }

        const serviceAccountStr = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
        if (!serviceAccountStr) {
            throw new Error("Missing FIREBASE_SERVICE_ACCOUNT environment variable");
        }

        const serviceAccount = JSON.parse(serviceAccountStr);
        const accessToken = await getAccessToken(serviceAccount);
        const projectId = serviceAccount.project_id;

        const results = await Promise.all(
            tokens.map(async (t) => {
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
            })
        );

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