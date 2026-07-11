'use client';

import { useState, useEffect } from 'react';
import { supabase } from '@/lib/supabase';
import Link from 'next/link';
import StatusBadge from '@/components/StatusBadge';
import { submitFormSchema } from '@/lib/validators';

interface LinkData {
  id: string;
  instructor_id: string;
  is_active: boolean;
  expires_at: string | null;
  instructor_name?: string;
}

interface ExistingSubmission {
  id: string;
  status: string;
  created_at: string;
  reviewed_at: string | null;
  review_notes: string | null;
  first_name: string;
  last_name: string;
  email: string;
}

export default function PupilInvitePage({ params }: { params: { token: string } }) {
  const { token } = params;
  const [linkData, setLinkData] = useState<LinkData | null>(null);
  const [existingSubmission, setExistingSubmission] = useState<ExistingSubmission | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [submitted, setSubmitted] = useState(false);

  const [existingPupilEmail, setExistingPupilEmail] = useState('');
  const [form, setForm] = useState({
    first_name: '',
    last_name: '',
    email: '',
    phone: '',
    address: '',
    postcode: '',
    pickup_location: '',
    dropoff_location: '',
    preferred_days: [] as string[],
    preferred_times: [] as string[],
    learning_goals: '',
    experience_level: '',
    emergency_contact_name: '',
    emergency_contact_phone: '',
    notes: '',
  });

  useEffect(() => {
    loadLinkData();
  }, [token]);

  async function loadLinkData() {
    try {
      const { data: link, error: linkErr } = await supabase
        .from('pupil_invite_links')
        .select('id, instructor_id, is_active, expires_at')
        .eq('token', token)
        .single();

      if (linkErr || !link) {
        console.error('Invite link lookup failed:', { token, error: linkErr, link });
        setError('This invite link is invalid. Please ask your driving instructor to share their invite link from the Pupil Registration section of their app.');
        setLoading(false);
        return;
      }

      if (!link.is_active) {
        setError('This invite link is no longer active. Please contact your instructor for a new one.');
        setLoading(false);
        return;
      }

      if (link.expires_at && new Date(link.expires_at) < new Date()) {
        setError('This invite link has expired. Please ask your instructor for a new one.');
        setLoading(false);
        return;
      }

      // Get instructor name
      const { data: profile } = await supabase
        .from('profiles')
        .select('full_name')
        .eq('id', link.instructor_id)
        .single();

      const instructorName = profile?.full_name?.trim() || 'Your instructor';

      setLinkData({ ...link, instructor_name: instructorName });
      setLoading(false);
    } catch {
      setError('Something went wrong. Please try again.');
      setLoading(false);
    }
  }

  async function checkExistingSubmission(email: string) {
    if (!linkData || !email || !email.includes('@')) return;

    const { data } = await supabase
      .from('pupil_invite_submissions')
      .select('id, status, created_at, reviewed_at, review_notes, first_name, last_name, email')
      .eq('link_id', linkData.id)
      .eq('email', email)
      .single();

    if (data) {
      setExistingSubmission(data);
    } else {
      setExistingSubmission(null);
    }
  }

  function updateField(field: string, value: string | string[]) {
    setForm((prev) => ({ ...prev, [field]: value }));
    if (field === 'email') {
      checkExistingSubmission(value as string);
    }
  }

  async function checkPupilEmail(email: string) {
    if (!linkData || !email || !email.includes('@')) return;
    try {
      const res = await fetch(`/api/check-email?email=${encodeURIComponent(email)}&link_token=${encodeURIComponent(token)}`);
      const data = await res.json();
      setExistingPupilEmail(data.exists ? email : '');
    } catch {
      // ignore fetch errors
    }
  }

  function toggleDay(day: string) {
    setForm((prev) => ({
      ...prev,
      preferred_days: prev.preferred_days.includes(day)
        ? prev.preferred_days.filter((d) => d !== day)
        : [...prev.preferred_days, day],
    }));
  }

  function toggleTime(time: string) {
    setForm((prev) => ({
      ...prev,
      preferred_times: prev.preferred_times.includes(time)
        ? prev.preferred_times.filter((t) => t !== time)
        : [...prev.preferred_times, time],
    }));
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!linkData) return;

    const zodResult = submitFormSchema.safeParse({
      ...form,
      link_token: linkData.id,
    });

    if (!zodResult.success) {
      const firstErr = zodResult.error.errors[0];
      setError(firstErr?.message || 'Please check your form inputs.');
      return;
    }

    setSubmitting(true);
    setError('');

    try {
      const response = await fetch('/api/submit', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          link_token: token,
          first_name: form.first_name.trim(),
          last_name: form.last_name.trim(),
          email: form.email.trim().toLowerCase(),
          phone: form.phone.trim(),
          address: form.address.trim(),
          postcode: form.postcode.trim(),
          pickup_location: form.pickup_location.trim(),
          dropoff_location: form.dropoff_location.trim(),
          preferred_days: form.preferred_days,
          preferred_times: form.preferred_times,
          learning_goals: form.learning_goals.trim(),
          experience_level: form.experience_level,
          emergency_contact_name: form.emergency_contact_name.trim(),
          emergency_contact_phone: form.emergency_contact_phone.trim(),
          notes: form.notes.trim(),
        }),
      });

      const result = await response.json();

      if (!response.ok) {
        if (response.status === 409) {
          if (result?.error?.includes('already registered as a pupil')) {
            setError('This email is already registered as a pupil. Please sign in to your account instead.');
          } else {
            setError('You have already submitted a registration with this email. Check your status below.');
            checkExistingSubmission(form.email);
          }
        } else {
          setError(result?.error || 'Failed to submit. Please try again.');
        }
        setSubmitting(false);
        return;
      }

      setSubmitted(true);
      setExistingSubmission({
        id: result.id || '',
        status: 'pending',
        created_at: result.created_at || new Date().toISOString(),
        reviewed_at: null,
        review_notes: null,
        first_name: form.first_name,
        last_name: form.last_name,
        email: form.email,
      });
    } catch {
      setError('An unexpected error occurred. Please try again.');
    } finally {
      setSubmitting(false);
    }
  }

  if (loading) {
    return (
      <div className="auth-page">
        <div className="auth-card text-center">
          <div className="w-14 h-14 bg-[var(--sunset-light)] rounded-2xl flex items-center justify-center mx-auto mb-5">
            <span className="spinner spinner-sunset" style={{width: 28, height: 28, borderWidth: 3}} />
          </div>
          <h1 className="text-xl font-bold text-[var(--text-primary)] mb-2">Loading invite…</h1>
        </div>
      </div>
    );
  }

  if (error && !linkData) {
    return (
      <div className="auth-page">
        <div className="auth-card text-center">
          <div className="w-16 h-16 bg-[#fef2f2] border border-[#fecaca] rounded-2xl flex items-center justify-center mx-auto mb-5">
            <svg className="w-8 h-8 text-[#991b1b]" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
            </svg>
          </div>
          <p className="text-sm font-semibold text-[#991b1b] mb-6">{error}</p>
          <Link href="/" className="btn-secondary block w-full">Go Home</Link>
        </div>
      </div>
    );
  }

  if (submitted || existingSubmission) {
    const status = existingSubmission?.status || 'pending';
    const s = {
      pending: { title: 'Registration Submitted!', desc: 'Your instructor will review your registration shortly.', icon: '⏳', color: 'text-[#92400e]' },
      approved: { title: "You're Approved!", desc: 'Your instructor has approved your registration.', icon: '🎉', color: 'text-[#166534]' },
      rejected: { title: 'Registration Not Accepted', desc: existingSubmission?.review_notes || 'Your instructor was unable to accept this registration. Please contact them directly.', icon: '❌', color: 'text-[#991b1b]' },
    }[status]!;

    return (
      <div className="auth-page py-12">
        <div className="auth-card">
          <div className="text-center mb-6">
            <div className="text-5xl mb-4">{s.icon}</div>
            <h2 className="text-2xl font-bold text-[var(--text-primary)] mb-4">{s.title}</h2>
            <StatusBadge status={status} />
          </div>
          <p className="text-center text-sm text-[var(--text-secondary)] mb-6 font-medium">{s.desc}</p>
          
          {status === 'approved' && (
            <div className="mb-6 p-5 bg-[#f0fdf4] rounded-xl border border-[#bbf7d0]">
               <p className="text-sm font-bold text-[#166534] mb-3">Next Step: Setup App</p>
               <ol className="text-sm text-[#15803d] space-y-2 list-decimal list-inside font-medium">
                 <li>Download the <strong>Lesson Tracker Pro</strong> app</li>
                 <li>Select <strong>"I'm a Pupil"</strong></li>
                 <li>Sign up using your email: <br/><strong className="ml-5 bg-white px-2 py-0.5 rounded border border-[#bbf7d0] mt-1 inline-block">{existingSubmission?.email || form.email}</strong></li>
               </ol>
            </div>
          )}
          
          {status === 'pending' && (
            <div className="mb-6 p-4 bg-[#fffbeb] rounded-xl border border-[#fde68a] text-center">
              <p className="text-sm font-medium text-[#92400e]">
                You can check your status anytime by following the link we sent to your email.
              </p>
            </div>
          )}

          {status === 'rejected' && existingSubmission?.review_notes && (
             <div className="mb-6 p-5 bg-[var(--surface-2)] rounded-xl border border-[var(--border)]">
               <p className="text-xs font-bold text-[var(--text-muted)] uppercase mb-2">Instructor's note</p>
               <p className="text-sm font-medium text-[var(--text-primary)]">{existingSubmission.review_notes}</p>
             </div>
          )}
          
          <div className="text-center">
             <Link href="/" className="btn-secondary inline-block">Return to Home</Link>
          </div>
        </div>
      </div>
    );
  }

  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const times = ['Morning', 'Afternoon', 'Evening'];

  const fieldsetLabel = "text-sm font-bold tracking-widest uppercase text-[var(--text-muted)] mb-4 pb-2 border-b border-[var(--border)]";

  return (
    <div className="auth-page py-12 h-auto shrink-0 items-start">
      <div className="auth-card max-w-2xl w-full" style={{padding: '2.5rem'}}>
        {/* Header */}
        <div className="flex items-center gap-4 mb-8 pb-6 border-b border-[var(--border)]">
          <Link href="/" className="w-12 h-12 bg-gradient-to-br from-[#f3751f] to-[#e05a0c] rounded-xl flex items-center justify-center shadow-[var(--shadow-sunset)] shrink-0">
            <span className="text-white font-black text-xl">L</span>
          </Link>
          <div>
            <h1 className="text-2xl font-bold text-[var(--text-primary)]">Pupil Registration</h1>
            <p className="text-sm text-[var(--text-muted)] mt-1">Invited by <strong className="text-[var(--text-primary)]">{linkData?.instructor_name}</strong></p>
          </div>
        </div>

        {error && (
          <div className="alert-error mb-6">
            <svg className="w-4 h-4 flex-shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
               <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm.75-11.25a.75.75 0 00-1.5 0v4.5a.75.75 0 001.5 0v-4.5zM10 15a1 1 0 100-2 1 1 0 000 2z" clipRule="evenodd" />
            </svg>
            <span>{error}</span>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-10">
          
          {/* Section 1: Personal */}
          <fieldset>
            <legend className={fieldsetLabel}>1. Personal Info</legend>
            <div className="space-y-4">
              <div className="grid md:grid-cols-2 gap-4">
                <div>
                  <label className="field-label">First Name *</label>
                  <input type="text" required value={form.first_name} onChange={(e) => updateField('first_name', e.target.value)} className="field-input" placeholder="Emma" />
                </div>
                <div>
                  <label className="field-label">Last Name *</label>
                  <input type="text" required value={form.last_name} onChange={(e) => updateField('last_name', e.target.value)} className="field-input" placeholder="Watson" />
                </div>
              </div>
              <div>
                <label className="field-label">Email Address *</label>
                <input
                  type="email" required value={form.email}
                  onChange={(e) => updateField('email', e.target.value)}
                  onBlur={() => checkPupilEmail(form.email)}
                  className="field-input" placeholder="emma@example.com"
                />
                {existingPupilEmail === form.email && (
                  <p className="text-sm text-red-600 mt-1.5 flex items-center gap-1.5 font-medium">
                    <svg className="w-4 h-4 shrink-0" fill="currentColor" viewBox="0 0 20 20">
                      <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm.75-11.25a.75.75 0 00-1.5 0v4.5a.75.75 0 001.5 0v-4.5zM10 15a1 1 0 100-2 1 1 0 000 2z" clipRule="evenodd" />
                    </svg>
                    This email is already registered as a pupil — sign in instead of submitting a new registration.
                  </p>
                )}
              </div>
              <div>
                <label className="field-label">Phone Number</label>
                <input type="tel" value={form.phone} onChange={(e) => updateField('phone', e.target.value)} className="field-input" placeholder="+44 7000 000000" />
              </div>
            </div>
          </fieldset>

          {/* Section 2: Location */}
          <fieldset>
             <legend className={fieldsetLabel}>2. Location</legend>
             <div className="space-y-4">
               <div>
                 <label className="field-label">Address</label>
                 <input type="text" value={form.address} onChange={(e) => updateField('address', e.target.value)} className="field-input" placeholder="123 High Street, London" />
               </div>
               <div>
                 <label className="field-label">Postcode</label>
                 <input type="text" value={form.postcode} onChange={(e) => updateField('postcode', e.target.value)} className="field-input" placeholder="SW1A 1AA" />
               </div>
               <div className="grid md:grid-cols-2 gap-4 mt-2">
                 <div>
                   <label className="field-label">Pickup Location</label>
                   <input type="text" value={form.pickup_location} onChange={(e) => updateField('pickup_location', e.target.value)} className="field-input" placeholder="e.g. Home or College" />
                 </div>
                 <div>
                   <label className="field-label">Dropoff Location</label>
                   <input type="text" value={form.dropoff_location} onChange={(e) => updateField('dropoff_location', e.target.value)} className="field-input" placeholder="e.g. Same as pickup" />
                 </div>
               </div>
             </div>
          </fieldset>

          {/* Section 3: Availability */}
          <fieldset>
             <legend className={fieldsetLabel}>3. Availability</legend>
             <div className="space-y-5">
               <div>
                 <label className="field-label">Preferred Days</label>
                 <div className="flex flex-wrap gap-2">
                   {days.map((day) => {
                     const active = form.preferred_days.includes(day);
                     return (
                       <button
                         key={day}
                         type="button"
                         onClick={() => toggleDay(day)}
                         className={`px-4 py-2 rounded-xl text-sm font-semibold transition-all border-2 ${
                           active ? 'bg-[var(--sunset-light)] text-[var(--sunset)] border-[var(--sunset)]' : 'bg-transparent text-[var(--text-secondary)] border-[var(--border-strong)] hover:border-[var(--sunset)] hover:text-[var(--text-primary)]'
                         }`}
                       >
                         {day}
                       </button>
                     );
                   })}
                 </div>
               </div>
               <div>
                 <label className="field-label">Preferred Times</label>
                 <div className="flex flex-wrap gap-2">
                   {times.map((time) => {
                      const active = form.preferred_times.includes(time);
                      return (
                       <button
                         key={time}
                         type="button"
                         onClick={() => toggleTime(time)}
                         className={`px-4 py-2 rounded-xl text-sm font-semibold transition-all border-2 ${
                           active ? 'bg-[var(--sunset-light)] text-[var(--sunset)] border-[var(--sunset)]' : 'bg-transparent text-[var(--text-secondary)] border-[var(--border-strong)] hover:border-[var(--sunset)] hover:text-[var(--text-primary)]'
                         }`}
                       >
                         {time}
                       </button>
                      )
                   })}
                 </div>
               </div>
             </div>
          </fieldset>

          {/* Section 4: Learning */}
          <fieldset>
             <legend className={fieldsetLabel}>4. Learning History</legend>
             <div className="space-y-4">
                <div>
                   <label className="field-label">Experience Level</label>
                   <select value={form.experience_level} onChange={(e) => updateField('experience_level', e.target.value)} className="field-input bg-white">
                      <option value="">Select an option...</option>
                      <option value="complete_beginner">Complete Beginner</option>
                      <option value="some_experience">Some Experience</option>
                      <option value="previously_learnt">Previously Learnt</option>
                      <option value="need_practice">Need Practice</option>
                      <option value="test_ready">Ready for Test</option>
                   </select>
                </div>
                <div>
                   <label className="field-label">Learning Goals</label>
                   <textarea rows={3} value={form.learning_goals} onChange={(e) => updateField('learning_goals', e.target.value)} className="field-input resize-y min-h-[80px]" placeholder="e.g. Pass test in 3 months..." />
                </div>
             </div>
          </fieldset>

          {/* Section 5: Emergency */}
          <fieldset>
             <legend className={fieldsetLabel}>5. Emergency Contact</legend>
             <div className="grid md:grid-cols-2 gap-4">
                <div>
                   <label className="field-label">Contact Name</label>
                   <input type="text" value={form.emergency_contact_name} onChange={(e) => updateField('emergency_contact_name', e.target.value)} className="field-input" placeholder="Relation & Name" />
                </div>
                <div>
                   <label className="field-label">Contact Phone</label>
                   <input type="tel" value={form.emergency_contact_phone} onChange={(e) => updateField('emergency_contact_phone', e.target.value)} className="field-input" placeholder="+44 7XXX XXX XXX" />
                </div>
             </div>
          </fieldset>
          
          <div className="pt-2">
             <label className="field-label">Additional Notes</label>
             <textarea rows={2} value={form.notes} onChange={(e) => updateField('notes', e.target.value)} className="field-input resize-y min-h-[80px]" placeholder="Anything else you'd like your instructor to know?" />
          </div>

          <button type="submit" disabled={submitting || existingPupilEmail === form.email} className="btn-primary w-full py-4 text-base">
            {submitting ? <><span className="spinner" /> Submitting…</> : 'Submit Registration'}
          </button>
        </form>
      </div>
    </div>
  );
}
