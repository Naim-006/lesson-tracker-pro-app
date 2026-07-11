'use client';

import Link from 'next/link';

export default function PaymentCancelledPage() {
  return (
    <div className="auth-page">
      <div className="auth-card text-center">
        <div className="w-16 h-16 bg-[#fef2f2] border border-[#fecaca] rounded-2xl flex items-center justify-center mx-auto mb-5">
          <svg className="w-8 h-8 text-[#991b1b]" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </div>
        <h1 className="text-2xl font-bold text-[var(--text-primary)] mb-3">Payment Cancelled</h1>
        <p className="text-sm text-[var(--text-secondary)] mb-8">You cancelled the payment. No charges were made. You can try again from the app.</p>
        <Link href="/" className="btn-secondary inline-block">Return Home</Link>
      </div>
    </div>
  );
}
