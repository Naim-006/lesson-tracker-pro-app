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
2. Open `SUPABASE_SCHEMA.sql` from the project root and copy the entire contents
3. Paste it into the SQL Editor
4. Click "Run" to execute the schema
5. Verify all tables were created successfully by checking the "Tables" section

> The schema includes everything: tables, enums, indexes, triggers, RLS policies (with `is_admin()` security definer function to avoid recursion), seed data, and the auth trigger that auto-creates a profile row on user signup.

## Step 4: Configure Flutter App

1. Open `lib/main.dart`
2. The Supabase URL and anon key are already configured:
   ```dart
   await Supabase.initialize(
     url: 'https://ssnbzixjzwiovelgezwd.supabase.co',
     anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
   );
   ```
3. If you created a NEW Supabase project, replace these with your own credentials from Project Settings → API

## Step 5: Enable Email Authentication

1. Go to Authentication → Providers in Supabase Dashboard
2. Click on "Email"
3. Enable the provider
4. Configure email settings:
   - **Confirm email**: Enabled (required)
   - **Secure email change**: Enabled
   - **Secure password reset**: Enabled
5. **IMPORTANT**: SMTP must be configured for verification emails to send. Go to Authentication → Settings and set up a custom SMTP provider.

## Step 6: Test Authentication Flow

1. Run your Flutter app
2. You should see the onboarding screen
3. Navigate through onboarding
4. Select "I'm an Instructor"
5. Sign up with name, UK phone, email, password
6. Check your email for verification link
7. Verify the email
8. Log in — you'll be directed to subscription selection
9. Select a plan or continue with free trial → enters Instructor Portal

## Step 8: Test Pupil Portal

1. As an instructor, add a pupil and send an invitation
2. Sign up as a pupil using the invited email
3. Verify email
4. Login — pupil portal with home, journey, chat, menu
5. Features: progress tracking, messaging, payments, slot requests

## Step 9: Test Admin Portal

1. Manually insert an admin profile in Supabase Table Editor:
   ```sql
   INSERT INTO profiles (id, full_name, email, role)
   VALUES ('USER_UUID_FROM_AUTH', 'Admin Name', 'admin@email.com', 'admin');
   ```
2. Login with the admin account → Admin Shell with full dashboard
3. Manage: instructors, subscriptions, plans, promo codes, payments, settings

## Troubleshooting

### Infinite recursion in RLS policy (code 42P17)
- Caused by the `admins_read_all_profiles` policy querying `profiles` itself.
- **Fix**: The schema now defines a `public.is_admin()` SECURITY DEFINER function that bypasses RLS. If you have the old schema, run:
  ```sql
  CREATE OR REPLACE FUNCTION public.is_admin() RETURNS BOOLEAN
  LANGUAGE sql SECURITY DEFINER STABLE AS $$
    SELECT EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  $$;
  ALTER POLICY "admins_read_all_profiles" ON profiles USING (public.is_admin());
  ```
- Then update all other policies referencing `SELECT ... FROM profiles WHERE role = 'admin'` to use `public.is_admin()`.

### Profile not created on signup
- Check that the `on_auth_user_created` trigger exists in Triggers section
- The trigger is included in `SUPABASE_SCHEMA.sql` Part 7 — re-run the full schema if missing
- Manually insert a profile row if needed

### Email verification not working
- Check if email provider is enabled in Supabase
- Check spam folder
- Ensure SMTP settings are configured in Authentication → Settings

### Authentication errors
- Verify URL and anon key are correct in `lib/main.dart`
- Check if user is email verified
- Check RLS policies don't block access

### Data not loading
- Verify database schema was executed (check tables exist)
- Check RLS policies allow access (run as authenticated user)
- Ensure user role in profiles table matches expected role

### "No invitation" for pupil signup
- Instructor must first invite the pupil via email in the Pupils section
- The invitation must exist in `pupil_invitations` table with status `pending`

## Next Steps

After successful setup:
1. **Stripe Integration**: Install `flutter_stripe` package and implement payment intents
2. **Push Notifications**: Set up Supabase Realtime or Firebase Cloud Messaging
3. **File Storage**: Configure Supabase Storage buckets for avatars, receipts, resources
4. **Custom Branding**: Set up email templates in Supabase
5. **Data Migration**: Existing users' local data can be migrated via the export/import tools
