# Supabase Database Design for Lesson Tracker Pro

## Overview
Multi-tenant driving instructor management system with role-based access control (RBAC) and Row Level Security (RLS) to ensure complete data isolation between instructors.

## Core Tables

### 1. `profiles` (extends Supabase auth.users)
```sql
CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  phone TEXT,
  role TEXT NOT NULL CHECK (role IN ('instructor', 'pupil')),
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  email_verified BOOLEAN DEFAULT FALSE
);

-- RLS Policies
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Instructors can view linked pupils"
  ON profiles FOR SELECT
  USING (
    auth.uid() IN (
      SELECT instructor_id FROM instructor_pupil_links WHERE pupil_id = profiles.id
    )
  );
```

### 2. `instructors` (Instructor-specific data)
```sql
CREATE TABLE instructors (
  id UUID REFERENCES profiles(id) PRIMARY KEY,
  business_name TEXT,
  instructor_title TEXT,
  hourly_rate DECIMAL(10,2) DEFAULT 35.00,
  currency TEXT DEFAULT 'GBP',
  location_lat DECIMAL(10,8),
  location_lng DECIMAL(10,8),
  location_address TEXT,
  service_radius_km INTEGER DEFAULT 20,
  bio TEXT,
  certifications TEXT[],
  languages TEXT[],
  vehicle_make TEXT,
  vehicle_model TEXT,
  vehicle_year INTEGER,
  vehicle_plate TEXT,
  availability JSONB, -- Weekly schedule
  is_verified BOOLEAN DEFAULT FALSE,
  rating DECIMAL(3,2),
  review_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE instructors ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Instructors can view own data"
  ON instructors FOR ALL
  USING (auth.uid() = id);

CREATE POLICY "Pupils can view linked instructors"
  ON instructors FOR SELECT
  USING (
    auth.uid() IN (
      SELECT pupil_id FROM instructor_pupil_links WHERE instructor_id = instructors.id
    )
  );

CREATE POLICY "Public can view verified instructors for discovery"
  ON instructors FOR SELECT
  USING (is_verified = TRUE);
```

### 3. `pupils` (Pupil-specific data)
```sql
CREATE TABLE pupils (
  id UUID REFERENCES profiles(id) PRIMARY KEY,
  address TEXT,
  postcode TEXT,
  gearbox_preference TEXT CHECK (gearbox_preference IN ('manual', 'automatic', 'any')),
  learning_goals TEXT[],
  experience_level TEXT CHECK (experience_level IN ('beginner', 'intermediate', 'advanced')),
  emergency_contact_name TEXT,
  emergency_contact_phone TEXT,
  test_date DATE,
  preferred_days TEXT[],
  preferred_times TEXT[],
  test_progress JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE pupils ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Pupils can view own data"
  ON pupils FOR ALL
  USING (auth.uid() = id);

CREATE POLICY "Instructors can view linked pupils"
  ON pupils FOR SELECT
  USING (
    auth.uid() IN (
      SELECT instructor_id FROM instructor_pupil_links WHERE pupil_id = pupils.id
    )
  );
```

### 4. `instructor_pupil_links` (Many-to-many relationship)
```sql
CREATE TABLE instructor_pupil_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID REFERENCES instructors(id) ON DELETE CASCADE,
  pupil_id UUID REFERENCES pupils(id) ON DELETE CASCADE,
  status TEXT CHECK (status IN ('pending', 'active', 'inactive', 'completed')) DEFAULT 'pending',
  hourly_rate DECIMAL(10,2),
  linked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(instructor_id, pupil_id)
);

-- RLS Policies
ALTER TABLE instructor_pupil_links ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Instructors can view own links"
  ON instructor_pupil_links FOR ALL
  USING (auth.uid() = instructor_id);

CREATE POLICY "Pupils can view own links"
  ON instructor_pupil_links FOR ALL
  USING (auth.uid() = pupil_id);
```

