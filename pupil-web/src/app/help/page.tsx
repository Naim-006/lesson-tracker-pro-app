'use client';

import { useState } from 'react';
import AppLogo from '@/components/AppLogo';
import DeveloperFooter from '@/components/DeveloperFooter';

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
    q: 'I didn\'t receive the invite email.',
    a: 'Check your spam or junk folder. If you still can\'t find it, ask your instructor to resend the invite or contact us for help.',
  },
  {
    q: 'How do I reset my password?',
    a: 'Open the Lesson Tracker app, go to the login screen, and tap "Forgot Password". Enter your email address and we\'ll send you a reset link.',
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
    <div className="min-h-screen p-4 md:p-8">
      <div className="max-w-2xl mx-auto">
        <div className="glass-card rounded-3xl p-6 md:p-8 animate-fade-in">
          <AppLogo size="md" />

          <div className="mt-6">
            <h2 className="text-xl font-bold text-gray-900">Help & Support</h2>
            <p className="mt-1 text-sm text-gray-500">
              Find answers to common questions or get in touch with us.
            </p>
          </div>

          {/* Quick Contact */}
          <div className="mt-6 grid grid-cols-2 gap-3">
            <a
              href="https://wa.me/8801984862536"
              target="_blank"
              rel="noopener noreferrer"
              className="p-4 bg-green-50 rounded-2xl border border-green-200 text-center hover:bg-green-100 transition-colors"
            >
              <div className="text-2xl mb-1">💬</div>
              <p className="text-sm font-semibold text-green-800">WhatsApp</p>
              <p className="text-xs text-green-600 mt-0.5">Quick reply</p>
            </a>
            <a
              href="tel:+8801984862536"
              className="p-4 bg-sunset-50 rounded-2xl border border-sunset-200 text-center hover:bg-sunset-100 transition-colors"
            >
              <div className="text-2xl mb-1">📞</div>
              <p className="text-sm font-semibold text-sunset-800">Call Us</p>
              <p className="text-xs text-sunset-600 mt-0.5">+880 1984-862536</p>
            </a>
          </div>

          {/* FAQ */}
          <div className="mt-8">
            <h3 className="text-sm font-semibold text-gray-700 mb-4">Frequently Asked Questions</h3>
            <div className="space-y-2">
              {faqs.map((faq, i) => (
                <div key={i} className="bg-white rounded-2xl border border-gray-100 overflow-hidden">
                  <button
                    onClick={() => setOpenFaq(openFaq === i ? null : i)}
                    className="w-full px-4 py-3 text-left flex items-center justify-between gap-2 hover:bg-gray-50 transition-colors"
                  >
                    <span className="text-sm font-medium text-gray-900">{faq.q}</span>
                    <svg
                      className={`w-4 h-4 text-gray-400 transition-transform flex-shrink-0 ${
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
                    <div className="px-4 pb-3 animate-fade-in">
                      <p className="text-sm text-gray-600 leading-relaxed">{faq.a}</p>
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>

          {/* Contact Form */}
          <div className="mt-8 p-4 bg-gray-50 rounded-2xl border border-gray-200">
            <h3 className="text-sm font-semibold text-gray-700 mb-1">Still Need Help?</h3>
            <p className="text-xs text-gray-500 mb-4">
              Fill in the form below and we&apos;ll get back to you.
            </p>
            <ContactForm />
          </div>
        </div>

        <DeveloperFooter />
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
      <div className="text-center py-4">
        <div className="text-3xl mb-2">📨</div>
        <p className="text-sm font-medium text-gray-900">Message Sent!</p>
        <p className="text-xs text-gray-500 mt-1">We&apos;ll get back to you as soon as possible.</p>
      </div>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-3">
      {error && (
        <div className="p-2 bg-red-50 rounded-lg border border-red-100 text-xs text-red-700">
          {error}
        </div>
      )}
      <div>
        <input
          type="text"
          placeholder="Your Name *"
          value={form.name}
          onChange={(e) => setForm((p) => ({ ...p, name: e.target.value }))}
          className="w-full px-3 py-2 bg-white border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-sunset-200"
        />
      </div>
      <div>
        <input
          type="email"
          placeholder="Your Email *"
          value={form.email}
          onChange={(e) => setForm((p) => ({ ...p, email: e.target.value }))}
          className="w-full px-3 py-2 bg-white border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-sunset-200"
        />
      </div>
      <div>
        <textarea
          rows={3}
          placeholder="Your Message *"
          value={form.message}
          onChange={(e) => setForm((p) => ({ ...p, message: e.target.value }))}
          className="w-full px-3 py-2 bg-white border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-sunset-200 resize-none"
        />
      </div>
      <button
        type="submit"
        disabled={submitting}
        className="btn-primary w-full text-sm text-center"
      >
        {submitting ? 'Sending...' : 'Send Message'}
      </button>
    </form>
  );
}
