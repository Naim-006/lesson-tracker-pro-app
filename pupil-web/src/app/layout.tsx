import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'Lesson Tracker - Pupil Registration',
  description: 'Complete your registration with your driving instructor',
  icons: { icon: '/favicon.ico' },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className="bg-[#f8f6f2] min-h-screen">{children}</body>
    </html>
  );
}
