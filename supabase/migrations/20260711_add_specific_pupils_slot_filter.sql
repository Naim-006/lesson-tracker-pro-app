-- Allow open slots targeted at specific pupils
ALTER TYPE slot_group_filter ADD VALUE IF NOT EXISTS 'specific_pupils';
