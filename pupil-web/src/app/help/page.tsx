'use client';

import { useState } from 'react';
import Link from 'next/link';

const faqs = [
  {
    q: 'How do I register as a pupil?',
    a: 'Ask your driving instructor to send you an invite link. Click the link, fill in the registration form, and submit. Your instructor will review your registration.',
  },
  {
    q: 'How long does registration review take?',
    a: 'Your instructor will review your registration as soon as they are available. You can check your status anytime using the link from your email.',
  },
  {
    q: "I didn't receive the invite email.",
    a: 'Check your spam or junk folder. If you still can\'t find it, ask your instructor to resend the invite or contact us for help.',
  },
  {
    q: 'How do I reset my password?',
    a: 'Go to the login screen and click "Forgot password?". Enter your email address and we\'ll send you a reset link.',
  },
  {
    q: 'The app says my invite link has expired.',
    a: 'Invite links are only valid for a limited time. Ask your instructor to send a new invite link.',
  },
  {
    q: 'How do I contact my instructor?',
    a: 'Once your registration is approved, you\'ll be able to message your instructor directly through the Lesson Tracker app.',
  },
];

export default function HelpPage() {
  const [openFaq, setOpenFaq] = useState<number | null>(null);

  return (
    <div className="auth-page py-12 items-start h-auto">
      <div className="auth-card max-w-2xl w-full mx-auto" style={{padding: '2rem'}}>
        {/* Header */}
        <div className="flex items-center gap-4 mb-8 pb-6 border-b border-[var(--border)]">
          <Link href="/" className="w-10 h-10 bg-gradient-to-br from-[#f3751f] to-[#e05a0c] rounded-xl flex items-center justify-center shadow-[var(--shadow-sunset)] shrink-0 transition-transform hover:scale-105">
            <span className="text-white font-black text-lg">L</span>
          </Link>
          <div>
            <h1 className="text-2xl font-bold text-[var(--text-primary)]">Help & Support</h1>
            <p className="text-sm text-[var(--text-muted)]">Find answers or get in touch</p>
          </div>
        </div>

        {/* Quick Contact */}
        <div className="grid grid-cols-2 gap-4 mb-10">
          <a
            href="https://wa.me/8801984862536"
            target="_blank"
            rel="noopener noreferrer"
            className="p-5 bg-[#f0fdf4] rounded-2xl border border-[#bbf7d0] text-center hover:bg-[#dcfce7] transition-all hover:-translate-y-0.5"
          >
            <div className="text-3xl mb-2">💬</div>
            <p className="text-[15px] font-bold text-[#166534]">WhatsApp</p>
            <p className="text-xs text-[#15803d]">Instant reply</p>
          </a>
          <a
            href="tel:+8801984862536"
            className="p-5 bg-[var(--sunset-light)] rounded-2xl border border-[var(--sunset)] opacity-80 text-center hover:opacity-100 transition-all hover:-translate-y-0.5"
          >
            <div className="text-3xl mb-2">📞</div>
            <p className="text-[15px] font-bold text-[var(--sunset-dark)]">Call Us</p>
            <p className="text-xs text-[var(--sunset)]">+880 1984-862536</p>
          </a>
        </div>

        {/* FAQ */}
        <div className="mb-10">
          <h2 className="text-sm font-bold uppercase tracking-wider text-[var(--text-muted)] mb-4">Frequently Asked Questions</h2>
          <div className="space-y-3">
            {faqs.map((faq, i) => (
              <div key={i} className="bg-[var(--surface)] rounded-xl border border-[var(--border-strong)] overflow-hidden transition-all">
                <button
                  onClick={() => setOpenFaq(openFaq === i ? null : i)}
                  className="w-full px-5 py-4 text-left flex items-start justify-between gap-4 hover:bg-[var(--surface-2)] transition-colors focus:outline-none"
                >
                  <span className="text-sm font-semibold text-[var(--text-primary)]">{faq.q}</span>
                  <svg
                    className={`w-5 h-5 text-[var(--text-muted)] transition-transform flex-shrink-0 mt-0.5 ${
                      openFaq === i ? 'rotate-180' : ''
                    }`}
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                  </svg>
                </button>
                {openFaq === i && (
                  <div className="px-5 pb-4 pt-1 animate-fade-in-up">
                    <p className="text-sm text-[var(--text-secondary)] leading-relaxed">{faq.a}</p>
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>

        {/* Contact Form */}
        <div className="p-6 bg-[var(--surface-2)] rounded-2xl border border-[var(--border)]">
          <h2 className="text-base font-bold text-[var(--text-primary)] mb-1">Still Need Help?</h2>
          <p className="text-sm text-[var(--text-muted)] mb-5">
            Fill in the form below and we'll get back to you shortly.
          </p>
          <ContactForm />
        </div>
        
        <div className="mt-8 text-center">
          <Link href="/" className="text-sm text-[var(--text-muted)] hover:text-[var(--text-primary)] transition-colors font-medium">
            ← Back to Home
          </Link>
        </div>
      </div>
    </div>
  );
}

function ContactForm() {
  const [form, setForm] = useState({ name: '', email: '', message: '' });
  const [submitting, setSubmitting] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [error, setError] = useState('');

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!form.name.trim() || !form.email.trim() || !form.message.trim()) {
      setError('Please fill in all fields.');
      return;
    }

    setSubmitting(true);
    setError('');

    try {
      const res = await fetch('/api/contact', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(form),
      });

      if (!res.ok) throw new Error('Failed to send');
      setSubmitted(true);
    } catch {
      setError('Failed to send message. Please try WhatsApp or call.');
    } finally {
      setSubmitting(false);
    }
  }

  if (submitted) {
    return (
      <div className="text-center py-6 bg-[var(--surface)] rounded-xl border border-[#bbf7d0]">
        <div className="text-4xl mb-3">📨</div>
        <p className="text-base font-bold text-[#166534]">Message Sent successfully!</p>
        <p className="text-sm text-[#15803d] mt-1 px-4">We'll get back to you at {form.email} as soon as possible.</p>
        <button 
          onClick={() => { setForm({ name: '', email: '', message: '' }); setSubmitted(false); }}
          className="mt-4 text-sm font-semibold text-[var(--sunset)] hover:underline"
        >
          Send another message
        </button>
      </div>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      {error && (
        <div className="alert-error">
          <svg className="w-4 h-4 flex-shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
             <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.28 7.22a.75.75 0 00-1.06 1.06L8.94 10l-1.72 1.72a.75.75 0 101.06 1.06L10 11.06l1.72 1.72a.75.75 0 101.06-1.06L11.06 10l1.72-1.72a.75.75 0 00-1.06-1.06L10 8.94 8.28 7.22z" clipRule="evenodd" />
          </svg>
          <span>{error}</span>
        </div>
      )}
      <div>
        <label className="field-label">Your Name</label>
        <input
          type="text"
          placeholder="Jane Doe"
          value={form.name}
          onChange={(e) => setForm((p) => ({ ...p, name: e.target.value }))}
          className="field-input"
        />
      </div>
      <div>
        <label className="field-label">Your Email</label>
        <input
          type="email"
          placeholder="jane@example.com"
          value={form.email}
          onChange={(e) => setForm((p) => ({ ...p, email: e.target.value }))}
          className="field-input"
        />
      </div>
      <div>
        <label className="field-label">Message</label>
        <textarea
          rows={4}
          placeholder="How can we help you?"
          value={form.message}
          onChange={(e) => setForm((p) => ({ ...p, message: e.target.value }))}
          className="field-input resize-y min-h-[100px]"
        />
      </div>
      <button
        type="submit"
        disabled={submitting}
        className="btn-primary w-full mt-2"
      >
        {submitting ? <><span className="spinner"/> Sending…</> : 'Send Message'}
      </button>
    </form>
  );
}
