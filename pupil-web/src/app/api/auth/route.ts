import { NextRequest, NextResponse } from 'next/server';
import { getSupabaseAdmin } from '@/lib/supabase';

// Generate a new invite link for an instructor
export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { instructor_id, max_submissions, expires_in_days } = body;

    if (!instructor_id) {
      return NextResponse.json({ error: 'instructor_id required' }, { status: 400 });
    }

    const supabase = getSupabaseAdmin();

    // Check if instructor already has an active link
    const { data: existing } = await supabase
      .from('pupil_invite_links')
      .select('id, token')
      .eq('instructor_id', instructor_id)
      .eq('is_active', true)
      .single();

    if (existing) {
      return NextResponse.json({
        token: existing.token,
        message: 'Using existing active link',
      });
    }

    // Generate unique token
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
    let token = '';
    for (let i = 0; i < 12; i++) {
      token += chars[Math.floor(Math.random() * chars.length)];
    }

    const expiresAt = expires_in_days
      ? new Date(Date.now() + expires_in_days * 86400000).toISOString()
      : null;

    const { data: link, error } = await supabase
      .from('pupil_invite_links')
      .insert({
        instructor_id,
        token,
        max_submissions: max_submissions || null,
        expires_at: expiresAt,
      })
      .select('id, token, created_at')
      .single();

    if (error) {
      console.error('Insert error:', error);
      return NextResponse.json({ error: 'Failed to create link' }, { status: 500 });
    }

    return NextResponse.json({ token: link.token, created_at: link.created_at });
  } catch (err) {
    console.error('API error:', err);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

// Get instructor's invite link and stats
export async function GET(req: NextRequest) {
  try {
    const { searchParams } = new URL(req.url);
    const instructorId = searchParams.get('instructor_id');

    if (!instructorId) {
      return NextResponse.json({ error: 'instructor_id required' }, { status: 400 });
    }

    const supabase = getSupabaseAdmin();

    const { data: link } = await supabase
      .from('pupil_invite_links')
      .select('*')
      .eq('instructor_id', instructorId)
      .eq('is_active', true)
      .single();

    if (!link) {
      return NextResponse.json({ link: null, submissions: [] });
    }

    const { data: submissions } = await supabase
      .from('pupil_invite_submissions')
      .select('*')
      .eq('link_id', link.id)
      .order('created_at', { ascending: false });

    return NextResponse.json({
      link,
      submissions: submissions || [],
      stats: {
        total: submissions?.length || 0,
        pending: submissions?.filter((s) => s.status === 'pending').length || 0,
        approved: submissions?.filter((s) => s.status === 'approved').length || 0,
        rejected: submissions?.filter((s) => s.status === 'rejected').length || 0,
      },
    });
  } catch (err) {
    console.error('API error:', err);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

// Deactivate an invite link
export async function DELETE(req: NextRequest) {
  try {
    const { searchParams } = new URL(req.url);
    const linkId = searchParams.get('link_id');
    const instructorId = searchParams.get('instructor_id');

    if (!linkId || !instructorId) {
      return NextResponse.json({ error: 'Missing params' }, { status: 400 });
    }

    const supabase = getSupabaseAdmin();

    const { error } = await supabase
      .from('pupil_invite_links')
      .update({ is_active: false })
      .eq('id', linkId)
      .eq('instructor_id', instructorId);

    if (error) {
      return NextResponse.json({ error: 'Failed' }, { status: 500 });
    }

    return NextResponse.json({ success: true });
  } catch (err) {
    console.error('API error:', err);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
