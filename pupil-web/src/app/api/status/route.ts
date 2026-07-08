import { NextRequest, NextResponse } from 'next/server';
import { getSupabaseAdmin } from '@/lib/supabase';

export const dynamic = 'force-dynamic';

export async function GET(req: NextRequest) {
  try {
    const { searchParams } = new URL(req.url);
    const pupilToken = searchParams.get('token');

    if (!pupilToken) {
      return NextResponse.json({ error: 'Token required' }, { status: 400 });
    }

    const supabase = getSupabaseAdmin();

    const { data: submission, error } = await supabase
      .from('pupil_invite_submissions')
      .select('id, status, first_name, last_name, email, created_at, reviewed_at, review_notes, instructor_id')
      .eq('pupil_token', pupilToken.toUpperCase())
      .single();

    if (error || !submission) {
      return NextResponse.json({ error: 'Not found' }, { status: 404 });
    }

    // Get instructor name
    const { data: profile } = await supabase
      .from('profiles')
      .select('first_name, last_name')
      .eq('id', submission.instructor_id)
      .single();

    return NextResponse.json({
      ...submission,
      instructor_name: profile
        ? `${profile.first_name || ''} ${profile.last_name || ''}`.trim()
        : 'Your instructor',
    });
  } catch (err) {
    console.error('API error:', err);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
