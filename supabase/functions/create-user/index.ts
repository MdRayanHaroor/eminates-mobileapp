import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
    // Handle CORS preflight requests
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    try {
        // Create a Supabase client with the SERVICE_ROLE key to bypass RLS and create users
        const supabaseAdmin = createClient(
            Deno.env.get('SUPABASE_URL') ?? '',
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
            {
                auth: {
                    autoRefreshToken: false,
                    persistSession: false,
                },
            }
        )

        // Verify the caller is an authenticated admin
        const authHeader = req.headers.get('Authorization')!
        const token = authHeader.replace('Bearer ', '')
        const { data: { user }, error: userError } = await supabaseAdmin.auth.getUser(token)

        if (userError || !user) {
            return new Response(
                JSON.stringify({ error: 'Unauthorized' }),
                { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        // Check if the caller has 'admin' role in public.users
        const { data: adminUser, error: adminCheckError } = await supabaseAdmin
            .from('users')
            .select('role')
            .eq('id', user.id)
            .single()

        if (adminCheckError || adminUser?.role !== 'admin') {
            return new Response(
                JSON.stringify({ error: 'Forbidden: Only admins can create agents.' }),
                { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        // Parse request body
        const { email, password, fullName, commissionPercentage } = await req.json()

        if (!email || !password || !fullName) {
            return new Response(
                JSON.stringify({ error: 'Missing required fields' }),
                { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        console.log(`Creating agent user: ${email}`)

        // 1. Create the Auth User
        const { data: newUser, error: createError } = await supabaseAdmin.auth.admin.createUser({
            email: email,
            password: password,
            email_confirm: true, // Auto-confirm
            user_metadata: { full_name: fullName }
        })

        if (createError) {
            console.error('Error creating auth user:', createError)
            return new Response(
                JSON.stringify({ error: createError.message }),
                { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        if (!newUser.user) {
            throw new Error('User creation failed silently')
        }

        // 2. Update the public.users table with role and commission
        // Note: The handle_new_user trigger might have already inserted the user row.
        // We strictly update the role to 'agent' and set commission.
        const { error: updateError } = await supabaseAdmin
            .from('users')
            .update({
                role: 'agent',
                commission_percentage: commissionPercentage || 0,
                full_name: fullName // Ensure full name is synced
            })
            .eq('id', newUser.user.id)

        if (updateError) {
            console.error('Error updating public user:', updateError)
            // Attempt cleanup? Or just report error. 
            // Ideally DB constraints would handle this, but triggers are async or tricky.
            return new Response(
                JSON.stringify({ error: 'User created but failed to set agent details: ' + updateError.message }),
                { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        return new Response(
            JSON.stringify({ user: newUser.user, message: 'Agent created successfully' }),
            { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )

    } catch (error) {
        console.error('Unexpected error:', error)
        return new Response(
            JSON.stringify({ error: error.message }),
            { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
    }
})
