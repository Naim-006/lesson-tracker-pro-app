'use client';

import { useState } from 'react';
import { supabase } from '@/lib/supabase';
import Link from 'next/link';

export default function ForgotPasswordPage() {
  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(false);
  const [sent, setSent] = useState(false);
  const [error, setError] = useState('');

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError('');
    if (!email.includes('@')) { setError('Please enter a valid email address.'); return; }
    setLoading(true);
    try {
      const { error: resetError } = await supabase.auth.resetPasswordForEmail(email, {
        redirectTo: `${process.env.NEXT_PUBLIC_APP_URL}/reset-password`,
      });
      if (resetError) throw resetError;
      setSent(true);
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Failed to send reset email.');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="auth-page">
      <div className="auth-card">
        <div className="text-center mb-8">
          <div className="w-14 h-14 bg-[var(--sunset-light)] rounded-2xl flex items-center justify-center mx-auto mb-4">
            <svg className="w-7 h-7 text-[var(--sunset)]" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M16.5 10.5V6.75a4.5 4.5 0 10-9 0v3.75m-.75 11.25h10.5a2.25 2.25 0 002.25-2.25v-6.75a2.25 2.25 0 00-2.25-2.25H6.75a2.25 2.25 0 00-2.25 2.25v6.75a2.25 2.25 0 002.25 2.25z" />
            </svg>
          </div>
          <h1 className="text-2xl font-bold text-[var(--text-primary)] tracking-tight">Reset Password</h1>
          <p className="text-sm text-[var(--text-muted)] mt-1.5">We'll send a reset link to your email</p>
        </div>

        {sent ? (
          <div className="text-center">
            <div className="alert-success mb-6">
              <svg className="w-4 h-4 flex-shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.857-9.809a.75.75 0 00-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 10-1.06 1.061l2.5 2.5a.75.75 0 001.137-.089l4-5.5z" clipRule="evenodd" />
              </svg>
              <span>
                If <strong>{email}</strong> is registered, you'll receive a reset link shortly. Check your inbox and spam folder.
              </span>
            </div>
            <Link href="/auth/instructor/login" className="btn-primary w-full block">
              Back to Login
            </Link>
          </div>
        ) : (
          <>
            {error && (
              <div className="alert-error mb-5">
                <svg className="w-4 h-4 flex-shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.28 7.22a.75.75 0 00-1.06 1.06L8.94 10l-1.72 1.72a.75.75 0 101.06 1.06L10 11.06l1.72 1.72a.75.75 0 101.06-1.06L11.06 10l1.72-1.72a.75.75 0 00-1.06-1.06L10 8.94 8.28 7.22z" clipRule="evenodd" />
                </svg>
                <span>{error}</span>
              </div>
            )}
            <form onSubmit={handleSubmit} noValidate className="space-y-4">
              <div>
                <label className="field-label">Email Address</label>
                <input id="forgot-email" type="email" className="field-input" placeholder="your@email.com" value={email} onChange={e => setEmail(e.target.value)} required autoComplete="email" autoFocus />
              </div>
              <button id="forgot-submit-btn" type="submit" disabled={loading} className="btn-primary w-full">
                {loading ? <><span className="spinner" /> Sending…</> : 'Send Reset Link'}
              </button>
            </form>
            <p className="text-center text-sm text-[var(--text-muted)] mt-6">
              Remembered your password?{' '}
              <Link href="/auth/instructor/login" className="text-[var(--sunset)] font-semibold hover:underline">Sign in</Link>
            </p>
          </>
        )}
      </div>
    </div>
  );
}
