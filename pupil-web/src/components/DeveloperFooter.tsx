export default function DeveloperFooter() {
  return (
    <footer className="mt-12 pb-8 text-center">
      <div className="border-t border-gray-200 pt-6">
        <p className="text-xs text-gray-400">
          Developed by{' '}
          <span className="font-semibold text-gray-500">NextByte</span>
        </p>
        <p className="text-xs text-gray-400 mt-1">
          Need help?{' '}
          <a
            href="https://wa.me/8801984862536"
            target="_blank"
            rel="noopener noreferrer"
            className="text-sunset-600 hover:text-sunset-700 underline"
          >
            Contact on WhatsApp
          </a>
          {' '}or call{' '}
          <a href="tel:+8801984862536" className="text-sunset-600 hover:text-sunset-700">
            +880 1984-862536
          </a>
        </p>
        <p className="text-xs text-gray-300 mt-2">
          &copy; {new Date().getFullYear()} Lesson Tracker. All rights reserved.
        </p>
      </div>
    </footer>
  );
}