### 5. `lessons` (Lesson bookings)
```sql
CREATE TABLE lessons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID REFERENCES instructors(id) ON DELETE CASCADE,
  pupil_id UUID REFERENCES pupils(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  time TEXT NOT NULL,
  duration INTEGER NOT NULL, -- minutes
  pickup_location TEXT,
  dropoff_location TEXT,
  lesson_type TEXT CHECK (lesson_type IN ('standard', 'motorway', 'pass_plus', 'mock_test', 'refresher')),
  notes TEXT,
  status TEXT CHECK (status IN ('scheduled', 'completed', 'cancelled', 'no_show')) DEFAULT 'scheduled',
  paid BOOLEAN DEFAULT FALSE,
  amount DECIMAL(10,2),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Instructors can view own lessons"
  ON lessons FOR ALL
  USING (auth.uid() = instructor_id);

CREATE POLICY "Pupils can view own lessons"
  ON lessons FOR ALL
  USING (auth.uid() = pupil_id);
```

### 6. `payments` (Financial transactions)
```sql
CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID REFERENCES instructors(id) ON DELETE CASCADE,
  pupil_id UUID REFERENCES pupils(id) ON DELETE CASCADE,
  lesson_id UUID REFERENCES lessons(id) ON DELETE SET NULL,
  type TEXT CHECK (type IN ('income', 'expense', 'refund')) NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  description TEXT,
  payment_method TEXT CHECK (payment_method IN ('cash', 'card', 'bank_transfer', 'online')),
  status TEXT CHECK (status IN ('pending', 'completed', 'failed', 'refunded')) DEFAULT 'pending',
  transaction_reference TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Instructors can view own payments"
  ON payments FOR ALL
  USING (auth.uid() = instructor_id);

CREATE POLICY "Pupils can view own payments"
  ON payments FOR SELECT
  USING (auth.uid() = pupil_id);
```

### 7. `enquiries` (Pupil enquiries to instructors)
```sql
CREATE TABLE enquiries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pupil_id UUID REFERENCES pupils(id) ON DELETE CASCADE,
  instructor_id UUID REFERENCES instructors(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  status TEXT CHECK (status IN ('pending', 'responded', 'accepted', 'rejected')) DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE enquiries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Instructors can view enquiries sent to them"
  ON enquiries FOR ALL
  USING (auth.uid() = instructor_id);

CREATE POLICY "Pupils can view own enquiries"
  ON enquiries FOR ALL
  USING (auth.uid() = pupil_id);
```

### 8. `messages` (In-app messaging)
```sql
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  receiver_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  lesson_id UUID REFERENCES lessons(id) ON DELETE SET NULL,
  content TEXT NOT NULL,
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view messages they sent or received"
  ON messages FOR SELECT
  USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

CREATE POLICY "Users can insert messages they send"
  ON messages FOR INSERT
  WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Users can update messages they sent"
  ON messages FOR UPDATE
  USING (auth.uid() = sender_id);
```

### 9. `open_slots` (Instructor available slots)
```sql
CREATE TABLE open_slots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID REFERENCES instructors(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  start_time TEXT NOT NULL,
  duration INTEGER NOT NULL,
  location TEXT,
  is_booked BOOLEAN DEFAULT FALSE,
  booked_by UUID REFERENCES pupils(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE open_slots ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Instructors can manage own slots"
  ON open_slots FOR ALL
  USING (auth.uid() = instructor_id);

CREATE POLICY "Pupils can view available slots"
  ON open_slots FOR SELECT
  USING (is_booked = FALSE);
```

### 10. `progress_categories` (Skill categories)
```sql
CREATE TABLE progress_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID REFERENCES instructors(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  order_index INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE progress_categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Instructors can manage own categories"
  ON progress_categories FOR ALL
  USING (auth.uid() = instructor_id);

CREATE POLICY "Pupils can view linked instructor categories"
  ON progress_categories FOR SELECT
  USING (
    auth.uid() IN (
      SELECT pupil_id FROM instructor_pupil_links WHERE instructor_id = progress_categories.instructor_id
    )
  );
```

