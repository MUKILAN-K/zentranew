/*
  # Complete Zentra Database Schema with Onboarding System

  ## Overview
  Creates complete database schema including:
  - Base user and organization tables
  - Extended onboarding system for auto-generation
  - Multi-branch management
  - Employee tracking
  - Inventory and product management
  - Analytics and preferences

  ## Tables Created
  
  ### Base Tables
  1. shops - Organizations/companies
  2. users - User profiles linked to auth
  
  ### Onboarding Tables
  3. onboarding_sessions - Wizard progress tracking
  4. shop_branches - Individual store locations
  5. employees - Staff management
  6. product_categories - Inventory categorization
  7. products - Product inventory
  8. organization_settings - Business configuration
  9. analytics_preferences - AI insights preferences

  ## Security
  - RLS enabled on all tables
  - Organization-based data isolation
  - Role-based access control (admin/manager/staff)
  
  ## Performance
  - Comprehensive indexing
  - Automatic timestamp updates
  - Optimized for multi-branch queries
*/

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ========================================
-- BASE TABLES: SHOPS AND USERS
-- ========================================

-- Shops table (organizations)
CREATE TABLE shops (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  manager_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  org_code TEXT UNIQUE,
  passkey TEXT,
  industry_type TEXT,
  total_branches INTEGER DEFAULT 1,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Users table (profiles)
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

-- Enable RLS
ALTER TABLE shops ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- ========================================
-- ONBOARDING SESSIONS TABLE
-- ========================================
CREATE TABLE onboarding_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  current_step INTEGER DEFAULT 1,
  total_steps INTEGER DEFAULT 7,
  completed BOOLEAN DEFAULT false,
  business_data JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE onboarding_sessions ENABLE ROW LEVEL SECURITY;

-- ========================================
-- SHOP BRANCHES TABLE
-- ========================================
CREATE TABLE shop_branches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES shops(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  location TEXT NOT NULL,
  size_category TEXT CHECK (size_category IN ('Small', 'Medium', 'Large')) DEFAULT 'Medium',
  theme_preference TEXT DEFAULT 'Light',
  opening_time TIME DEFAULT '09:00:00',
  closing_time TIME DEFAULT '21:00:00',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE shop_branches ENABLE ROW LEVEL SECURITY;

-- ========================================
-- EMPLOYEES TABLE
-- ========================================
CREATE TABLE employees (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id UUID REFERENCES shop_branches(id) ON DELETE CASCADE NOT NULL,
  organization_id UUID REFERENCES shops(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  role TEXT CHECK (role IN ('Manager', 'Cashier', 'Staff', 'Auditor')) NOT NULL,
  salary DECIMAL(10, 2) DEFAULT 0,
  contact_number TEXT,
  shift_start TIME,
  shift_end TIME,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE employees ENABLE ROW LEVEL SECURITY;

-- ========================================
-- PRODUCT CATEGORIES TABLE
-- ========================================
CREATE TABLE product_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES shops(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(organization_id, name)
);

ALTER TABLE product_categories ENABLE ROW LEVEL SECURITY;

-- ========================================
-- PRODUCTS TABLE
-- ========================================
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id UUID REFERENCES shop_branches(id) ON DELETE CASCADE NOT NULL,
  category_id UUID REFERENCES product_categories(id) ON DELETE SET NULL,
  organization_id UUID REFERENCES shops(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  selling_price DECIMAL(10, 2) NOT NULL,
  cost_price DECIMAL(10, 2) NOT NULL,
  current_stock INTEGER DEFAULT 0,
  min_stock_level INTEGER DEFAULT 10,
  supplier_name TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- ========================================
-- ORGANIZATION SETTINGS TABLE
-- ========================================
CREATE TABLE organization_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES shops(id) ON DELETE CASCADE NOT NULL UNIQUE,
  industry_type TEXT NOT NULL,
  currency TEXT DEFAULT 'INR',
  gst_enabled BOOLEAN DEFAULT true,
  billing_format TEXT DEFAULT 'Detailed',
  discounts_enabled BOOLEAN DEFAULT true,
  brand_color TEXT DEFAULT '#3B82F6',
  logo_url TEXT,
  business_slogan TEXT,
  two_factor_enabled BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE organization_settings ENABLE ROW LEVEL SECURITY;

-- ========================================
-- ANALYTICS PREFERENCES TABLE
-- ========================================
CREATE TABLE analytics_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES shops(id) ON DELETE CASCADE NOT NULL UNIQUE,
  performance_ranking BOOLEAN DEFAULT true,
  sales_forecasting BOOLEAN DEFAULT true,
  inventory_predictions BOOLEAN DEFAULT true,
  fraud_detection BOOLEAN DEFAULT true,
  dashboard_style TEXT DEFAULT 'Modern',
  low_stock_alerts BOOLEAN DEFAULT true,
  daily_summaries BOOLEAN DEFAULT true,
  performance_alerts BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE analytics_preferences ENABLE ROW LEVEL SECURITY;

-- ========================================
-- RLS POLICIES: SHOPS
-- ========================================
CREATE POLICY "shops_select_manager_or_org_admin" ON shops
  FOR SELECT TO authenticated
  USING (
    (manager_id = auth.uid()) OR
    EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin' AND u.organization_id = shops.id)
  );

CREATE POLICY "shops_insert_manager" ON shops
  FOR INSERT TO authenticated
  WITH CHECK (manager_id = auth.uid());

CREATE POLICY "shops_update_manager_or_org_admin" ON shops
  FOR UPDATE TO authenticated
  USING (
    (manager_id = auth.uid()) OR
    EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin' AND u.organization_id = shops.id)
  )
  WITH CHECK (
    (manager_id = auth.uid()) OR
    EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin' AND u.organization_id = shops.id)
  );

CREATE POLICY "shops_delete_manager_or_org_admin" ON shops
  FOR DELETE TO authenticated
  USING (
    (manager_id = auth.uid()) OR
    EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin' AND u.organization_id = shops.id)
  );

-- ========================================
-- RLS POLICIES: USERS
-- ========================================
CREATE POLICY "users_select_self" ON users
  FOR SELECT TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "users_select_org_managers_admins" ON users
  FOR SELECT TO authenticated
  USING (
    EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.organization_id = users.organization_id AND u.role IN ('admin','manager'))
  );

CREATE POLICY "users_insert_self" ON users
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = id);

CREATE POLICY "users_insert_by_admin_manager" ON users
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role IN ('admin','manager') AND u.organization_id = users.organization_id)
  );

CREATE POLICY "users_update_self" ON users
  FOR UPDATE TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "users_update_by_admin_manager" ON users
  FOR UPDATE TO authenticated
  USING (
    EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role IN ('admin','manager') AND u.organization_id = users.organization_id)
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role IN ('admin','manager') AND u.organization_id = users.organization_id)
  );

