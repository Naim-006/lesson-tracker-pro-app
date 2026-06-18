'use client';

import { useState, useEffect, use } from 'react';
import { supabase } from '@/lib/supabase';
import AppLogo from '@/components/AppLogo';
import DeveloperFooter from '@/components/DeveloperFooter';
import StatusBadge from '@/components/StatusBadge';
import { formatDateTime } from '@/lib/utils';

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

export default function PupilInvitePage({ params }: { params: Promise<{ token: string }> }) {
  const { token } = use(params);
  const [linkData, setLinkData] = useState<LinkData | null>(null);
  const [existingSubmission, setExistingSubmission] = useState<ExistingSubmission | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [submitted, setSubmitted] = useState(false);

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
        setError('This invite link is invalid or has expired.');
        setLoading(false);
        return;
      }

      if (!link.is_active) {
        setError('This invite link is no longer active.');
        setLoading(false);
        return;
      }

      if (link.expires_at && new Date(link.expires_at) < new Date()) {
        setError('This invite link has expired.');
        setLoading(false);
        return;
      }

      // Get instructor name
      const { data: profile } = await supabase
        .from('profiles')
        .select('first_name, last_name')
        .eq('id', link.instructor_id)
        .single();

      const instructorName = profile
        ? `${profile.first_name || ''} ${profile.last_name || ''}`.trim()
        : 'Your instructor';

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

    // Validate required fields
    if (!form.first_name.trim() || !form.last_name.trim() || !form.email.trim()) {
      setError('Please fill in all required fields.');
      return;
    }

    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)) {
      setError('Please enter a valid email address.');
      return;
    }

    setSubmitting(true);
    setError('');

    try {
      // Generate unique pupil token
      const pupilToken = Math.random().toString(36).substring(2, 10).toUpperCase();

      const { error: insertErr } = await supabase.from('pupil_invite_submissions').insert({
        link_id: linkData.id,
        instructor_id: linkData.instructor_id,
        pupil_token: pupilToken,
        first_name: form.first_name.trim(),
        last_name: form.last_name.trim(),
        email: form.email.trim().toLowerCase(),
        phone: form.phone.trim() || null,
        address: form.address.trim() || null,
        postcode: form.postcode.trim() || null,
        pickup_location: form.pickup_location.trim() || null,
        dropoff_location: form.dropoff_location.trim() || null,
        preferred_days: form.preferred_days.length > 0 ? form.preferred_days : null,
        preferred_times: form.preferred_times.length > 0 ? form.preferred_times : null,
        learning_goals: form.learning_goals.trim() || null,
        experience_level: form.experience_level || null,
        emergency_contact_name: form.emergency_contact_name.trim() || null,
        emergency_contact_phone: form.emergency_contact_phone.trim() || null,
        notes: form.notes.trim() || null,
      });

      if (insertErr) {
        if (insertErr.message?.includes('unique')) {
          setError('You have already submitted a registration with this email. Check your status below.');
          checkExistingSubmission(form.email);
        } else {
          setError('Failed to submit. Please try again.');
        }
        setSubmitting(false);
        return;
      }

      setSubmitted(true);
      setExistingSubmission({
        id: '',
        status: 'pending',
        created_at: new Date().toISOString(),
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
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center animate-fade-in">
          <div className="w-12 h-12 border-4 border-sunset-200 border-t-sunset-500 rounded-full animate-spin mx-auto" />
          <p className="mt-4 text-gray-500">Loading...</p>
        </div>
      </div>
    );
  }

  if (error && !linkData) {
    return (
      <div className="min-h-screen flex items-center justify-center p-4">
        <div className="glass-card rounded-3xl p-8 max-w-md w-full text-center animate-fade-in">
          <AppLogo size="lg" />
          <div className="mt-6 p-4 bg-red-50 rounded-2xl border border-red-100">
            <p className="text-red-700 font-medium">{error}</p>
          </div>
          <DeveloperFooter />
        </div>
      </div>
    );
  }

  if (submitted || existingSubmission) {
    const status = existingSubmission?.status || 'pending';
    const statusMessages: Record<string, { title: string; desc: string; icon: string }> = {
      pending: {
        title: 'Registration Submitted!',
        desc: 'Your instructor will review your registration shortly. You will be notified once approved.',
        icon: '⏳',
      },
      approved: {
        title: 'You\'re Approved!',
        desc: 'Your instructor has approved your registration. You can now sign up for the Lesson Tracker app.',
        icon: '🎉',
      },
      rejected: {
        title: 'Registration Not Accepted',
        desc: existingSubmission?.review_notes || 'Your instructor was unable to accept this registration. Please contact them directly.',
        icon: '❌',
      },
    };

    const s = statusMessages[status] || statusMessages.pending;

    return (
      <div className="min-h-screen flex items-center justify-center p-4">
        <div className="glass-card rounded-3xl p-8 max-w-md w-full animate-fade-in">
          <AppLogo size="md" />
          <div className="mt-6 text-center">
            <div className="text-4xl mb-3">{s.icon}</div>
            <h2 className="text-xl font-bold text-gray-900">{s.title}</h2>
            <div className="mt-3">
              <StatusBadge status={status} />
            </div>
            <p className="mt-3 text-sm text-gray-600 leading-relaxed">{s.desc}</p>

            {status === 'approved' && (
              <div className="mt-6 p-4 bg-emerald-50 rounded-2xl border border-emerald-100">
                <p className="text-sm text-emerald-700 font-medium mb-2">
                  Next Step: Download the App
                </p>
                <p className="text-xs text-emerald-600">
                  Open the Lesson Tracker app, select <strong>&quot;I&apos;m a Pupil&quot;</strong>, and sign up using your email:
                </p>
                <p className="mt-2 text-sm font-mono font-semibold text-emerald-800 bg-white px-3 py-1.5 rounded-lg border border-emerald-200 inline-block">
                  {existingSubmission?.email || form.email}
                </p>
              </div>
            )}

            {status === 'pending' && (
              <div className="mt-4 p-4 bg-amber-50 rounded-2xl border border-amber-100">
                <p className="text-xs text-amber-700">
                  You can check your status anytime by visiting this link again.
                </p>
              </div>
            )}

            {status === 'rejected' && existingSubmission?.review_notes && (
              <div className="mt-4 p-4 bg-gray-50 rounded-2xl border border-gray-200">
                <p className="text-xs text-gray-500 font-medium">Instructor&apos;s note:</p>
                <p className="text-sm text-gray-700 mt-1">{existingSubmission.review_notes}</p>
              </div>
            )}
          </div>
          <DeveloperFooter />
        </div>
      </div>
    );
  }

  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const times = ['Morning', 'Afternoon', 'Evening'];

  return (
    <div className="min-h-screen p-4 md:p-8">
      <div className="max-w-lg mx-auto">
        <div className="glass-card rounded-3xl p-6 md:p-8 animate-fade-in">
          <AppLogo size="md" />

          <div className="mt-6 p-4 bg-sunset-50 rounded-2xl border border-sunset-100">
            <p className="text-sm text-sunset-800">
              You&apos;ve been invited by <strong>{linkData?.instructor_name}</strong> to register as a pupil.
              Please fill in the form below.
            </p>
          </div>

          {error && (
            <div className="mt-4 p-3 bg-red-50 rounded-xl border border-red-100 text-sm text-red-700 animate-fade-in">
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit} className="mt-6 space-y-5">
            {/* Personal Info */}
            <fieldset>
              <legend className="text-sm font-semibold text-gray-700 mb-3 flex items-center gap-2">
                <span className="w-6 h-6 bg-sunset-100 text-sunset-700 rounded-full flex items-center justify-center text-xs font-bold">1</span>
                Personal Information
              </legend>
              <div className="space-y-3">
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="block text-xs font-medium text-gray-600 mb-1">First Name *</label>
                    <input
                      type="text"
                      required
                      value={form.first_name}
                      onChange={(e) => updateField('first_name', e.target.value)}
                      className="w-full px-3 py-2.5 bg-white border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-sunset-200"
                      placeholder="John"
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-medium text-gray-600 mb-1">Last Name *</label>
                    <input
                      type="text"
                      required
                      value={form.last_name}
                      onChange={(e) => updateField('last_name', e.target.value)}
                      className="w-full px-3 py-2.5 bg-white border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-sunset-200"
                      placeholder="Smith"
                    />
                  </div>
                </div>
                <div>
                  <label className="block text-xs font-medium text-gray-600 mb-1">Email *</label>
                  <input
                    type="email"
                    required
                    value={form.email}
                    onChange={(e) => updateField('email', e.target.value)}
                    className="w-full px-3 py-2.5 bg-white border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-sunset-200"
                    placeholder="john@example.com"
                  />
                </div>
                <div>
                  <label className="block text-xs font-medium text-gray-600 mb-1">Phone</label>
                  <input
                    type="tel"
                    value={form.phone}
                    onChange={(e) => updateField('phone', e.target.value)}
                    className="w-full px-3 py-2.5 bg-white border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-sunset-200"
                    placeholder="+44 7XXX XXX XXX"
                  />
                </div>
              </div>
            </fieldset>

            {/* Location */}
            <fieldset>
              <legend className="text-sm font-semibold text-gray-700 mb-3 flex items-center gap-2">
                <span className="w-6 h-6 bg-sunset-100 text-sunset-700 rounded-full flex items-center justify-center text-xs font-bold">2</span>
                Location
              </legend>
              <div className="space-y-3">
                <div>
                  <label className="block text-xs font-medium text-gray-600 mb-1">Address</label>
                  <input
                    type="text"
                    value={form.address}
                    onChange={(e) => updateField('address', e.target.value)}
                    className="w-full px-3 py-2.5 bg-white border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-sunset-200"
                    placeholder="123 Main St, London"
                  />
                </div>
                <div>
                  <label className="block text-xs font-medium text-gray-600 mb-1">Postcode</label>
                  <input
                    type="text"
                    value={form.postcode}
                    onChange={(e) => updateField('postcode', e.target.value)}
                    className="w-full px-3 py-2.5 bg-white border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-sunset-200"
                    placeholder="SW1A 1AA"
                  />
                </div>
                <div>
                  <label className="block text-xs font-medium text-gray-600 mb-1">Pickup Location</label>
                  <input
                    type="text"
                    value={form.pickup_location}
                    onChange={(e) => updateField('pickup_location', e.target.value)}
                    className="w-full px-3 py-2.5 bg-white border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-sunset-200"
                    placeholder="Where should we pick you up?"
                  />
                </div>
                <div>
                  <label className="block text-xs font-medium text-gray-600 mb-1">Dropoff Location</label>
                  <input
                    type="text"
                    value={form.dropoff_location}
                    onChange={(e) => updateField('dropoff_location', e.target.value)}
                    className="w-full px-3 py-2.5 bg-white border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-sunset-200"
                    placeholder="Where should we drop you off?"
                  />
                </div>
              </div>
            </fieldset>

            {/* Availability */}
            <fieldset>
              <legend className="text-sm font-semibold text-gray-700 mb-3 flex items-center gap-2">
                <span className="w-6 h-6 bg-sunset-100 text-sunset-700 rounded-full flex items-center justify-center text-xs font-bold">3</span>
                Availability
              </legend>
              <div className="space-y-3">
                <div>
                  <label className="block text-xs font-medium text-gray-600 mb-2">Preferred Days</label>
                  <div className="flex flex-wrap gap-2">
                    {days.map((day) => (
                      <button
                        key={day}
                        type="button"
                        onClick={() => toggleDay(day)}
                        className={`px-3 py-1.5 rounded-lg text-xs font-medium border transition-all ${
                          form.preferred_days.includes(day)
                            ? 'bg-sunset-500 text-white border-sunset-500'
                            : 'bg-white text-gray-600 border-gray-200 hover:border-sunset-300'
                        }`}
                      >
                        {day}
                      </button>
                    ))}
                  </div>
                </div>
                <div>
                  <label className="block text-xs font-medium text-gray-600 mb-2">Preferred Times</label>
                  <div className="flex flex-wrap gap-2">
                    {times.map((time) => (
                      <button
                        key={time}
                        type="button"
                        onClick={() => toggleTime(time)}
                        className={`px-3 py-1.5 rounded-lg text-xs font-medium border transition-all ${
                          form.preferred_times.includes(time)
                            ? 'bg-sunset-500 text-white border-sunset-500'
                            : 'bg-white text-gray-600 border-gray-200 hover:border-sunset-300'
                        }`}
                      >
                        {time}
                      </button>
                    ))}
                  </div>
                </div>
              </div>
            </fieldset>

            {/* Learning */}
            <fieldset>
              <legend className="text-sm font-semibold text-gray-700 mb-3 flex items-center gap-2">
                <span className="w-6 h-6 bg-sunset-100 text-sunset-700 rounded-full flex items-center justify-center text-xs font-bold">4</span>
                Learning Details
              </legend>
              <div className="space-y-3">
                <div>
                  <label className="block text-xs font-medium text-gray-600 mb-1">Experience Level</label>
                  <select
                    value={form.experience_level}
                    onChange={(e) => updateField('experience_level', e.target.value)}
                    className="w-full px-3 py-2.5 bg-white border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-sunset-200"
                  >
                    <option value="">Select...</option>
                    <option value="complete_beginner">Complete Beginner</option>
                    <option value="some_experience">Some Experience</option>
                    <option value="previously_learnt">Previously Learnt</option>
                    <option value="need_practice">Need Practice</option>
                    <option value="test_ready">Ready for Test</option>
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-medium text-gray-600 mb-1">Learning Goals</label>
                  <textarea
                    value={form.learning_goals}
                    onChange={(e) => updateField('learning_goals', e.target.value)}
                    rows={2}
                    className="w-full px-3 py-2.5 bg-white border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-sunset-200 resize-none"
                    placeholder="What do you want to achieve?"
                  />
                </div>
              </div>
            </fieldset>

            {/* Emergency Contact */}
            <fieldset>
              <legend className="text-sm font-semibold text-gray-700 mb-3 flex items-center gap-2">
                <span className="w-6 h-6 bg-sunset-100 text-sunset-700 rounded-full flex items-center justify-center text-xs font-bold">5</span>
                Emergency Contact
              </legend>
              <div className="space-y-3">
                <div>
                  <label className="block text-xs font-medium text-gray-600 mb-1">Contact Name</label>
                  <input
                    type="text"
                    value={form.emergency_contact_name}
                    onChange={(e) => updateField('emergency_contact_name', e.target.value)}
                    className="w-full px-3 py-2.5 bg-white border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-sunset-200"
                    placeholder="Emergency contact name"
                  />
                </div>
                <div>
                  <label className="block text-xs font-medium text-gray-600 mb-1">Contact Phone</label>
                  <input
                    type="tel"
                    value={form.emergency_contact_phone}
                    onChange={(e) => updateField('emergency_contact_phone', e.target.value)}
                    className="w-full px-3 py-2.5 bg-white border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-sunset-200"
                    placeholder="+44 7XXX XXX XXX"
                  />
                </div>
              </div>
            </fieldset>

            {/* Notes */}
            <div>
              <label className="block text-xs font-medium text-gray-600 mb-1">Additional Notes</label>
              <textarea
                value={form.notes}
                onChange={(e) => updateField('notes', e.target.value)}
                rows={2}
                className="w-full px-3 py-2.5 bg-white border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-sunset-200 resize-none"
                placeholder="Anything else your instructor should know?"
              />
            </div>

            <button
              type="submit"
              disabled={submitting}
              className="btn-primary w-full text-center"
            >
              {submitting ? (
                <span className="flex items-center justify-center gap-2">
                  <span className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                  Submitting...
                </span>
              ) : (
                'Submit Registration'
              )}
            </button>
          </form>
        </div>

        <DeveloperFooter />
      </div>
    </div>
  );
}
