export default function AppLogo({ size = 'md' }: { size?: 'sm' | 'md' | 'lg' }) {
  const sizes = {
    sm: { container: 'w-8 h-8', icon: 'text-sm', text: 'text-sm' },
    md: { container: 'w-12 h-12', icon: 'text-lg', text: 'text-xl' },
    lg: { container: 'w-20 h-20', icon: 'text-3xl', text: 'text-3xl' },
  };
  const s = sizes[size];

  return (
    <div className="flex items-center gap-3">
      <div
        className={`${s.container} bg-gradient-to-br from-sunset-500 to-sunset-700 rounded-2xl flex items-center justify-center shadow-lg`}
      >
        <span className={`${s.icon} text-white font-bold`}>L</span>
      </div>
      <div>
        <h1 className={`${s.text} font-bold text-gray-900`}>Lesson Tracker</h1>
        {size !== 'sm' && (
          <p className="text-xs text-gray-500">Professional Driving Instructor Platform</p>
        )}
      </div>
    </div>
  );
}