CREATE POLICY "users_delete_by_admin" ON users
  FOR DELETE TO authenticated
  USING (
    EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin' AND u.organization_id = users.organization_id)
  );

-- ========================================
-- RLS POLICIES: ONBOARDING
-- ========================================
CREATE POLICY "users_manage_own_onboarding" ON onboarding_sessions
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ========================================
-- RLS POLICIES: BRANCHES
-- ========================================
CREATE POLICY "org_users_manage_branches" ON shop_branches
  FOR ALL TO authenticated
  USING (
    EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.organization_id = shop_branches.organization_id AND u.role IN ('admin', 'manager'))
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.organization_id = shop_branches.organization_id AND u.role IN ('admin', 'manager'))
  );

-- ========================================
-- RLS POLICIES: EMPLOYEES
-- ========================================
CREATE POLICY "org_users_manage_employees" ON employees
  FOR ALL TO authenticated
  USING (
    EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.organization_id = employees.organization_id AND u.role IN ('admin', 'manager'))
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.organization_id = employees.organization_id AND u.role IN ('admin', 'manager'))
  );

-- ========================================
-- RLS POLICIES: CATEGORIES
-- ========================================
CREATE POLICY "org_users_manage_categories" ON product_categories
  FOR ALL TO authenticated
  USING (
    EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.organization_id = product_categories.organization_id)
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.organization_id = product_categories.organization_id)
  );

-- ========================================
-- RLS POLICIES: PRODUCTS
-- ========================================
CREATE POLICY "org_users_manage_products" ON products
  FOR ALL TO authenticated
  USING (
    EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.organization_id = products.organization_id)
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.organization_id = products.organization_id)
  );

-- ========================================
-- RLS POLICIES: SETTINGS
-- ========================================
CREATE POLICY "org_admin_manage_settings" ON organization_settings
  FOR ALL TO authenticated
  USING (
    EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.organization_id = organization_settings.organization_id AND u.role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.organization_id = organization_settings.organization_id AND u.role = 'admin')
  );

-- ========================================
-- RLS POLICIES: ANALYTICS
-- ========================================
CREATE POLICY "org_admin_manage_analytics" ON analytics_preferences
  FOR ALL TO authenticated
  USING (
    EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.organization_id = analytics_preferences.organization_id AND u.role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.organization_id = analytics_preferences.organization_id AND u.role = 'admin')
  );

-- ========================================
-- HELPER FUNCTIONS
-- ========================================
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

CREATE OR REPLACE FUNCTION generate_passkey()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN 'PASS-' || UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 12));
END;
$$;

-- Set defaults for shops
ALTER TABLE shops ALTER COLUMN org_code SET DEFAULT generate_org_code();
ALTER TABLE shops ALTER COLUMN passkey SET DEFAULT generate_passkey();

-- ========================================
-- TIMESTAMP UPDATE FUNCTION
-- ========================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- TRIGGERS
-- ========================================
CREATE TRIGGER shops_updated_at BEFORE UPDATE ON shops FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER onboarding_sessions_updated_at BEFORE UPDATE ON onboarding_sessions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER shop_branches_updated_at BEFORE UPDATE ON shop_branches FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER employees_updated_at BEFORE UPDATE ON employees FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER product_categories_updated_at BEFORE UPDATE ON product_categories FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER products_updated_at BEFORE UPDATE ON products FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER organization_settings_updated_at BEFORE UPDATE ON organization_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER analytics_preferences_updated_at BEFORE UPDATE ON analytics_preferences FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ========================================
-- INDEXES
-- ========================================
CREATE INDEX idx_shops_manager_id ON shops(manager_id);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_organization_id ON users(organization_id);
CREATE INDEX idx_onboarding_user ON onboarding_sessions(user_id);
CREATE INDEX idx_onboarding_completed ON onboarding_sessions(completed);
CREATE INDEX idx_branches_org ON shop_branches(organization_id);
CREATE INDEX idx_branches_active ON shop_branches(is_active);
CREATE INDEX idx_employees_branch ON employees(branch_id);
CREATE INDEX idx_employees_org ON employees(organization_id);
CREATE INDEX idx_employees_role ON employees(role);
CREATE INDEX idx_categories_org ON product_categories(organization_id);
CREATE INDEX idx_products_branch ON products(branch_id);
CREATE INDEX idx_products_org ON products(organization_id);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_stock ON products(current_stock);
CREATE INDEX idx_settings_org ON organization_settings(organization_id);
CREATE INDEX idx_analytics_org ON analytics_preferences(organization_id);