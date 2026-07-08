import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: {
    default: 'Lesson Tracker Pro — Driving Instructor Platform',
    template: '%s | Lesson Tracker Pro',
  },
  description:
    'The all-in-one platform for driving instructors. Manage lessons, track pupil progress, handle payments, and grow your driving school.',
  keywords: ['driving instructor', 'lesson tracker', 'pupil management', 'driving school software'],
  authors: [{ name: 'Lesson Tracker Pro' }],
  openGraph: {
    type: 'website',
    siteName: 'Lesson Tracker Pro',
    title: 'Lesson Tracker Pro — Driving Instructor Platform',
    description: 'The all-in-one platform for driving instructors.',
  },
  icons: {
    icon: '/favicon.ico',
  },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
      </head>
      <body>{children}</body>
    </html>
  );
}
