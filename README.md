# Lesson Tracker Pro

Professional CRM, diary, and bookkeeping app for **driving instructors** — built with Flutter for Android (iOS-ready).

## Features

| Module | Capabilities |
|--------|----------------|
| **Home** | Overview dashboard, monthly revenue hero card, today / next 7 days lessons, unpaid alerts, activity feed |
| **Pupils** | CRM with Current / Waiting / Passed tabs, search, full pupil profiles, call & email shortcuts |
| **Diary** | Day & week views, book lessons (pickup/drop-off, recurrence, shared-with-pupil), open slots, events |
| **Finances** | Income / expense / profit KPIs, filters, CSV export (fiscal year), payments & expenses |
| **Activity** | Secure messaging with lock, activity updates feed |
| **Drawer** | Enquiry Manager, Test Reports, Settings, Help (10 articles) |
| **Quick Add** | Pupil, Event, Lesson, Payment, Expense, Slot, Mileage |

## Theme

**Sunset palette** — navy `#1B263B`, orange accent `#F97316`, cream light background. Full light & dark mode toggle (moon icon in app bar).

## Run on Android

```bash
cd "d:\0 lst"
flutter pub get
flutter run
```

Release build:

```bash
flutter build apk --release
```

## Data

All data is stored locally with **SharedPreferences** (persists across restarts). Mock sample data loads on first launch. Ready to connect Supabase / Firebase when you add a backend.

## Project structure

```
lib/
  core/          # models, theme, providers, utils
  features/      # screens by module
  main.dart
assets/images/   # logo
```

## Version

1.0.0 — Lesson Tracker Pro
