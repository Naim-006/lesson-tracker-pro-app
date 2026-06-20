import AppLogo from '@/components/AppLogo';
import DeveloperFooter from '@/components/DeveloperFooter';

export default function HomePage() {
  return (
    <div className="min-h-screen bg-[#f8f6f2]">
      {/* Hero */}
      <div className="bg-gradient-to-br from-[#f3751f] to-[#e85d3a] text-white">
        <div className="max-w-2xl mx-auto px-6 py-20 text-center">
          <div className="inline-block mb-6">
            <div className="w-20 h-20 bg-white/20 rounded-3xl flex items-center justify-center backdrop-blur-sm border border-white/20">
              <span className="text-4xl font-bold">L</span>
            </div>
          </div>
          <h1 className="text-4xl md:text-5xl font-extrabold tracking-tight mb-4">
            Lesson Tracker
          </h1>
          <p className="text-lg text-white/80 mb-2">
            Professional Driving Instructor Platform
          </p>
          <p className="text-sm text-white/60 max-w-md mx-auto">
            Manage lessons, track pupil progress, handle payments, and grow your driving school — all in one app.
          </p>
        </div>
      </div>

      {/* Features */}
      <div className="max-w-2xl mx-auto px-6 py-12">
        <h2 className="text-xl font-bold text-gray-900 text-center mb-8">Everything You Need</h2>
        <div className="grid grid-cols-2 gap-4">
          {[
            { icon: '📅', title: 'Smart Diary', desc: 'Schedule & manage lessons' },
            { icon: '👥', title: 'Pupil Tracking', desc: 'Progress & communication' },
            { icon: '💰', title: 'Finances', desc: 'Income, invoices & reports' },
            { icon: '💬', title: 'Messaging', desc: 'Real-time chat with pupils' },
            { icon: '📊', title: 'Progress Matrix', desc: 'Skills & test readiness' },
            { icon: '🗺️', title: 'Route Planning', desc: 'Pickup & dropoff locations' },
          ].map((f) => (
            <div key={f.title} className="p-4 bg-white rounded-2xl border border-gray-100">
              <div className="text-2xl mb-2">{f.icon}</div>
              <h3 className="font-semibold text-gray-900 text-sm">{f.title}</h3>
              <p className="text-xs text-gray-500 mt-1">{f.desc}</p>
            </div>
          ))}
        </div>
      </div>

      {/* CTA */}
      <div className="max-w-2xl mx-auto px-6 pb-12">
        <div className="bg-white rounded-3xl p-8 border border-gray-100 text-center">
          <h2 className="text-lg font-bold text-gray-900 mb-2">Ready to Get Started?</h2>
          <p className="text-sm text-gray-500 mb-6">
            Download the app and ask your instructor for an invite link.
          </p>
          <div className="flex gap-3 justify-center flex-wrap">
            <div className="px-5 py-3 bg-gray-900 text-white rounded-xl text-sm font-semibold flex items-center gap-2">
              <span>📱</span> Download App
            </div>
            <a
              href="https://wa.me/8801984862536"
              target="_blank"
              rel="noopener noreferrer"
              className="px-5 py-3 bg-green-500 text-white rounded-xl text-sm font-semibold flex items-center gap-2"
            >
              <span>💬</span> Contact Us
            </a>
            <a
              href="/help"
              className="px-5 py-3 bg-white text-gray-900 rounded-xl text-sm font-semibold flex items-center gap-2 border border-gray-200 hover:bg-gray-50"
            >
              <span>❓</span> Help
            </a>
          </div>
        </div>
      </div>

      <DeveloperFooter />
    </div>
  );
}
