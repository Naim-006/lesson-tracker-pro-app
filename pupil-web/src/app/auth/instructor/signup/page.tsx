'use client';

import { useState } from 'react';
import { supabase } from '@/lib/supabase';
import Link from 'next/link';

export default function InstructorSignupPage() {
  const [step, setStep] = useState<'form' | 'verify'>('form');
  const [fullName, setFullName] = useState('');
  const [phone, setPhone] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPw, setShowPw] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  function validate() {
    if (!fullName.trim()) return 'Full name is required.';
    const phoneRegex = /^(\+44|0)7\d{9}$|^(\+44|0)\d{10}$/;
    if (!phoneRegex.test(phone.replace(/\s/g, ''))) return 'Enter a valid UK phone number.';
    if (!email.includes('@')) return 'Enter a valid email address.';
    if (password.length < 8) return 'Password must be at least 8 characters.';
    if (password !== confirmPassword) return 'Passwords do not match.';
    return null;
  }

  async function handleSignup(e: React.FormEvent) {
    e.preventDefault();
    setError('');
    const err = validate();
    if (err) { setError(err); return; }

    setLoading(true);
    try {
      const { error: signUpError } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: { full_name: fullName, phone, role: 'instructor' },
          emailRedirectTo: `${process.env.NEXT_PUBLIC_APP_URL}/auth/callback`,
        },
      });
      if (signUpError) throw signUpError;
      setStep('verify');
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Signup failed. Please try again.';
      setError(msg.includes('User already registered') ? 'An account with this email already exists.' : msg);
    } finally {
      setLoading(false);
    }
  }

  if (step === 'verify') {
    return (
      <div className="auth-page">
        <div className="auth-card text-center">
          <div className="w-16 h-16 bg-[var(--sunset-light)] rounded-2xl flex items-center justify-center mx-auto mb-5">
            <svg className="w-8 h-8 text-[var(--sunset)]" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M21.75 6.75v10.5a2.25 2.25 0 01-2.25 2.25h-15a2.25 2.25 0 01-2.25-2.25V6.75m19.5 0A2.25 2.25 0 0019.5 4.5h-15a2.25 2.25 0 00-2.25 2.25m19.5 0v.243a2.25 2.25 0 01-1.07 1.916l-7.5 4.615a2.25 2.25 0 01-2.36 0L3.32 8.91a2.25 2.25 0 01-1.07-1.916V6.75" />
            </svg>
          </div>
          <h1 className="text-2xl font-bold text-[var(--text-primary)] mb-2">Check your email</h1>
          <p className="text-[var(--text-secondary)] text-sm mb-6">
            We've sent a verification link to <strong className="text-[var(--text-primary)]">{email}</strong>. Click the link to activate your account.
          </p>
          <div className="alert-warning mb-6">
            <svg className="w-4 h-4 flex-shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M8.485 2.495c.673-1.167 2.357-1.167 3.03 0l6.28 10.875c.673 1.167-.17 2.625-1.516 2.625H3.72c-1.347 0-2.189-1.458-1.515-2.625L8.485 2.495zM10 5a.75.75 0 01.75.75v4.5a.75.75 0 01-1.5 0v-4.5A.75.75 0 0110 5zm0 9a1 1 0 100-2 1 1 0 000 2z" clipRule="evenodd" />
            </svg>
            <span>After verifying, open the Lesson Tracker Pro mobile app to sign in.</span>
          </div>
          <Link href="/auth/instructor/login" className="btn-primary w-full block">
            Go to Login
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="auth-page">
      <div className="auth-card">
        {/* Logo */}
        <div className="text-center mb-8">
          <div className="w-14 h-14 bg-gradient-to-br from-[#f3751f] to-[#e05a0c] rounded-2xl flex items-center justify-center mx-auto mb-4 shadow-[var(--shadow-sunset)]">
            <span className="text-white text-2xl font-black">L</span>
          </div>
          <h1 className="text-2xl font-bold text-[var(--text-primary)] tracking-tight">Create Instructor Account</h1>
          <p className="text-sm text-[var(--text-muted)] mt-1.5">Start your 60-day free trial — no card required</p>
        </div>

        {error && (
          <div className="alert-error mb-5">
            <svg className="w-4 h-4 flex-shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.28 7.22a.75.75 0 00-1.06 1.06L8.94 10l-1.72 1.72a.75.75 0 101.06 1.06L10 11.06l1.72 1.72a.75.75 0 101.06-1.06L11.06 10l1.72-1.72a.75.75 0 00-1.06-1.06L10 8.94 8.28 7.22z" clipRule="evenodd" />
            </svg>
            <span>{error}</span>
          </div>
        )}

        <form onSubmit={handleSignup} noValidate className="space-y-4">
          <div>
            <label className="field-label">Full Name</label>
            <input type="text" className="field-input" placeholder="Jane Smith" value={fullName} onChange={e => setFullName(e.target.value)} required autoComplete="name" />
          </div>
          <div>
            <label className="field-label">UK Phone Number</label>
            <input type="tel" className="field-input" placeholder="07700 900000" value={phone} onChange={e => setPhone(e.target.value)} required autoComplete="tel" />
          </div>
          <div>
            <label className="field-label">Email Address</label>
            <input type="email" className="field-input" placeholder="jane@example.com" value={email} onChange={e => setEmail(e.target.value)} required autoComplete="email" />
          </div>
          <div>
            <label className="field-label">Password</label>
            <div className="relative">
              <input type={showPw ? 'text' : 'password'} className="field-input pr-12" placeholder="Min 8 characters" value={password} onChange={e => setPassword(e.target.value)} required autoComplete="new-password" />
              <button type="button" onClick={() => setShowPw(v => !v)} className="absolute right-3 top-1/2 -translate-y-1/2 text-[var(--text-muted)] hover:text-[var(--text-secondary)] transition-colors p-1">
                {showPw ? (
                  <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}><path strokeLinecap="round" strokeLinejoin="round" d="M3.98 8.223A10.477 10.477 0 001.934 12C3.226 16.338 7.244 19.5 12 19.5c.993 0 1.953-.138 2.863-.395M6.228 6.228A10.45 10.45 0 0112 4.5c4.756 0 8.773 3.162 10.065 7.498a10.523 10.523 0 01-4.293 5.774M6.228 6.228L3 3m3.228 3.228l3.65 3.65m7.894 7.894L21 21m-3.228-3.228l-3.65-3.65m0 0a3 3 0 10-4.243-4.243m4.242 4.242L9.88 9.88" /></svg>
                ) : (
                  <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}><path strokeLinecap="round" strokeLinejoin="round" d="M2.036 12.322a1.012 1.012 0 010-.639C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178z" /><path strokeLinecap="round" strokeLinejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" /></svg>
                )}
              </button>
            </div>
          </div>
          <div>
            <label className="field-label">Confirm Password</label>
            <input type={showPw ? 'text' : 'password'} className="field-input" placeholder="Repeat password" value={confirmPassword} onChange={e => setConfirmPassword(e.target.value)} required autoComplete="new-password" />
          </div>

          <button type="submit" disabled={loading} className="btn-primary w-full mt-2">
            {loading ? <><span className="spinner" /> Creating account…</> : 'Create Account'}
          </button>
        </form>

        <p className="text-center text-sm text-[var(--text-muted)] mt-6">
          Already have an account?{' '}
          <Link href="/auth/instructor/login" className="text-[var(--sunset)] font-semibold hover:underline">Sign in</Link>
        </p>
        <p className="text-center text-xs text-[var(--text-muted)] mt-3">
          By signing up you agree to our{' '}
          <Link href="/help" className="underline">Terms &amp; Privacy Policy</Link>.
        </p>
      </div>
    </div>
  );
}
