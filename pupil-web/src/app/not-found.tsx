import Link from 'next/link';
import AppLogo from '@/components/AppLogo';
import DeveloperFooter from '@/components/DeveloperFooter';

export default function NotFound() {
  return (
    <div className="min-h-screen bg-[#f8f6f2] flex flex-col items-center justify-center p-6">
      <AppLogo size="lg" />
      <div className="mt-8 text-center max-w-md">
        <div className="w-16 h-16 mx-auto mb-4 rounded-2xl bg-amber-50 flex items-center justify-center">
          <svg className="w-8 h-8 text-amber-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4.5c-.77-.833-2.694-.833-3.464 0L3.34 16.5c-.77.833.192 2.5 1.732 2.5z" />
          </svg>
        </div>
        <h1 className="text-xl font-bold text-gray-900 mb-2">Page Not Found</h1>
        <p className="text-gray-500 mb-6 text-sm">
          The page you&apos;re looking for doesn&apos;t exist or has been moved.
        </p>
        <Link
          href="/"
          className="inline-block px-6 py-3 bg-gradient-to-r from-[#F97316] to-[#E85D3A] text-white font-semibold rounded-xl hover:opacity-90 transition-opacity"
        >
          Go Home
        </Link>
      </div>
      <div className="mt-12">
        <DeveloperFooter />
      </div>
    </div>
  );
}
