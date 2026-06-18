import { z } from 'zod';

export const submitFormSchema = z.object({
  link_token: z.string().min(1, 'Invalid link'),
  first_name: z.string().min(1, 'First name is required').max(100),
  last_name: z.string().min(1, 'Last name is required').max(100),
  email: z.string().email('Invalid email address'),
  phone: z.string().max(20).optional().or(z.literal('')),
  address: z.string().max(200).optional().or(z.literal('')),
  postcode: z.string().max(20).optional().or(z.literal('')),
  pickup_location: z.string().max(200).optional().or(z.literal('')),
  dropoff_location: z.string().max(200).optional().or(z.literal('')),
  preferred_days: z.array(z.string()).optional(),
  preferred_times: z.array(z.string()).optional(),
  learning_goals: z.string().max(500).optional().or(z.literal('')),
  experience_level: z.string().optional().or(z.literal('')),
  emergency_contact_name: z.string().max(100).optional().or(z.literal('')),
  emergency_contact_phone: z.string().max(20).optional().or(z.literal('')),
  notes: z.string().max(500).optional().or(z.literal('')),
});

export type SubmitFormData = z.infer<typeof submitFormSchema>;

export const reviewSchema = z.object({
  submission_id: z.string().uuid(),
  action: z.enum(['approve', 'reject']),
  review_notes: z.string().max(500).optional().or(z.literal('')),
});

export type ReviewData = z.infer<typeof reviewSchema>;
