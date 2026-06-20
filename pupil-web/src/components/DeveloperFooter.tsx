export default function DeveloperFooter() {
  return (
    <footer className="mt-12 pb-8 text-center">
      <div className="border-t border-gray-200 pt-6">
        <p className="text-xs text-gray-400">
          Developed by{' '}
          <span className="font-semibold text-gray-500">NextByte</span>
        </p>
        <div className="flex items-center justify-center gap-3 mt-2">
          <a href="/help" className="text-xs text-sunset-600 hover:text-sunset-700 underline">
            Help & Support
          </a>
          <span className="text-xs text-gray-300">|</span>
          <a
            href="https://wa.me/8801984862536"
            target="_blank"
            rel="noopener noreferrer"
            className="text-xs text-sunset-600 hover:text-sunset-700 underline"
          >
            WhatsApp
          </a>
          <span className="text-xs text-gray-300">|</span>
          <a href="tel:+8801984862536" className="text-xs text-sunset-600 hover:text-sunset-700">
            +880 1984-862536
          </a>
        </div>
        <p className="text-xs text-gray-300 mt-2">
          &copy; {new Date().getFullYear()} Lesson Tracker. All rights reserved.
        </p>
      </div>
    </footer>
  );
}
