# Supabase Setup Guide for Lesson Tracker Pro

This guide will help you set up Supabase for your Flutter app with authentication and database.

## Prerequisites

1. Create a Supabase account at https://supabase.com
2. Have your Flutter project ready

## Step 1: Create Supabase Project

1. Go to Supabase Dashboard: https://supabase.com/dashboard
2. Click "New Project"
3. Enter project name: `lesson-tracker-pro`
4. Choose a database password (save it securely)
5. Select a region closest to your users
6. Click "Create new project"
7. Wait for the project to be created (2-3 minutes)

## Step 2: Get Project Credentials

1. Once the project is ready, go to Project Settings → API
2. Copy the following values:
   - **Project URL** (looks like: `https://xxxxxxxx.supabase.co`)
   - **anon public key** (looks like: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`)

## Step 3: Run Database Schema

1. Go to the SQL Editor in Supabase Dashboard
2. Open the file `SUPABASE_DATABASE_DESIGN.md` in your project
3. Copy the entire SQL schema from that file
4. Paste it into the SQL Editor
5. Click "Run" to execute the schema
6. Verify all tables were created successfully

## Step 4: Configure Flutter App

1. Open `lib/main.dart`
2. Replace the placeholder values:
   ```dart
   await Supabase.initialize(
     url: 'YOUR_SUPABASE_URL',  // Replace with your Project URL
     anonKey: 'YOUR_SUPABASE_ANON_KEY',  // Replace with your anon key
   );
   ```

## Step 5: Enable Email Authentication

1. Go to Authentication → Providers in Supabase Dashboard
2. Click on "Email"
3. Ensure "Enable Email provider" is turned on
4. Configure email settings:
   - **Confirm email**: Enabled (recommended)
   - **Secure email change**: Enabled
   - **Secure password reset**: Enabled

## Step 6: Test Authentication Flow

1. Run your Flutter app
2. You should see the onboarding screen
3. Navigate through onboarding
4. Select a role (Pupil or Instructor)
5. Try signing up a new user
6. Check your email for verification link
7. Verify the email
8. Try logging in

## Step 7: Test Pupil Portal

1. Sign up as a pupil
2. Verify email
3. Login as pupil
4. You should see the pupil portal with:
   - Home dashboard
   - Progress tracking
   - Enquiry system
   - Nearby tutors
   - Messaging
   - Slot requests
   - Payments

## Step 8: Test Instructor Portal

1. Sign up as an instructor
2. Verify email
3. Login as instructor
4. You should see the instructor portal (uses local storage for now)

## Troubleshooting

### Email verification not working
- Check if email provider is enabled in Supabase
- Check spam folder
- Ensure SMTP settings are configured in Supabase

### Authentication errors
- Verify URL and anon key are correct
- Check if user is email verified
- Check RLS policies in database

### Data not loading
- Verify database schema was executed
- Check RLS policies allow access
- Ensure user is authenticated

## Next Steps

After successful setup:
1. Customize the database schema if needed
2. Add more RLS policies for additional security
3. Configure email templates in Supabase
4. Set up storage for file uploads (avatars, etc.)
5. Consider migrating instructor portal data to Supabase (future enhancement)
