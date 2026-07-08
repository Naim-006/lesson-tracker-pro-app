'use client';

import { useState, useEffect } from 'react';
import { supabase } from '@/lib/supabase';
import Link from 'next/link';
import { formatDateTime } from '@/lib/utils';
import StatusBadge from '@/components/StatusBadge';

interface SubmissionData {
  id: string;
  status: string;
  first_name: string;
  last_name: string;
  email: string;
  created_at: string;
  reviewed_at: string | null;
  review_notes: string | null;
  instructor_name?: string;
}

export default function PupilStatusPage({ params }: { params: { token: string } }) {
  const { token } = params;
  const [data, setData] = useState<SubmissionData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    loadStatus();
  }, [token]);

  async function loadStatus() {
    try {
      const { data: submission, error: fetchErr } = await supabase
        .from('pupil_invite_submissions')
        .select('*')
        .eq('pupil_token', token.toUpperCase())
        .single();

      if (fetchErr || !submission) {
        setError('No registration found. Please check your link or contact your instructor.');
        setLoading(false);
        return;
      }

      const { data: profile } = await supabase
        .from('profiles')
        .select('first_name, last_name')
        .eq('id', submission.instructor_id)
        .single();

      const instructorName = profile
        ? `${profile.first_name || ''} ${profile.last_name || ''}`.trim()
        : 'Your instructor';

      setData({ ...submission, instructor_name: instructorName });
      setLoading(false);
    } catch {
      setError('Something went wrong. Please try again.');
      setLoading(false);
    }
  }

  if (loading) {
    return (
      <div className="auth-page">
        <div className="auth-card text-center">
          <div className="w-14 h-14 bg-[var(--sunset-light)] rounded-2xl flex items-center justify-center mx-auto mb-5">
            <span className="spinner spinner-sunset" style={{width: 28, height: 28, borderWidth: 3}} />
          </div>
          <h1 className="text-xl font-bold text-[var(--text-primary)] mb-2">Loading status…</h1>
          <p className="text-sm text-[var(--text-muted)]">Please wait.</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="auth-page">
        <div className="auth-card text-center">
          <div className="alert-error mx-auto mb-5 inline-flex">
            <span>{error}</span>
          </div>
          <Link href="/" className="btn-secondary w-full block">Go to Home</Link>
        </div>
      </div>
    );
  }

  const statusConfig: Record<string, { title: string; desc: string; icon: string; color: string }> = {
    pending: {
      title: 'Awaiting Review',
      desc: 'Your instructor has received your registration and will review it shortly. You can check back here anytime.',
      icon: '⏳',
      color: 'bg-[#fffbeb] border-[#fde68a]',
    },
    approved: {
      title: 'Registration Approved!',
      desc: 'Your instructor has approved your registration. You can now create your account in the Lesson Tracker app.',
      icon: '🎉',
      color: 'bg-[#f0fdf4] border-[#bbf7d0]',
    },
    rejected: {
      title: 'Registration Not Accepted',
      desc: data?.review_notes || 'Your instructor was unable to accept this registration. Please contact them directly for more information.',
      icon: '❌',
      color: 'bg-[#fef2f2] border-[#fecaca]',
    },
  };

  const config = statusConfig[data?.status || 'pending'] || statusConfig.pending;

  const steps = [
    { label: 'Registration Submitted', done: true, time: data?.created_at },
    { label: 'Instructor Review', done: data?.status !== 'pending', time: data?.reviewed_at },
    { label: 'Account Creation', done: data?.status === 'approved', time: null },
  ];

  return (
    <div className="auth-page py-12 h-auto items-start">
      <div className="auth-card" style={{padding: '2rem'}}>
        
        {/* Header */}
        <div className="flex flex-col items-center mb-6 text-center border-b border-[var(--border)] pb-6">
          <div className="text-5xl mb-4">{config.icon}</div>
          <h1 className="text-2xl font-bold text-[var(--text-primary)] mb-2">{config.title}</h1>
          <StatusBadge status={data!.status} />
        </div>

        {/* Progress Steps */}
        <div className="mb-8 space-y-4">
          {steps.map((step, i) => (
            <div key={i} className="flex items-start gap-3">
              <div className="mt-0.5">
                {step.done ? (
                  <div className="w-6 h-6 bg-[#166534] rounded-full flex items-center justify-center shadow-sm">
                    <svg className="w-3.5 h-3.5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
                    </svg>
                  </div>
                ) : (
                  <div className="w-6 h-6 bg-[var(--border-strong)] rounded-full flex items-center justify-center">
                    <div className="w-2 h-2 bg-[var(--text-muted)] rounded-full" />
                  </div>
                )}
              </div>
              <div className="flex-1 min-w-0">
                <p className={`text-sm font-semibold ${step.done ? 'text-[var(--text-primary)]' : 'text-[var(--text-muted)]'}`}>
                  {step.label}
                </p>
                {step.time && (
                  <p className="text-xs text-[var(--text-muted)] mt-0.5">{formatDateTime(step.time)}</p>
                )}
              </div>
            </div>
          ))}
        </div>

        {/* Info Card */}
        <div className={`mb-6 p-4 rounded-xl border ${config.color}`}>
          <p className="text-sm text-[var(--text-secondary)] leading-relaxed">{config.desc}</p>
        </div>

        {/* Registration Details */}
        <div className="mb-8 p-5 bg-[var(--surface-2)] rounded-xl border border-[var(--border)]">
          <h3 className="text-xs font-bold text-[var(--text-muted)] uppercase tracking-widest mb-4">
            Your Details
          </h3>
          <div className="space-y-2.5 text-sm">
            <div className="flex justify-between">
              <span className="text-[var(--text-secondary)]">Name</span>
              <span className="text-[var(--text-primary)] font-semibold">{data!.first_name} {data!.last_name}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-[var(--text-secondary)]">Email</span>
              <span className="text-[var(--text-primary)] font-semibold">{data!.email}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-[var(--text-secondary)]">Instructor</span>
              <span className="text-[var(--text-primary)] font-semibold">{data!.instructor_name}</span>
            </div>
          </div>
        </div>

        {data!.status === 'approved' && (
          <div className="mb-6 p-5 bg-[#f0fdf4] rounded-xl border border-[#bbf7d0]">
            <p className="text-sm font-bold text-[#166534] mb-3">Next Steps:</p>
            <ol className="text-sm text-[#15803d] space-y-2 list-decimal list-inside font-medium pb-2 border-b border-[#bbf7d0]">
              <li>Download the <strong>Lesson Tracker Pro</strong> app</li>
              <li>Select <strong>"I'm a Pupil"</strong></li>
              <li>Sign up using your email: <br/><strong className="ml-5 bg-white px-2 py-0.5 rounded border border-[#bbf7d0] mt-1 inline-block">{data!.email}</strong></li>
            </ol>
            <div className="mt-4 text-center">
               <Link href="/auth/pupil/login" className="btn-primary w-full text-center">
                 Go to Web Login
               </Link>
            </div>
          </div>
        )}

        {data!.status === 'pending' && (
          <div className="text-center pt-2">
            <p className="text-xs text-[var(--text-muted)] mb-2">
              This page will update automatically when your instructor reviews your registration.
            </p>
            <button onClick={loadStatus} className="text-xs font-bold text-[var(--sunset)] hover:underline">
              Refresh Status
            </button>
          </div>
        )}

        {data!.status === 'rejected' && data!.review_notes && (
          <div className="mt-4 p-4 bg-[var(--surface-2)] rounded-xl border border-[var(--border)]">
            <p className="text-xs font-bold text-[var(--text-muted)] mb-1">Instructor's Note:</p>
            <p className="text-sm font-medium text-[var(--text-primary)]">{data!.review_notes}</p>
          </div>
        )}
      </div>
    </div>
  );
}
