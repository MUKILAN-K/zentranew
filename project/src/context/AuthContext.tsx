import React, { createContext, useContext, useState, useEffect } from 'react';
import { User as SupabaseUser } from '@supabase/supabase-js';
import { supabase, AuthUser } from '../lib/supabase';

interface AuthContextType {
  user: AuthUser | null;
  loading: boolean;
  login: (email: string, password: string) => Promise<{ success: boolean; error?: string }>;
  logout: () => Promise<void>;
  isOwner: boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<AuthUser | null>(null);
  const [loading, setLoading] = useState(true);

  const fetchUserProfile = async (supabaseUser: SupabaseUser): Promise<AuthUser | null> => {
    try {
      console.log('Fetching user profile for ID:', supabaseUser.id);
      
      // Fetch user profile from users table
      const { data: userProfile, error: userError } = await supabase
        .from('users')
        .select('*')
        .eq('id', supabaseUser.id)
        .single();

      console.log('User profile fetch result:', { userProfile, userError });

      // If we successfully fetched a user profile, return it
      if (userProfile && !userError) {
        console.log('Found existing user profile:', userProfile);
        
        // If user is an admin (owner), fetch their organization
        let organization = null;
        if (userProfile.role === 'admin') {
          const { data: orgData, error: orgError } = await supabase
            .from('shops')
            .select('*')
            .eq('manager_id', userProfile.id)
            .single();

          console.log('Organization fetch result:', { orgData, orgError });

          if (!orgError && orgData) {
            organization = orgData;
          }
        }

        return {
          ...userProfile,
          organization
        };
      }

      // If we got an error or no user profile, try to create one
      console.error('Error fetching user profile or no profile found:', userError);
      if (userError) {
        console.log('Error details:', {
          code: userError.code,
          message: userError.message,
          details: userError.details
        });
      }
      
      console.log('Attempting to create user profile for ID:', supabaseUser.id);
      
      // Get user metadata from auth
      const name = supabaseUser.user_metadata?.name || supabaseUser.email?.split('@')[0] || 'User';
      const role = supabaseUser.user_metadata?.role || 'admin'; // Default to admin for new signups

      console.log('Creating user profile with data:', {
        id: supabaseUser.id,
        email: supabaseUser.email,
        name: name,
        role: role
      });

      // Try to insert the user profile
      const { data: newUser, error: insertError } = await supabase
        .from('users')
        .insert({
          id: supabaseUser.id,
          email: supabaseUser.email,
          name: name,
          role: role
        })
        .select()
        .single();

      console.log('User insert result:', { newUser, insertError });

      if (insertError) {
        console.error('Error creating user profile:', insertError);
        console.log('Insert error details:', {
          code: insertError.code,
          message: insertError.message,
          details: insertError.details
        });
        // Even if we can't create the user profile, let's not fail completely
        // Return a minimal user object
        return {
          id: supabaseUser.id,
          email: supabaseUser.email,
          name: name,
          role: role,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        } as AuthUser;
      }

      // If user is an admin (owner), create their organization
      let organization = null;
      if (newUser.role === 'admin') {
        const orgName = `${newUser.name}'s Organization`;
        console.log('Creating organization for admin user:', {
          name: orgName,
          manager_id: newUser.id
        });

        const { data: orgData, error: orgError } = await supabase
          .from('shops')
          .insert({
            name: orgName,
            manager_id: newUser.id
          })
          .select()
          .single();

        console.log('Shop insert result:', { orgData, orgError });

        if (orgError) {
          console.error('Error creating organization:', orgError);
          console.log('Shop insert error details:', {
            code: orgError.code,
            message: orgError.message,
            details: orgError.details
          });
        }

        if (!orgError && orgData) {
          // Update user with organization_id
          console.log('Updating user with organization ID:', orgData.id);
          const { error: userUpdateError } = await supabase
            .from('users')
            .update({ organization_id: orgData.id })
            .eq('id', newUser.id);

          console.log('User update result:', { userUpdateError });

          if (userUpdateError) {
            console.error('User update error:', userUpdateError);
          }

          organization = orgData;
        }
      }

      return {
        ...newUser,
        organization
      };

    } catch (error) {
      console.error('Error in fetchUserProfile:', error);
      // Return a minimal user object even if we encounter an error
      return null;
    }
  };

  const login = async (email: string, password: string): Promise<{ success: boolean; error?: string }> => {
    try {
      setLoading(true);

      // Authenticate with Supabase
      const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
        email,
        password
      });

      if (authError) {
        return {
          success: false,
          error: 'Invalid login credentials. Please check your email and password.'
        };
      }

      if (!authData.user) {
        return {
          success: false,
          error: 'Authentication failed. Please try again.'
        };
      }

      // Fetch user profile
      const userProfile = await fetchUserProfile(authData.user);

      // Even if we can't fetch the full profile, let's create a minimal one
      if (!userProfile) {
        // Create a minimal user profile
        const minimalProfile: AuthUser = {
          id: authData.user.id,
          email: authData.user.email || email,
          name: authData.user.user_metadata?.name || authData.user.email?.split('@')[0] || 'User',
          role: authData.user.user_metadata?.role || 'admin',
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        };
      
        setUser(minimalProfile);
        return { success: true };
      }

      // Set user
      setUser(userProfile);
      return { success: true };

    } catch (error) {
      console.error('Login error:', error);
      return {
        success: false,
        error: 'Network error. Please check your connection and try again.'
      };
    } finally {
      setLoading(false);
    }
  };

  const logout = async (): Promise<void> => {
    try {
      setLoading(true);
      await supabase.auth.signOut();
      setUser(null);
    } catch (error) {
      console.error('Logout error:', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    // Check initial session
    const initializeAuth = async () => {
      try {
        console.log('Initializing auth session');
        const { data: { session } } = await supabase.auth.getSession();
        console.log('Current session:', session);
      
        if (session?.user) {
          console.log('User is logged in, fetching profile');
          const userProfile = await fetchUserProfile(session.user);
          // Set user regardless of role for now, we'll check role in protected routes
          if (userProfile) {
            setUser(userProfile);
          }
        } else {
          console.log('No active session');
        }
      } catch (error) {
        console.error('Auth initialization error:', error);
      } finally {
        console.log('Auth initialization complete');
        setLoading(false);
      }
    };

    initializeAuth();

    // Listen for auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange(async (event, session) => {
      console.log('Auth state changed:', event, session?.user?.id);
      
      if (event === 'SIGNED_OUT' || !session?.user) {
        console.log('User signed out');
        setUser(null);
        setLoading(false);
      } else if (event === 'SIGNED_IN' && session?.user) {
        console.log('User signed in, fetching profile');
        const userProfile = await fetchUserProfile(session.user);
        // Set user regardless of role for now, we'll check role in protected routes
        if (userProfile) {
          setUser(userProfile);
        }
        setLoading(false);
      }
    });

    return () => {
      console.log('Unsubscribing from auth state changes');
      subscription.unsubscribe();
    };
  }, []);

  const isOwner = user?.role === 'admin';

  return (
    <AuthContext.Provider value={{ user, loading, login, logout, isOwner }}>
      {children}
    </AuthContext.Provider>
  );
};