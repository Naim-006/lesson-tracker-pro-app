import { NextRequest, NextResponse } from 'next/server';
import { getSupabaseAdmin } from '@/lib/supabase';

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { submission_id, action, review_notes, instructor_id } = body;

    if (!submission_id || !action || !instructor_id) {
      return NextResponse.json({ error: 'Missing required fields' }, { status: 400 });
    }

    if (!['approve', 'reject'].includes(action)) {
      return NextResponse.json({ error: 'Invalid action' }, { status: 400 });
    }

    const supabase = getSupabaseAdmin();

    // Verify the submission belongs to this instructor
    const { data: submission, error: fetchErr } = await supabase
      .from('pupil_invite_submissions')
      .select('id, instructor_id, status')
      .eq('id', submission_id)
      .single();

    if (fetchErr || !submission) {
      return NextResponse.json({ error: 'Submission not found' }, { status: 404 });
    }

    if (submission.instructor_id !== instructor_id) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 403 });
    }

    const newStatus = action === 'approve' ? 'approved' : 'rejected';

    const { error: updateErr } = await supabase
      .from('pupil_invite_submissions')
      .update({
        status: newStatus,
        reviewed_at: new Date().toISOString(),
        review_notes: review_notes?.trim() || null,
      })
      .eq('id', submission_id);

    if (updateErr) {
      console.error('Update error:', updateErr);
      return NextResponse.json({ error: 'Failed to update' }, { status: 500 });
    }

    // If approved, auto-create pupil records
    if (action === 'approve') {
      const { data: sub } = await supabase
        .from('pupil_invite_submissions')
        .select('*')
        .eq('id', submission_id)
        .single();

      if (sub) {
        // Create auth user with temporary password (pupil will reset)
        const tempPassword = Math.random().toString(36).slice(-12) + 'A1!';

        const { data: authData, error: authErr } = await supabase.auth.admin.createUser({
          email: sub.email,
          password: tempPassword,
          email_confirm: true,
        });

        if (!authErr && authData?.user) {
          // Create profile
          await supabase.from('profiles').upsert({
            id: authData.user.id,
            email: sub.email,
            first_name: sub.first_name,
            last_name: sub.last_name,
            phone: sub.phone,
            role: 'pupil',
          });

          // Create pupil record
          const { data: pupil } = await supabase
            .from('pupils')
            .insert({
              profile_id: authData.user.id,
              first_name: sub.first_name,
              last_name: sub.last_name,
              email: sub.email,
              phone: sub.phone,
              address: sub.address,
              postcode: sub.postcode,
              pickup_location: sub.pickup_location,
              dropoff_location: sub.dropoff_location,
              status: 'current',
            })
            .select('id')
            .single();

          if (pupil) {
            // Link to instructor
            await supabase.from('instructor_pupil_links').insert({
              instructor_id: sub.instructor_id,
              pupil_id: pupil.id,
              status: 'active',
            });
          }

          // Send password reset email
          await supabase.auth.admin.inviteUserByEmail(sub.email, {
            redirectTo: `${process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000'}/auth/callback`,
          });
        }
      }
    }

    return NextResponse.json({ success: true, status: newStatus });
  } catch (err) {
    console.error('API error:', err);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
