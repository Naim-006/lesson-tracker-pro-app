'use client';

import { useState, useEffect } from 'react';
import { supabase } from '@/lib/supabase';
import AppLogo from '@/components/AppLogo';
import DeveloperFooter from '@/components/DeveloperFooter';
import StatusBadge from '@/components/StatusBadge';
import { formatDateTime, getInviteUrl } from '@/lib/utils';

interface Submission {
  id: string;
  first_name: string;
  last_name: string;
  email: string;
  phone: string | null;
  status: string;
  created_at: string;
  reviewed_at: string | null;
  review_notes: string | null;
  pupil_token: string;
  preferred_days: string[] | null;
  experience_level: string | null;
  learning_goals: string | null;
}

interface LinkData {
  id: string;
  token: string;
  created_at: string;
  is_active: boolean;
  max_submissions: number | null;
  expires_at: string | null;
}

export default function DashboardPage() {
  const [instructorId, setInstructorId] = useState('');
  const [link, setLink] = useState<LinkData | null>(null);
  const [submissions, setSubmissions] = useState<Submission[]>([]);
  const [stats, setStats] = useState({ total: 0, pending: 0, approved: 0, rejected: 0 });
  const [loading, setLoading] = useState(true);
  const [selectedSubmission, setSelectedSubmission] = useState<Submission | null>(null);
  const [reviewNotes, setReviewNotes] = useState('');
  const [reviewing, setReviewing] = useState(false);
  const [copied, setCopied] = useState(false);
  const [filter, setFilter] = useState<string>('all');

  useEffect(() => {
    loadData();
  }, []);

  async function loadData() {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (user) {
        setInstructorId(user.id);
        await fetchLinkData(user.id);
      }
    } catch {
      setLoading(false);
    }
  }

  async function fetchLinkData(instId: string) {
    try {
      const res = await fetch(`/api/auth?instructor_id=${instId}`);
      const data = await res.json();

      if (data.link) {
        setLink(data.link);
        setSubmissions(data.submissions || []);
        setStats(data.stats || { total: 0, pending: 0, approved: 0, rejected: 0 });
      }

      if (!data.link) {
        // Auto-create link
        const createRes = await fetch('/api/auth', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ instructor_id: instId }),
        });
        const createData = await createRes.json();
        if (createData.token) {
          await fetchLinkData(instId);
        }
      }
    } catch {
      // Silent fail
    } finally {
      setLoading(false);
    }
  }

  async function handleReview(action: 'approve' | 'reject') {
    if (!selectedSubmission || !instructorId) return;
    setReviewing(true);

    try {
      const res = await fetch('/api/review', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          submission_id: selectedSubmission.id,
          action,
          review_notes: reviewNotes,
          instructor_id: instructorId,
        }),
      });

      const data = await res.json();
      if (data.success) {
        setSelectedSubmission(null);
        setReviewNotes('');
        await fetchLinkData(instructorId);
      }
    } catch {
      // Silent fail
    } finally {
      setReviewing(false);
    }
  }

  async function handleDeactivate() {
    if (!link || !instructorId) return;
    if (!confirm('Deactivate this invite link? New pupils won\'t be able to register.')) return;

    try {
      await fetch(`/api/auth?link_id=${link.id}&instructor_id=${instructorId}`, {
        method: 'DELETE',
      });
      setLink(null);
      setSubmissions([]);
      setStats({ total: 0, pending: 0, approved: 0, rejected: 0 });
    } catch {
      // Silent fail
    }
  }

  function copyLink() {
    if (!link) return;
    navigator.clipboard.writeText(getInviteUrl(link.token));
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  }

  const filteredSubmissions = submissions.filter((s) =>
    filter === 'all' ? true : s.status === filter
  );

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="w-12 h-12 border-4 border-sunset-200 border-t-sunset-500 rounded-full animate-spin mx-auto" />
          <p className="mt-4 text-gray-500">Loading dashboard...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen p-4 md:p-8">
      <div className="max-w-3xl mx-auto">
        {/* Header */}
        <div className="flex items-center justify-between mb-8">
          <AppLogo size="sm" />
          <div className="flex items-center gap-2">
            <span className="text-xs text-gray-500">Instructor Dashboard</span>
          </div>
        </div>

        {/* Invite Link Card */}
        {link && (
          <div className="glass-card rounded-3xl p-6 mb-6 animate-fade-in">
            <div className="flex items-start justify-between mb-4">
              <h2 className="text-lg font-bold text-gray-900">Your Invite Link</h2>
              <button
                onClick={handleDeactivate}
                className="text-xs text-red-500 hover:text-red-600 underline"
              >
                Deactivate
              </button>
            </div>

            <div className="flex items-center gap-2 p-3 bg-gray-50 rounded-xl border border-gray-200">
              <code className="flex-1 text-sm text-gray-700 truncate font-mono">
                {getInviteUrl(link.token)}
              </code>
              <button
                onClick={copyLink}
                className={`px-4 py-2 rounded-lg text-xs font-semibold transition-all ${
                  copied
                    ? 'bg-emerald-500 text-white'
                    : 'bg-sunset-500 text-white hover:bg-sunset-600'
                }`}
              >
                {copied ? 'Copied!' : 'Copy'}
              </button>
            </div>

            <p className="mt-3 text-xs text-gray-500">
              Share this link with pupils. They&apos;ll fill in their details and you can review before approving.
            </p>

            {/* Stats */}
            <div className="grid grid-cols-4 gap-3 mt-4">
              {[
                { label: 'Total', value: stats.total, color: 'text-gray-900' },
                { label: 'Pending', value: stats.pending, color: 'text-amber-600' },
                { label: 'Approved', value: stats.approved, color: 'text-emerald-600' },
                { label: 'Rejected', value: stats.rejected, color: 'text-red-600' },
              ].map((stat) => (
                <div key={stat.label} className="text-center p-3 bg-gray-50 rounded-xl">
                  <div className={`text-2xl font-bold ${stat.color}`}>{stat.value}</div>
                  <div className="text-xs text-gray-500 mt-1">{stat.label}</div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Filter Tabs */}
        <div className="flex gap-2 mb-4">
          {['all', 'pending', 'approved', 'rejected'].map((f) => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className={`px-4 py-2 rounded-xl text-xs font-semibold transition-all ${
                filter === f
                  ? 'bg-sunset-500 text-white'
                  : 'bg-white text-gray-600 border border-gray-200 hover:border-sunset-300'
              }`}
            >
              {f.charAt(0).toUpperCase() + f.slice(1)}
              {f === 'pending' && stats.pending > 0 && (
                <span className="ml-1.5 px-1.5 bg-amber-400 text-white rounded-full text-[10px]">
                  {stats.pending}
                </span>
              )}
            </button>
          ))}
        </div>

        {/* Submissions List */}
        <div className="space-y-3">
          {filteredSubmissions.length === 0 ? (
            <div className="glass-card rounded-2xl p-8 text-center">
              <p className="text-gray-500 text-sm">
                {filter === 'all'
                  ? 'No registrations yet. Share your invite link to get started!'
                  : `No ${filter} registrations.`}
              </p>
            </div>
          ) : (
            filteredSubmissions.map((sub) => (
              <div
                key={sub.id}
                className="glass-card rounded-2xl p-4 hover:shadow-md transition-shadow cursor-pointer"
                onClick={() => setSelectedSubmission(sub)}
              >
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 bg-sunset-100 rounded-full flex items-center justify-center">
                      <span className="text-sm font-bold text-sunset-700">
                        {sub.first_name[0]}{sub.last_name[0]}
                      </span>
                    </div>
                    <div>
                      <p className="font-semibold text-gray-900 text-sm">
                        {sub.first_name} {sub.last_name}
                      </p>
                      <p className="text-xs text-gray-500">{sub.email}</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    <StatusBadge status={sub.status} />
                  </div>
                </div>
                <div className="flex items-center gap-4 mt-2 text-xs text-gray-400">
                  <span>Submitted {formatDateTime(sub.created_at)}</span>
                  {sub.experience_level && (
                    <span className="capitalize">{sub.experience_level.replace('_', ' ')}</span>
                  )}
                </div>
              </div>
            ))
          )}
        </div>

        <DeveloperFooter />
      </div>

      {/* Review Modal */}
      {selectedSubmission && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-3xl p-6 max-w-md w-full max-h-[90vh] overflow-y-auto animate-fade-in">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-bold text-gray-900">Review Registration</h3>
              <button
                onClick={() => { setSelectedSubmission(null); setReviewNotes(''); }}
                className="w-8 h-8 flex items-center justify-center rounded-full hover:bg-gray-100"
              >
                ✕
              </button>
            </div>

            <div className="space-y-3 mb-6">
              <div className="flex justify-between text-sm">
                <span className="text-gray-500">Name</span>
                <span className="font-medium">{selectedSubmission.first_name} {selectedSubmission.last_name}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-gray-500">Email</span>
                <span className="font-medium">{selectedSubmission.email}</span>
              </div>
              {selectedSubmission.phone && (
                <div className="flex justify-between text-sm">
                  <span className="text-gray-500">Phone</span>
                  <span className="font-medium">{selectedSubmission.phone}</span>
                </div>
              )}
              {selectedSubmission.experience_level && (
                <div className="flex justify-between text-sm">
                  <span className="text-gray-500">Experience</span>
                  <span className="font-medium capitalize">{selectedSubmission.experience_level.replace('_', ' ')}</span>
                </div>
              )}
              {selectedSubmission.preferred_days && selectedSubmission.preferred_days.length > 0 && (
                <div className="flex justify-between text-sm">
                  <span className="text-gray-500">Days</span>
                  <span className="font-medium">{selectedSubmission.preferred_days.join(', ')}</span>
                </div>
              )}
              {selectedSubmission.learning_goals && (
                <div>
                  <span className="text-xs text-gray-500">Goals</span>
                  <p className="text-sm text-gray-700 mt-1">{selectedSubmission.learning_goals}</p>
                </div>
              )}
            </div>

            <div className="mb-6">
              <label className="block text-xs font-medium text-gray-600 mb-1">Review Notes (optional)</label>
              <textarea
                value={reviewNotes}
                onChange={(e) => setReviewNotes(e.target.value)}
                rows={2}
                className="w-full px-3 py-2 bg-gray-50 border border-gray-200 rounded-xl text-sm resize-none focus:ring-2 focus:ring-sunset-200"
                placeholder="Reason for rejection (if applicable)..."
              />
            </div>

            <div className="flex gap-3">
              <button
                onClick={() => handleReview('reject')}
                disabled={reviewing}
                className="flex-1 px-4 py-3 bg-red-50 text-red-700 rounded-xl font-semibold text-sm border border-red-200 hover:bg-red-100 transition-all disabled:opacity-50"
              >
                {reviewing ? 'Processing...' : 'Reject'}
              </button>
              <button
                onClick={() => handleReview('approve')}
                disabled={reviewing}
                className="flex-1 btn-primary text-center disabled:opacity-50"
              >
                {reviewing ? 'Processing...' : 'Approve'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
