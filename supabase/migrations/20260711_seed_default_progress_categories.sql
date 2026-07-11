-- Seed default progress categories and skill templates for an instructor.
-- Usage: SELECT seed_default_progress_categories('instructor-uuid-here');
-- This is safe to call multiple times — it only inserts if the instructor
-- has zero categories.

CREATE OR REPLACE FUNCTION public.seed_default_progress_categories(p_instructor_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Only seed if instructor has no categories yet
  IF NOT EXISTS (SELECT 1 FROM progress_categories WHERE instructor_id = p_instructor_id) THEN
    INSERT INTO progress_categories (instructor_id, title, description, order_index) VALUES
      (p_instructor_id, 'Preparation', 'Cockpit Checks,Safety Checks,Vehicle Controls,Seat Positioning,Mirrors', 0),
      (p_instructor_id, 'Traffic', 'Signals,Anticipation,Use of Speed,Meeting Traffic,Crossing Traffic,Overtaking', 1),
      (p_instructor_id, 'Junctions', 'Left Turn,Right Turn,Emerging', 2),
      (p_instructor_id, 'Traffic Management', 'Roundabouts,Mini Roundabouts,Pedestrian Crossing,Dual Carriageways', 3),
      (p_instructor_id, 'Manoeuvres', 'Straight Reverse,Left Reverse,Right Reverse,Parking in a Bay,Parallel Parking,Park on the Right-hand Side of Road,Turning In-road', 4),
      (p_instructor_id, 'Situations', 'Emergency Stop,Daytime Driving,Nighttime Driving,Dry Roads,Wet Roads,Country Roads,Town and City Roads,Sat Nav Driving,Following Road Signs', 5);
  END IF;
END;
$$;
