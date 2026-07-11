import { NextRequest, NextResponse } from 'next/server';
import { getSupabaseAdmin } from '@/lib/supabase';

export async function POST(req: NextRequest) {
  const admin = getSupabaseAdmin();

  const { data: configRow } = await admin
    .from('app_settings')
    .select('value')
    .eq('key', 'payment_config')
    .single();

  const config = (configRow?.value as Record<string, unknown>) ?? {};
  const webhookSecret = config['webhook_secret'] as string;

  const body = await req.text();
  const sig = req.headers.get('stripe-signature') || '';

  if (webhookSecret) {
    const crypto = await import('crypto');
    const parts = sig.split(',');
    let timestamp = '';
    let signature = '';
    for (const part of parts) {
      const [k, v] = part.split('=');
      if (k === 't') timestamp = v;
      if (k === 'v1') signature = v;
    }
    const payload = `${timestamp}.${body}`;
    const expected = crypto.createHmac('sha256', webhookSecret).update(payload).digest('hex');
    if (expected !== signature) {
      return NextResponse.json({ error: 'Invalid signature' }, { status: 401 });
    }
  }

  let event;
  try {
    event = JSON.parse(body);
  } catch {
    return NextResponse.json({ error: 'Invalid payload' }, { status: 400 });
  }

  if (event.type === 'checkout.session.completed') {
    const session = event.data.object;
    const instructorId = session.metadata?.instructor_id;
    const planId = session.metadata?.plan_id;
    const planName = session.metadata?.plan_name;
    const amount = session.amount_total ? session.amount_total / 100 : 0;
    const durationMonths = parseInt(session.metadata?.duration_months || '1', 10);

    if (instructorId) {
      const now = new Date();
      const endDate = new Date(now);
      endDate.setMonth(endDate.getMonth() + durationMonths);

      await admin.from('instructor_subscriptions').insert({
        instructor_id: instructorId,
        plan_id: planId || null,
        plan_type: planName || 'Subscription',
        amount: amount,
        start_date: now.toISOString(),
        end_date: endDate.toISOString(),
        status: 'active',
        payment_status: 'paid',
        created_at: now.toISOString(),
      });

      await admin.from('instructor_payments').insert({
        instructor_id: instructorId,
        amount: amount,
        payment_date: now.toISOString(),
        status: 'completed',
        payment_method: 'stripe',
        description: `Subscription payment - ${planName || 'Plan'}`,
      });
    }
  }

  return NextResponse.json({ received: true });
}
