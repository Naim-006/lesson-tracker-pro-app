import AppLogo from '@/components/AppLogo';

export default function Loading() {
  return (
    <div className="min-h-screen bg-[#f8f6f2] flex flex-col items-center justify-center p-6">
      <AppLogo size="lg" />
      <div className="mt-8 flex flex-col items-center gap-4">
        <div className="w-8 h-8 border-2 border-[#F97316] border-t-transparent rounded-full animate-spin" />
        <p className="text-gray-400 text-sm">Loading...</p>
      </div>
    </div>
  );
}
