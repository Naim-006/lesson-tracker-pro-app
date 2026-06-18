import AppLogo from '@/components/AppLogo';
import DeveloperFooter from '@/components/DeveloperFooter';

export default function HomePage() {
  return (
    <div className="min-h-screen flex items-center justify-center p-4">
      <div className="glass-card rounded-3xl p-8 max-w-md w-full text-center animate-fade-in">
        <AppLogo size="lg" />

        <div className="mt-8 space-y-4">
          <div className="p-4 bg-sunset-50 rounded-2xl border border-sunset-100">
            <h2 className="font-semibold text-sunset-800">Pupil Registration</h2>
            <p className="text-sm text-sunset-700 mt-1">
              If your instructor sent you an invite link, please use that directly.
            </p>
          </div>

          <div className="grid grid-cols-1 gap-3">
            <a
              href="/dashboard"
              className="p-4 bg-white rounded-2xl border border-gray-200 hover:border-sunset-300 transition-all group"
            >
              <h3 className="font-semibold text-gray-900 group-hover:text-sunset-600">
                Instructor Dashboard
              </h3>
              <p className="text-xs text-gray-500 mt-1">
                Manage pupil registrations and invite links
              </p>
            </a>
          </div>
        </div>

        <DeveloperFooter />
      </div>
    </div>
  );
}