### 11. `progress_skills` (Individual skills within categories)
```sql
CREATE TABLE progress_skills (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id UUID REFERENCES progress_categories(id) ON DELETE CASCADE,
  pupil_id UUID REFERENCES pupils(id) ON DELETE CASCADE,
  skill_name TEXT NOT NULL,
  skill_level INTEGER CHECK (skill_level >= 1 AND skill_level <= 5) DEFAULT 1,
  notes TEXT,
  last_practiced DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE progress_skills ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Instructors can view linked pupil skills"
  ON progress_skills FOR ALL
  USING (
    auth.uid() IN (
      SELECT instructor_id FROM instructor_pupil_links WHERE pupil_id = progress_skills.pupil_id
    )
  );

CREATE POLICY "Pupils can view own skills"
  ON progress_skills FOR SELECT
  USING (auth.uid() = pupil_id);
```

### 12. `teaching_resources` (Instructor teaching materials)
```sql
CREATE TABLE teaching_resources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID REFERENCES instructors(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  type TEXT CHECK (type IN ('document', 'video', 'link')) NOT NULL,
  category TEXT NOT NULL,
  description TEXT,
  video_link TEXT,
  resource_link TEXT,
  share_link TEXT,
  visibility TEXT CHECK (visibility IN ('private', 'public', 'selective')) DEFAULT 'private',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE teaching_resources ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Instructors can manage own resources"
  ON teaching_resources FOR ALL
  USING (auth.uid() = instructor_id);

CREATE POLICY "Pupils can view linked instructor public resources"
  ON teaching_resources FOR SELECT
  USING (
    visibility = 'public' AND
    auth.uid() IN (
      SELECT pupil_id FROM instructor_pupil_links WHERE instructor_id = teaching_resources.instructor_id
    )
  );
```

### 13. `resource_pupil_access` (Selective resource access)
```sql
CREATE TABLE resource_pupil_access (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  resource_id UUID REFERENCES teaching_resources(id) ON DELETE CASCADE,
  pupil_id UUID REFERENCES pupils(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(resource_id, pupil_id)
);

-- RLS Policies
ALTER TABLE resource_pupil_access ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Instructors can manage resource access"
  ON resource_pupil_access FOR ALL
  USING (
    auth.uid() IN (
      SELECT instructor_id FROM teaching_resources WHERE id = resource_id
    )
  );

CREATE POLICY "Pupils can view their resource access"
  ON resource_pupil_access FOR SELECT
  USING (auth.uid() = pupil_id);
```

### 14. `test_reports` (Driving test reports)
```sql
CREATE TABLE test_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pupil_id UUID REFERENCES pupils(id) ON DELETE CASCADE,
  instructor_id UUID REFERENCES instructors(id) ON DELETE CASCADE,
  test_date DATE NOT NULL,
  test_center_name TEXT,
  test_center_id INTEGER,
  result TEXT CHECK (result IN ('pass', 'fail')) NOT NULL,
  grade_level TEXT,
  manoeuvres TEXT[],
  scales_notes TEXT,
  aural_notes TEXT,
  notes TEXT,
  examiner_name TEXT,
  faults INTEGER DEFAULT 0,
  serious_faults INTEGER DEFAULT 0,
  dangerous_faults INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE test_reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Instructors can view linked pupil reports"
  ON test_reports FOR ALL
  USING (auth.uid() = instructor_id);

CREATE POLICY "Pupils can view own reports"
  ON test_reports FOR SELECT
  USING (auth.uid() = pupil_id);
```

### 15. `invoices` (Payment requests from instructors)
```sql
CREATE TABLE invoices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID REFERENCES instructors(id) ON DELETE CASCADE,
  pupil_id UUID REFERENCES pupils(id) ON DELETE CASCADE,
  invoice_number TEXT UNIQUE NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  description TEXT,
  due_date DATE,
  status TEXT CHECK (status IN ('pending', 'paid', 'overdue', 'cancelled')) DEFAULT 'pending',
  payment_link TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Instructors can manage own invoices"
  ON invoices FOR ALL
  USING (auth.uid() = instructor_id);

CREATE POLICY "Pupils can view own invoices"
  ON invoices FOR SELECT
  USING (auth.uid() = pupil_id);
```

