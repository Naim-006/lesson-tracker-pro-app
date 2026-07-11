-- Add new payment methods to the payment_method enum
ALTER TYPE payment_method ADD VALUE IF NOT EXISTS 'revolut';
ALTER TYPE payment_method ADD VALUE IF NOT EXISTS 'monzo';
ALTER TYPE payment_method ADD VALUE IF NOT EXISTS 'stripe';

-- Create transactions table if it doesn't exist
CREATE TABLE IF NOT EXISTS transactions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  instructor_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  pupil_id        UUID REFERENCES pupils(id) ON DELETE SET NULL,
  pupil_name      TEXT,
  type            transaction_type NOT NULL,
  amount          DECIMAL(10,2) NOT NULL,
  description     TEXT NOT NULL DEFAULT '',
  date            DATE NOT NULL DEFAULT CURRENT_DATE,
  payment_method  payment_method,
  payment_type    payment_type,
  category        expense_category,
  is_recurring    BOOLEAN DEFAULT false,
  receipt_url     TEXT,
  vendor_name     TEXT,
  is_reconciled   BOOLEAN DEFAULT false,
  tax_deductible  BOOLEAN DEFAULT true,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS on transactions
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

-- Instructors can manage their own transactions
DROP POLICY IF EXISTS "instructors_manage_transactions" ON transactions;
CREATE POLICY "instructors_manage_transactions" ON transactions
  FOR ALL USING (instructor_id = auth.uid());

-- Pupils can read their own transactions
DROP POLICY IF EXISTS "pupils_read_own_transactions" ON transactions;
CREATE POLICY "pupils_read_own_transactions" ON transactions
  FOR SELECT USING (pupil_id = auth.uid());
