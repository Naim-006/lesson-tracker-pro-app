'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { supabase } from '@/lib/supabase';

export default function AuthCallbackPage() {
  const router = useRouter();

  useEffect(() => {
    // Supabase JS v2 automatically handles the token from the URL hash.
    // We just need to wait briefly and then check session state.
    const checkSession = async () => {
      const { data: { session } } = await supabase.auth.getSession();
      if (session) {
        // Redirect based on role
        const { data: profile } = await supabase
          .from('profiles')
          .select('role')
          .eq('id', session.user.id)
          .single();

        if (profile?.role === 'admin') {
          router.replace('/');
        } else if (profile?.role === 'instructor') {
          router.replace('/');
        } else {
          router.replace('/');
        }
      } else {
        // No session – might be a magic link / email confirmation
        // Wait a moment for SDK to process the URL hash
        setTimeout(async () => {
          const { data: { session: s2 } } = await supabase.auth.getSession();
          if (s2) {
            router.replace('/');
          } else {
            router.replace('/auth/instructor/login?message=Email+verified.+Please+log+in.');
          }
        }, 1500);
      }
    };
    checkSession();
  }, [router]);

  return (
    <div className="auth-page">
      <div className="auth-card text-center">
        <div className="w-14 h-14 bg-[var(--sunset-light)] rounded-2xl flex items-center justify-center mx-auto mb-5">
          <span className="spinner spinner-sunset" style={{width: 28, height: 28, borderWidth: 3}} />
        </div>
        <h1 className="text-xl font-bold text-[var(--text-primary)] mb-2">Verifying your account…</h1>
        <p className="text-sm text-[var(--text-muted)]">Please wait while we confirm your identity.</p>
      </div>
    </div>
  );
}