### 16. `mileage_entries` (Vehicle mileage tracking)
```sql
CREATE TABLE mileage_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id UUID REFERENCES instructors(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  miles DECIMAL(10,2) NOT NULL,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE mileage_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Instructors can manage own mileage"
  ON mileage_entries FOR ALL
  USING (auth.uid() = instructor_id);
```

## Database Functions

### Function: Create profile on signup
```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, role, email_verified)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'role', 'pupil'),
    NEW.email_confirmed_at IS NOT NULL
  );
  
  -- Create role-specific profile
  IF NEW.raw_user_meta_data->>'role' = 'instructor' THEN
    INSERT INTO public.instructors (id)
    VALUES (NEW.id);
  ELSIF NEW.raw_user_meta_data->>'role' = 'pupil' THEN
    INSERT INTO public.pupils (id)
    VALUES (NEW.id);
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

### Function: Update email verification status
```sql
CREATE OR REPLACE FUNCTION public.update_email_verification()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.profiles
  SET email_verified = NEW.email_confirmed_at IS NOT NULL
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_email_confirmed
  AFTER UPDATE OF email_confirmed_at ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.update_email_verification();
```

### Function: Auto-generate invoice number
```sql
CREATE OR REPLACE FUNCTION public.generate_invoice_number()
RETURNS TRIGGER AS $$
DECLARE
  invoice_num TEXT;
BEGIN
  -- Generate invoice number in format: INV-YYYYMMDD-XXXX
  invoice_num := 'INV-' || TO_CHAR(NEW.created_at, 'YYYYMMDD') || '-' || LPAD((ROW_NUMBER() OVER (ORDER BY NEW.created_at))::TEXT, 4, '0');
  NEW.invoice_number := invoice_num;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_invoice_created
  BEFORE INSERT ON invoices
  FOR EACH ROW EXECUTE FUNCTION public.generate_invoice_number();
```

## Indexes for Performance

```sql
-- Instructor queries
CREATE INDEX idx_instructors_location ON instructors USING GIST (point(location_lng, location_lat));
CREATE INDEX idx_instructors_verified ON instructors(is_verified) WHERE is_verified = TRUE;

-- Lesson queries
CREATE INDEX idx_lessons_instructor_date ON lessons(instructor_id, date);
CREATE INDEX idx_lessons_pupil_date ON lessons(pupil_id, date);

-- Payment queries
CREATE INDEX idx_payments_instructor ON payments(instructor_id);
CREATE INDEX idx_payments_pupil ON payments(pupil_id);

-- Message queries
CREATE INDEX idx_messages_sender ON messages(sender_id, created_at DESC);
CREATE INDEX idx_messages_receiver ON messages(receiver_id, created_at DESC);

-- Enquiry queries
CREATE INDEX idx_enquiries_instructor ON enquiries(instructor_id, status);
CREATE INDEX idx_enquiries_pupil ON enquiries(pupil_id);

-- Open slots
CREATE INDEX idx_open_slots_instructor ON open_slots(instructor_id, date, is_booked);
```

## Security Notes

1. **Row Level Security (RLS)** is enabled on all tables to ensure data isolation
2. **Instructors** can only access their own data and data of linked pupils
3. **Pupils** can only access their own data and data of linked instructors
4. **Public access** is limited to verified instructor profiles for discovery
5. **Email verification** is required before account activation
6. **Cascading deletes** ensure referential integrity
7. **UUID primary keys** prevent enumeration attacks
8. **Security definer functions** for privileged operations

## Data Flow

1. User signs up → `auth.users` created → Trigger creates `profiles` and role-specific table entry
2. Email verified → Trigger updates `email_verified` flag
3. User logs in → App checks `email_verified` and `role` → Routes to appropriate portal
4. Instructor creates lesson → Only visible to that instructor and linked pupil
5. Pupil requests slot → Only visible to that pupil and instructor
6. All queries automatically filtered by RLS based on `auth.uid()`
