'use client';

import Link from 'next/link';

export default function PaymentSuccessPage() {
  return (
    <div className="auth-page">
      <div className="auth-card text-center">
        <div className="w-16 h-16 bg-[#f0fdf4] border border-[#bbf7d0] rounded-2xl flex items-center justify-center mx-auto mb-5">
          <svg className="w-8 h-8 text-[#166534]" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
          </svg>
        </div>
        <h1 className="text-2xl font-bold text-[var(--text-primary)] mb-3">Payment Successful!</h1>
        <p className="text-sm text-[var(--text-secondary)] mb-8">Your subscription is now active. You can close this page and return to the app.</p>
        <Link href="/" className="btn-secondary inline-block">Return Home</Link>
      </div>
    </div>
  );
}
