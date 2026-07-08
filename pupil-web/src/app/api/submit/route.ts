import { NextRequest, NextResponse } from 'next/server';
import { supabase } from '@/lib/supabase';
import { submitFormSchema } from '@/lib/validators';

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();

    const zodResult = submitFormSchema.safeParse(body);
    if (!zodResult.success) {
      const firstErr = zodResult.error.errors[0];
      return NextResponse.json(
        { error: firstErr?.message || 'Validation failed' },
        { status: 400 },
      );
    }

    const { link_token, first_name, last_name, email, phone, address, postcode,
      pickup_location, dropoff_location, preferred_days, preferred_times,
      learning_goals, experience_level, emergency_contact_name, emergency_contact_phone, notes
    } = zodResult.data;

    // Validate invite link
    const { data: link, error: linkErr } = await supabase
      .from('pupil_invite_links')
      .select('id, instructor_id, is_active, expires_at')
      .eq('token', link_token)
      .single();

    if (linkErr || !link) {
      return NextResponse.json({ error: 'Invalid invite link' }, { status: 404 });
    }

    if (!link.is_active) {
      return NextResponse.json({ error: 'Invite link is inactive' }, { status: 410 });
    }

    if (link.expires_at && new Date(link.expires_at) < new Date()) {
      return NextResponse.json({ error: 'Invite link has expired' }, { status: 410 });
    }

    // Check for existing submission
    const { data: existing } = await supabase
      .from('pupil_invite_submissions')
      .select('id, status')
      .eq('link_id', link.id)
      .eq('email', email.toLowerCase())
      .single();

    if (existing) {
      return NextResponse.json({
        error: 'Already registered',
        status: existing.status,
        pupil_token: null,
      }, { status: 409 });
    }

    // Generate unique pupil token
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    let pupilToken = '';
    for (let i = 0; i < 8; i++) {
      pupilToken += chars[Math.floor(Math.random() * chars.length)];
    }

    // Insert submission
    const { data: submission, error: insertErr } = await supabase
      .from('pupil_invite_submissions')
      .insert({
        link_id: link.id,
        instructor_id: link.instructor_id,
        pupil_token: pupilToken,
        first_name: first_name.trim(),
        last_name: last_name.trim(),
        email: email.trim().toLowerCase(),
        phone: phone?.trim() || null,
        address: address?.trim() || null,
        postcode: postcode?.trim() || null,
        pickup_location: pickup_location?.trim() || null,
        dropoff_location: dropoff_location?.trim() || null,
        preferred_days: Array.isArray(preferred_days) && preferred_days.length > 0 ? preferred_days : null,
        preferred_times: Array.isArray(preferred_times) && preferred_times.length > 0 ? preferred_times : null,
        learning_goals: learning_goals?.trim() || null,
        experience_level: experience_level || null,
        emergency_contact_name: emergency_contact_name?.trim() || null,
        emergency_contact_phone: emergency_contact_phone?.trim() || null,
        notes: notes?.trim() || null,
        status: 'pending',
      })
      .select('id, pupil_token, status, created_at')
      .single();

    if (insertErr) {
      console.error('Insert error:', insertErr);
      return NextResponse.json({ error: 'Failed to submit' }, { status: 500 });
    }

    return NextResponse.json({
      success: true,
      pupil_token: submission.pupil_token,
      status: submission.status,
      created_at: submission.created_at,
    });
  } catch (err) {
    console.error('API error:', err);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
