-- ZENTRA: COMPLETE DATABASE SETUP
-- This script creates the tables, indexes, triggers, and RLS policies needed for the application
-- Run this in the Supabase SQL Editor

-- 0. Enable gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. Drop existing tables (CAREFUL in production)
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS shops CASCADE;

-- 2. Shops table (organizations)
CREATE TABLE shops (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  manager_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 3. Users table (profiles)
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'staff' CHECK (role IN ('admin','manager','staff')),
  avatar_url TEXT,
  organization_id UUID REFERENCES shops(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 4. Enable Row Level Security
ALTER TABLE shops ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- ---------------------------
-- SHOPS RLS POLICIES
-- ---------------------------

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

-- ---------------------------
-- USERS RLS POLICIES
-- ---------------------------

-- 1) Allow user to SELECT their own profile
CREATE POLICY "users_select_self" ON users
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- 2) Allow org admins & managers to SELECT users in same organization (list employees)
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

-- 3) Allow self-signup INSERT (auth.uid() must equal id)
CREATE POLICY "users_insert_self" ON users
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- 4) Optionally allow org admins/managers to create users in their org
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

-- 5) Allow users to UPDATE their own profile
CREATE POLICY "users_update_self" ON users
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- 6) Allow org admins/managers to UPDATE users in same org
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

-- 7) Allow only org admins to DELETE users in same org
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

-- ---------------------------
-- INDEXES
-- ---------------------------
CREATE INDEX IF NOT EXISTS idx_shops_manager_id ON shops(manager_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_organization_id ON users(organization_id);

-- ---------------------------
-- TRIGGER: auto-update updated_at
-- ---------------------------
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