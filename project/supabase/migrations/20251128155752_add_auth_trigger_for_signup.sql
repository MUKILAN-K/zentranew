/*
  # Add Automatic User Profile Creation on Auth Signup

  This migration creates a trigger that automatically creates a user profile 
  in the users table whenever a new user signs up in Supabase Auth.

  When a user registers via signUp():
  1. Auth user is created in auth.users
  2. This trigger fires automatically
  3. A corresponding profile is created in users table with role='admin'
  4. User data is immediately available for login
*/

-- Create a trigger function that runs when a new user signs up
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.users (id, email, name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_metadata->>'name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_metadata->>'role', 'admin')
  );
  RETURN NEW;
END;
$$;

-- Drop trigger if it exists to avoid conflicts
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create trigger on auth.users insert
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();