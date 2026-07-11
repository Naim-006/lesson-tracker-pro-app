import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { status: 200, headers: corsHeaders })
  }

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      console.error('Missing Authorization header')
      return new Response(JSON.stringify({ error: 'Unauthorized - no auth header' }), { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    const token = authHeader.replace('Bearer ', '')

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } }
    )

    const { data: { user }, error: authError } = await supabase.auth.getUser(token)
    if (authError || !user) {
      console.error('getUser failed:', authError?.message ?? 'user is null')
      return new Response(JSON.stringify({ error: `Unauthorized - ${authError?.message ?? 'invalid token'}` }), { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    const { data: profile } = await supabase
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .single()

    if (!profile || profile.role !== 'instructor') {
      return new Response(JSON.stringify({ error: 'Forbidden' }), { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    const { plan_id } = await req.json()
    if (!plan_id) {
      return new Response(JSON.stringify({ error: 'plan_id required' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    const { data: plan } = await supabase
      .from('subscription_plans')
      .select('*')
      .eq('id', plan_id)
      .eq('is_active', true)
      .single()

    if (!plan) {
      return new Response(JSON.stringify({ error: 'Plan not found' }), { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    const serviceKey = Deno.env.get('SERVICE_ROLE_KEY')
    const adminSupabase = serviceKey
      ? createClient(Deno.env.get('SUPABASE_URL')!, serviceKey)
      : supabase

    const { data: paymentConfig } = await adminSupabase
      .from('app_settings')
      .select('value')
      .eq('key', 'payment_config')
      .maybeSingle()

    const config = (paymentConfig?.value as Record<string, unknown>) ?? {}
    const stripeSecretKey = config['stripe_secret_key'] as string

    if (!stripeSecretKey) {
      return new Response(JSON.stringify({ error: 'Payment not configured. Contact admin.' }), { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    const stripeResponse = await fetch('https://api.stripe.com/v1/checkout/sessions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${stripeSecretKey}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        'mode': 'payment',
        'success_url': `${Deno.env.get('INVITE_BASE_URL') ?? 'https://lessontrackerpro.vercel.app'}/payment/success?session_id={CHECKOUT_SESSION_ID}`,
        'cancel_url': `${Deno.env.get('INVITE_BASE_URL') ?? 'https://lessontrackerpro.vercel.app'}/payment/cancelled`,
        'client_reference_id': user.id,
        'metadata[plan_id]': plan_id,
        'metadata[instructor_id]': user.id,
        'metadata[plan_name]': (plan['name'] as string) ?? '',
        'metadata[duration_months]': String(Number(plan['duration_months']) || 1),
        'line_items[0][price_data][currency]': 'gbp',
        'line_items[0][price_data][product_data][name]': (plan['name'] as string) ?? 'Subscription',
        'line_items[0][price_data][unit_amount]': String(Math.round((plan['price'] as number) * 100)),
        'line_items[0][quantity]': '1',
      }),
    })

    const session = await stripeResponse.json()

    if (!stripeResponse.ok) {
      return new Response(JSON.stringify({ error: session.error?.message ?? 'Stripe error' }), { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    return new Response(JSON.stringify({
      url: session.url,
      session_id: session.id,
    }), { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
  }
})
