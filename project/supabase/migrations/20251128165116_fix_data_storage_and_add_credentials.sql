/*
  # Fix Data Storage Issue and Add Organization Credentials

  ## Problem Identified
  - Auth trigger was not creating user profiles due to email confirmation flow
  - Missing org_code and passkey columns in shops table
  - No automatic organization creation for admin users

  ## Changes
  1. Add org_code and passkey columns to shops table
  2. Generate credentials for existing organizations
  3. Fix trigger to handle email confirmation states
  4. Add function to auto-create organization for admin users

  ## Security
  - Maintains all existing RLS policies
  - Credentials are unique per organization
*/

-- Add missing credential columns to shops table
ALTER TABLE shops 
ADD COLUMN IF NOT EXISTS org_code TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS passkey TEXT;

-- Generate org_code and passkey for existing shops
UPDATE shops 
SET 
  org_code = 'ORG-' || UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 8)),
  passkey = 'PASS-' || UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 12))
WHERE org_code IS NULL OR passkey IS NULL;

-- Function to generate unique org code
CREATE OR REPLACE FUNCTION generate_org_code()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
  new_code TEXT;
  code_exists BOOLEAN;
BEGIN
  LOOP
    new_code := 'ORG-' || UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 8));
    SELECT EXISTS(SELECT 1 FROM shops WHERE org_code = new_code) INTO code_exists;
    EXIT WHEN NOT code_exists;
  END LOOP;
  RETURN new_code;
END;
$$;

-- Function to generate passkey
CREATE OR REPLACE FUNCTION generate_passkey()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN 'PASS-' || UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 12));
END;
$$;

-- Add default values for new shops
ALTER TABLE shops 
ALTER COLUMN org_code SET DEFAULT generate_org_code(),
ALTER COLUMN passkey SET DEFAULT generate_passkey();

-- Improved trigger function that handles email confirmation
DROP FUNCTION IF EXISTS handle_new_user() CASCADE;

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  user_name TEXT;
  user_role TEXT;
  new_org_id UUID;
BEGIN
  -- Extract user metadata
  user_name := COALESCE(NEW.raw_user_meta_data->>'name', SPLIT_PART(NEW.email, '@', 1));
  user_role := COALESCE(NEW.raw_user_meta_data->>'role', 'admin');

  -- Create user profile (works regardless of email confirmation status)
  INSERT INTO public.users (id, email, name, role)
  VALUES (NEW.id, NEW.email, user_name, user_role)
  ON CONFLICT (id) DO NOTHING;

  -- If user is admin, create their organization
  IF user_role = 'admin' THEN
    INSERT INTO public.shops (name, manager_id)
    VALUES (user_name || '''s Organization', NEW.id)
    RETURNING id INTO new_org_id;

    -- Link user to their organization
    UPDATE public.users
    SET organization_id = new_org_id
    WHERE id = NEW.id;
  END IF;

  RETURN NEW;
END;
$$;

-- Recreate trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW 
  EXECUTE FUNCTION handle_new_user();

-- Also handle updates (for email confirmation)
DROP TRIGGER IF EXISTS on_auth_user_updated ON auth.users;

CREATE TRIGGER on_auth_user_updated
  AFTER UPDATE ON auth.users
  FOR EACH ROW
  WHEN (OLD.email_confirmed_at IS NULL AND NEW.email_confirmed_at IS NOT NULL)
  EXECUTE FUNCTION handle_new_user();