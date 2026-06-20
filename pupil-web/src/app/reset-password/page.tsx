'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { supabase } from '@/lib/supabase';
import AppLogo from '@/components/AppLogo';
import DeveloperFooter from '@/components/DeveloperFooter';

export default function ResetPasswordPage() {
  const router = useRouter();
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState(false);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    supabase.auth.onAuthStateChange(async (event, session) => {
      if (event === 'PASSWORD_RECOVERY') {
        setReady(true);
      }
    });

    const hash = window.location.hash;
    if (hash && hash.includes('type=recovery')) {
      setReady(true);
    }
  }, []);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError('');

    if (password.length < 6) {
      setError('Password must be at least 6 characters.');
      return;
    }

    if (password !== confirmPassword) {
      setError('Passwords do not match.');
      return;
    }

    setLoading(true);
    try {
      const { error: updateErr } = await supabase.auth.updateUser({ password });
      if (updateErr) {
        setError(updateErr.message);
      } else {
        setSuccess(true);
        setTimeout(() => router.push('/'), 3000);
      }
    } catch {
      setError('Something went wrong. Please try again.');
    } finally {
      setLoading(false);
    }
  }

  if (!ready && !success) {
    return (
      <div className="min-h-screen flex items-center justify-center p-4">
        <div className="glass-card rounded-3xl p-8 max-w-md w-full text-center animate-fade-in">
          <AppLogo size="md" />
          <div className="mt-8">
            <div className="w-12 h-12 border-4 border-sunset-200 border-t-sunset-500 rounded-full animate-spin mx-auto" />
            <p className="mt-4 text-gray-500">Verifying reset link...</p>
          </div>
          <DeveloperFooter />
        </div>
      </div>
    );
  }

  if (success) {
    return (
      <div className="min-h-screen flex items-center justify-center p-4">
        <div className="glass-card rounded-3xl p-8 max-w-md w-full text-center animate-fade-in">
          <AppLogo size="md" />
          <div className="mt-8">
            <div className="text-5xl mb-4">✅</div>
            <h2 className="text-xl font-bold text-gray-900">Password Reset Successfully!</h2>
            <p className="mt-2 text-sm text-gray-500">
              Your password has been updated. Redirecting to home...
            </p>
          </div>
          <DeveloperFooter />
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex items-center justify-center p-4">
      <div className="glass-card rounded-3xl p-6 md:p-8 max-w-md w-full animate-fade-in">
        <AppLogo size="md" />

        <div className="mt-6">
          <h2 className="text-xl font-bold text-gray-900">Set New Password</h2>
          <p className="mt-1 text-sm text-gray-500">
            Enter your new password below.
          </p>
        </div>

        {error && (
          <div className="mt-4 p-3 bg-red-50 rounded-xl border border-red-100 text-sm text-red-700">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="mt-6 space-y-4">
          <div>
            <label className="block text-xs font-medium text-gray-600 mb-1">New Password *</label>
            <input
              type="password"
              required
              minLength={6}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full px-3 py-2.5 bg-white border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-sunset-200"
              placeholder="At least 6 characters"
            />
          </div>
          <div>
            <label className="block text-xs font-medium text-gray-600 mb-1">Confirm Password *</label>
            <input
              type="password"
              required
              minLength={6}
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              className="w-full px-3 py-2.5 bg-white border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-sunset-200"
              placeholder="Repeat your password"
            />
          </div>
          <button
            type="submit"
            disabled={loading}
            className="btn-primary w-full text-center"
          >
            {loading ? (
              <span className="flex items-center justify-center gap-2">
                <span className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                Updating...
              </span>
            ) : (
              'Update Password'
            )}
          </button>
        </form>
      </div>
      <DeveloperFooter />
    </div>
  );
}
