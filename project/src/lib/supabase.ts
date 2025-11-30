import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing Supabase environment variables');
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

// Database types
export interface User {
  id: string;
  email: string;
  name: string;
  role: 'admin' | 'manager' | 'staff';
  avatar_url?: string;
  organization_id?: string;
  created_at: string;
  updated_at: string;
}

export interface Shop {
  id: string;
  name: string;
  manager_id: string;
  created_at: string;
  updated_at: string;
}

export interface AuthUser extends User {
  organization?: Shop;
}