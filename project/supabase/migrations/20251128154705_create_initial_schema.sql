/*
  # Initial Database Schema Setup for Zentra

  ## Overview
  This migration creates the complete database schema for the Zentra multi-branch shop management system.

  ## Tables Created
  
  ### 1. shops (Organizations/Branches)
  - `id` (UUID, primary key) - Unique shop/organization identifier
  - `name` (TEXT) - Shop/organization name
  - `manager_id` (UUID, FK to auth.users) - Reference to the owner/manager
  - `created_at` (TIMESTAMPTZ) - Creation timestamp
  - `updated_at` (TIMESTAMPTZ) - Last update timestamp (auto-updated)

  ### 2. users (User Profiles)
  - `id` (UUID, primary key, FK to auth.users) - User ID matching Supabase Auth
  - `email` (TEXT, unique) - User email address
  - `name` (TEXT) - User's full name
  - `role` (TEXT) - User role: 'admin', 'manager', or 'staff'
  - `avatar_url` (TEXT, optional) - Profile picture URL
  - `organization_id` (UUID, FK to shops) - Reference to user's organization
  - `created_at` (TIMESTAMPTZ) - Creation timestamp
  - `updated_at` (TIMESTAMPTZ) - Last update timestamp (auto-updated)

  ## Security Features
  
  ### Row Level Security (RLS)
  - Enabled on all tables
  - Granular access control based on user roles
  - Data isolation between organizations
  
  ### Policies Created
  
  #### shops table (8 policies)
  1. SELECT: Managers and org admins can view their shops
  2. INSERT: Authenticated users can create shops where they are the manager
  3. UPDATE: Managers and org admins can update their shops
  4. DELETE: Managers and org admins can delete their shops
  
  #### users table (7 policies)
  1. SELECT (self): Users can view their own profile
  2. SELECT (org): Org admins/managers can view users in same organization
  3. INSERT (self): Users can create their own profile during signup
  4. INSERT (admin): Admins/managers can create users in their organization
  5. UPDATE (self): Users can update their own profile
  6. UPDATE (admin): Admins/managers can update users in their organization
  7. DELETE (admin): Only admins can delete users in their organization

  ## Performance
  - Indexes created on frequently queried columns
  - Automatic timestamp updates via triggers
  
  ## Important Notes
  - All operations are secured with RLS
  - Users are linked to auth.users via CASCADE delete
  - Organizations are linked to managers with SET NULL on delete
  - Timestamps are automatically managed by triggers
*/

-- Enable pgcrypto extension for gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create shops table (organizations/branches)
CREATE TABLE IF NOT EXISTS shops (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  manager_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create users table (profiles)
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'staff' CHECK (role IN ('admin','manager','staff')),
  avatar_url TEXT,
  organization_id UUID REFERENCES shops(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE shops ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- ========================================
-- SHOPS RLS POLICIES
-- ========================================

-- Allow managers or org admins to SELECT shops in their org
CREATE POLICY "shops_select_manager_or_org_admin" ON shops
  FOR SELECT
  TO authenticated
  USING (
    (manager_id = auth.uid())
    OR EXISTS (
      SELECT 1 FROM users u
      WHERE u.id = auth.uid()
        AND u.role = 'admin'
        AND u.organization_id = shops.id
    )
  );

-- Allow authenticated user to INSERT a shop where they will be manager
CREATE POLICY "shops_insert_manager" ON shops
  FOR INSERT
  TO authenticated
  WITH CHECK (manager_id = auth.uid());

-- Allow managers or org admins to UPDATE the shop
CREATE POLICY "shops_update_manager_or_org_admin" ON shops
  FOR UPDATE
  TO authenticated
  USING (
    (manager_id = auth.uid())
    OR EXISTS (
      SELECT 1 FROM users u
      WHERE u.id = auth.uid()
        AND u.role = 'admin'
        AND u.organization_id = shops.id
    )
  )
  WITH CHECK (
    (manager_id = auth.uid())
    OR EXISTS (
      SELECT 1 FROM users u
      WHERE u.id = auth.uid()
        AND u.role = 'admin'
        AND u.organization_id = shops.id
    )
  );

-- Allow managers or org admins to DELETE the shop
CREATE POLICY "shops_delete_manager_or_org_admin" ON shops
  FOR DELETE
  TO authenticated
  USING (
    (manager_id = auth.uid())
    OR EXISTS (
      SELECT 1 FROM users u
      WHERE u.id = auth.uid()
        AND u.role = 'admin'
        AND u.organization_id = shops.id
    )
  );

-- ========================================
-- USERS RLS POLICIES
-- ========================================

-- Allow user to SELECT their own profile
CREATE POLICY "users_select_self" ON users
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Allow org admins & managers to SELECT users in same organization
CREATE POLICY "users_select_org_managers_admins" ON users
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.id = auth.uid()
        AND u.organization_id = users.organization_id
        AND u.role IN ('admin','manager')
    )
  );

-- Allow self-signup INSERT (auth.uid() must equal id)
CREATE POLICY "users_insert_self" ON users
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- Allow org admins/managers to create users in their org
CREATE POLICY "users_insert_by_admin_manager" ON users
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.id = auth.uid()
        AND u.role IN ('admin','manager')
        AND u.organization_id = users.organization_id
    )
  );

-- Allow users to UPDATE their own profile
CREATE POLICY "users_update_self" ON users
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Allow org admins/managers to UPDATE users in same org
CREATE POLICY "users_update_by_admin_manager" ON users
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.id = auth.uid()
        AND u.role IN ('admin','manager')
        AND u.organization_id = users.organization_id
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.id = auth.uid()
        AND u.role IN ('admin','manager')
        AND u.organization_id = users.organization_id
    )
  );

-- Allow only org admins to DELETE users in same org
CREATE POLICY "users_delete_by_admin" ON users
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users u
      WHERE u.id = auth.uid()
        AND u.role = 'admin'
        AND u.organization_id = users.organization_id
    )
  );

-- ========================================
-- INDEXES FOR PERFORMANCE
-- ========================================

CREATE INDEX IF NOT EXISTS idx_shops_manager_id ON shops(manager_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_organization_id ON users(organization_id);

-- ========================================
-- TRIGGERS FOR AUTO-UPDATE TIMESTAMPS
-- ========================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER shops_updated_at
  BEFORE UPDATE ON shops FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER users_updated_at
  BEFORE UPDATE ON users FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();