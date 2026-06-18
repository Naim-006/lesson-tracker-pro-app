'use client';

import { useState, useEffect, use } from 'react';
import { supabase } from '@/lib/supabase';
import AppLogo from '@/components/AppLogo';
import DeveloperFooter from '@/components/DeveloperFooter';
import StatusBadge from '@/components/StatusBadge';
import { formatDateTime } from '@/lib/utils';

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

export default function PupilStatusPage({ params }: { params: Promise<{ token: string }> }) {
  const { token } = use(params);
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

      // Get instructor name
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
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center animate-fade-in">
          <div className="w-12 h-12 border-4 border-sunset-200 border-t-sunset-500 rounded-full animate-spin mx-auto" />
          <p className="mt-4 text-gray-500">Loading status...</p>
        </div>
      </div>
    );
  }

  if (error) {
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

  const statusConfig: Record<string, { title: string; desc: string; icon: string; color: string }> = {
    pending: {
      title: 'Awaiting Review',
      desc: 'Your instructor has received your registration and will review it shortly. You can check back here anytime.',
      icon: '⏳',
      color: 'bg-amber-50 border-amber-200',
    },
    approved: {
      title: 'Registration Approved!',
      desc: 'Your instructor has approved your registration. You can now create your account in the Lesson Tracker app.',
      icon: '🎉',
      color: 'bg-emerald-50 border-emerald-200',
    },
    rejected: {
      title: 'Registration Not Accepted',
      desc: data?.review_notes || 'Your instructor was unable to accept this registration. Please contact them directly for more information.',
      icon: '❌',
      color: 'bg-red-50 border-red-200',
    },
  };

  const config = statusConfig[data?.status || 'pending'] || statusConfig.pending;

  const steps = [
    { label: 'Registration Submitted', done: true, time: data?.created_at },
    { label: 'Instructor Review', done: data?.status !== 'pending', time: data?.reviewed_at },
    { label: 'Account Creation', done: data?.status === 'approved', time: null },
  ];

  return (
    <div className="min-h-screen flex items-center justify-center p-4">
      <div className="glass-card rounded-3xl p-6 md:p-8 max-w-md w-full animate-fade-in">
        <AppLogo size="md" />

        <div className="mt-6 text-center">
          <div className="text-4xl mb-3">{config.icon}</div>
          <h2 className="text-xl font-bold text-gray-900">{config.title}</h2>
          <div className="mt-3">
            <StatusBadge status={data!.status} />
          </div>
        </div>

        {/* Progress Steps */}
        <div className="mt-6 space-y-3">
          {steps.map((step, i) => (
            <div key={i} className="flex items-start gap-3">
              <div className="mt-0.5">
                {step.done ? (
                  <div className="w-6 h-6 bg-emerald-500 rounded-full flex items-center justify-center">
                    <svg className="w-3.5 h-3.5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
                    </svg>
                  </div>
                ) : (
                  <div className="w-6 h-6 bg-gray-200 rounded-full flex items-center justify-center">
                    <div className="w-2 h-2 bg-gray-400 rounded-full" />
                  </div>
                )}
              </div>
              <div className="flex-1 min-w-0">
                <p className={`text-sm font-medium ${step.done ? 'text-gray-900' : 'text-gray-400'}`}>
                  {step.label}
                </p>
                {step.time && (
                  <p className="text-xs text-gray-400 mt-0.5">{formatDateTime(step.time)}</p>
                )}
              </div>
            </div>
          ))}
        </div>

        {/* Info Card */}
        <div className={`mt-6 p-4 rounded-2xl border ${config.color}`}>
          <p className="text-sm text-gray-700 leading-relaxed">{config.desc}</p>
        </div>

        {/* Registration Details */}
        <div className="mt-6 p-4 bg-gray-50 rounded-2xl border border-gray-200">
          <h3 className="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-3">
            Your Details
          </h3>
          <div className="space-y-2 text-sm">
            <div className="flex justify-between">
              <span className="text-gray-500">Name</span>
              <span className="text-gray-900 font-medium">{data!.first_name} {data!.last_name}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-500">Email</span>
              <span className="text-gray-900 font-medium">{data!.email}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-500">Instructor</span>
              <span className="text-gray-900 font-medium">{data!.instructor_name}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-500">Submitted</span>
              <span className="text-gray-900 font-medium">{formatDateTime(data!.created_at)}</span>
            </div>
          </div>
        </div>

        {data!.status === 'approved' && (
          <div className="mt-6 p-4 bg-emerald-50 rounded-2xl border border-emerald-200">
            <p className="text-sm font-semibold text-emerald-800 mb-2">Next Steps:</p>
            <ol className="text-xs text-emerald-700 space-y-1.5 list-decimal list-inside">
              <li>Download the <strong>Lesson Tracker</strong> app</li>
              <li>Open the app and select <strong>&quot;I&apos;m a Pupil&quot;</strong></li>
              <li>Sign up using your email: <strong>{data!.email}</strong></li>
              <li>You&apos;ll be connected to your instructor automatically</li>
            </ol>
          </div>
        )}

        {data!.status === 'pending' && (
          <div className="mt-4 text-center">
            <p className="text-xs text-gray-400">
              This page will update automatically when your instructor reviews your registration.
            </p>
            <button
              onClick={loadStatus}
              className="mt-3 text-xs text-sunset-600 hover:text-sunset-700 font-medium underline"
            >
              Refresh Status
            </button>
          </div>
        )}

        {data!.status === 'rejected' && data!.review_notes && (
          <div className="mt-4 p-4 bg-gray-50 rounded-2xl border border-gray-200">
            <p className="text-xs font-medium text-gray-500 mb-1">Instructor&apos;s Note:</p>
            <p className="text-sm text-gray-700">{data!.review_notes}</p>
          </div>
        )}
      </div>

      <DeveloperFooter />
    </div>
  );
}
