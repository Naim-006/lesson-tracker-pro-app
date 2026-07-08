'use client';

import { useEffect, useState } from 'react';
import { supabase } from '@/lib/supabase';
import { useRouter } from 'next/navigation';

export default function SignoutPage() {
  const router = useRouter();
  const [done, setDone] = useState(false);

  useEffect(() => {
    (async () => {
      await supabase.auth.signOut();
      setDone(true);
      setTimeout(() => router.replace('/'), 1500);
    })();
  }, [router]);

  return (
    <div className="auth-page">
      <div className="auth-card text-center">
        <div className="w-14 h-14 bg-[var(--sunset-light)] rounded-2xl flex items-center justify-center mx-auto mb-5">
          {done ? (
            <svg className="w-7 h-7 text-[var(--sunset)]" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          ) : (
            <span className="spinner spinner-sunset" style={{width: 28, height: 28, borderWidth: 3}} />
          )}
        </div>
        <h1 className="text-xl font-bold text-[var(--text-primary)] mb-2">
          {done ? 'Signed out successfully' : 'Signing you out…'}
        </h1>
        <p className="text-sm text-[var(--text-muted)]">
          {done ? 'Redirecting you to the home page…' : 'Please wait a moment.'}
        </p>
      </div>
    </div>
  );
}
