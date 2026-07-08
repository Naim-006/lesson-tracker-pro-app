import Link from 'next/link';

export default function HomePage() {
  return (
    <div className="min-h-screen bg-[var(--bg)] flex flex-col font-sans">
      {/* ─── Hero Section ──────────────────────── */}
      <section className="relative overflow-hidden bg-[var(--surface)] border-b border-[var(--border)] pt-20 pb-24 md:pt-28 md:pb-32">
        {/* Background glow effects */}
        <div className="absolute top-0 right-1/4 w-[400px] h-[400px] bg-[var(--sunset)] opacity-10 rounded-full blur-[100px] -z-10" />
        <div className="absolute -bottom-20 left-1/4 w-[300px] h-[300px] bg-[#e05a0c] opacity-10 rounded-full blur-[120px] -z-10" />
        
        <div className="max-w-4xl mx-auto px-6 text-center animate-fade-in-up">
          <div className="inline-flex items-center justify-center p-[2px] rounded-full bg-gradient-to-r from-[var(--sunset)] to-[#e05a0c] mb-8 shadow-[var(--shadow-sunset)] animate-scale-in">
            <div className="bg-white px-5 py-2 rounded-full text-sm font-bold text-[var(--sunset)] tracking-wide">
              LESSON TRACKER PRO
            </div>
          </div>
          
          <h1 className="text-5xl md:text-7xl font-black text-[var(--text-primary)] tracking-tight leading-[1.1] mb-6">
            The all-in-one platform for <br className="hidden md:block"/>
            <span className="bg-gradient-to-br from-[var(--sunset)] to-[#e05a0c] bg-clip-text text-transparent">
              driving instructors
            </span>
          </h1>
          
          <p className="text-lg md:text-xl text-[var(--text-secondary)] max-w-2xl mx-auto mb-10 leading-relaxed">
            Manage your diary, track pupil progress, handle payments, and grow your driving school — entirely from your phone.
          </p>

          <div className="flex flex-col sm:flex-row items-center justify-center gap-4 animate-fade-in-up animate-delay-100">
            <Link href="/auth/instructor/signup" className="btn-primary px-8 py-3.5 text-lg w-full sm:w-auto">
              Start Free Trial
            </Link>
            <Link href="/auth/instructor/login" className="btn-secondary px-8 py-3.5 text-lg w-full sm:w-auto">
              Instructor Login
            </Link>
          </div>
          
          <div className="mt-8 flex items-center justify-center gap-2 text-sm text-[var(--text-muted)] animate-fade-in-up animate-delay-200">
            <svg className="w-5 h-5 text-green-500" fill="currentColor" viewBox="0 0 20 20"><path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.857-9.809a.75.75 0 00-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 10-1.06 1.061l2.5 2.5a.75.75 0 001.137-.089l4-5.5z" clipRule="evenodd" /></svg>
            60-day free trial • No credit card required • Cancel anytime
          </div>
        </div>
      </section>

      {/* ─── Role Portals ─────────────────────── */}
      <section className="py-20 bg-[var(--surface-2)]">
        <div className="max-w-5xl mx-auto px-6">
          <div className="text-center mb-12">
            <h2 className="text-3xl font-bold text-[var(--text-primary)]">Select your portal</h2>
            <p className="text-[var(--text-secondary)] mt-2">Sign in to your designated Lesson Tracker area.</p>
          </div>

          <div className="grid md:grid-cols-2 gap-6">
            {/* Pupil Portal */}
            <Link href="/auth/pupil/login" className="surface-card p-8 group hover:-translate-y-1 transition-all duration-300 hover:shadow-[0_12px_40px_rgba(99,102,241,0.15)] hover:border-[#6366f1] block">
              <div className="w-14 h-14 bg-[#e0e7ff] rounded-2xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
                <svg className="w-7 h-7 text-[#4f46e5]" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M12 6.042A8.967 8.967 0 006 3.75c-1.052 0-2.062.18-3 .512v14.25A8.987 8.987 0 016 18c2.305 0 4.408.867 6 2.292m0-14.25a8.966 8.966 0 016-2.292c1.052 0 2.062.18 3 .512v14.25A8.987 8.987 0 0018 18a8.967 8.967 0 00-6 2.292m0-14.25v14.25" />
                </svg>
              </div>
              <h3 className="text-xl font-bold text-[var(--text-primary)] mb-2">Pupil Portal</h3>
              <p className="text-[var(--text-secondary)] text-sm mb-6">Manage your profile, view progress reports, and handle payments. Ask your instructor for an invite if you haven't got one.</p>
              <div className="text-[#4f46e5] font-semibold flex items-center gap-1 text-sm">
                Pupil Login <span className="text-lg">→</span>
              </div>
            </Link>

            {/* Admin Portal */}
            <Link href="/auth/admin/login" className="surface-card p-8 group hover:-translate-y-1 transition-all duration-300 hover:shadow-[0_12px_40px_rgba(30,30,46,0.15)] hover:border-[#1e1e2e] block">
              <div className="w-14 h-14 bg-gray-100 rounded-2xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
                <svg className="w-7 h-7 text-[#1e1e2e]" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75L11.25 15 15 9.75m-3-7.036A11.959 11.959 0 013.598 6 11.99 11.99 0 003 9.749c0 5.592 3.824 10.29 9 11.623 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.571-.598-3.751h-.152c-3.196 0-6.1-1.248-8.25-3.285z" />
                </svg>
              </div>
              <h3 className="text-xl font-bold text-[var(--text-primary)] mb-2">Admin Portal</h3>
              <p className="text-[var(--text-secondary)] text-sm mb-6">Restricted access for support staff and administrators to manage the platform, subscriptions, and instructors.</p>
              <div className="text-[#1e1e2e] font-semibold flex items-center gap-1 text-sm">
                Admin Login <span className="text-lg">→</span>
              </div>
            </Link>
          </div>
        </div>
      </section>

      {/* ─── Footer ─────────────────────────── */}
      <footer className="mt-auto py-8 text-center text-sm text-[var(--text-muted)] bg-[var(--surface)] border-t border-[var(--border)]">
        <p>&copy; {new Date().getFullYear()} Lesson Tracker Pro. All rights reserved.</p>
      </footer>
    </div>
  );
}
