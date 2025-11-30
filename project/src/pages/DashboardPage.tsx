import React, { useState } from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import AdminLayout from '../components/AdminLayout';
import { Copy, Check, Shield, Loader2, AlertCircle } from 'lucide-react';

const DashboardPage: React.FC = () => {
  const { user, logout, loading, isOwner } = useAuth();
  const [copiedField, setCopiedField] = useState<string | null>(null);
  const [loggingOut, setLoggingOut] = useState(false);

  // Redirect if not authenticated or not an owner
  if (!loading && (!user || !isOwner)) {
    return <Navigate to="/login" replace />;
  }

  const copyToClipboard = async (text: string, field: string) => {
    try {
      await navigator.clipboard.writeText(text);
      setCopiedField(field);
      setTimeout(() => setCopiedField(null), 2000);
    } catch (err) {
      console.error('Failed to copy text: ', err);
    }
  };

  const handleLogout = async () => {
    setLoggingOut(true);
    try {
      await logout();
    } catch (error) {
      console.error('Logout error:', error);
    } finally {
      setLoggingOut(false);
    }
  };

  const handleLogoutClick = () => {
    handleLogout();
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 dark:bg-gray-900 flex items-center justify-center">
        <div className="flex items-center space-x-2">
          <Loader2 className="h-6 w-6 animate-spin text-blue-600" />
          <span className="text-gray-600 dark:text-gray-300">Loading dashboard...</span>
        </div>
      </div>
    );
  }

  if (!user) {
    return <Navigate to="/login" replace />;
  }

  const organization = user.organization;
  const orgCode = organization?.org_code || 'ORG-LOADING';
  const passkey = organization?.passkey || 'PASS-LOADING';

  return (
    <AdminLayout onLogout={handleLogoutClick} userName={user.name} orgName={user.organization?.name}>
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Welcome Section */}
        <div className="mb-8">
          <h2 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">
            Welcome, {user.name}
          </h2>
          {organization ? (
            <p className="text-lg text-gray-600 dark:text-gray-300">
              Organization: <span className="font-semibold">{organization.name}</span>
            </p>
          ) : (
            <div className="bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg p-4 flex items-start space-x-3">
              <AlertCircle className="h-5 w-5 text-yellow-500 flex-shrink-0 mt-0.5" />
              <div>
                <p className="text-sm text-yellow-800 dark:text-yellow-200 font-medium">
                  Organization Setup Required
                </p>
                <p className="text-sm text-yellow-700 dark:text-yellow-300 mt-1">
                  Please contact support to complete your organization setup.
                </p>
              </div>
            </div>
          )}
        </div>

        {organization && (
          <>
            {/* Credentials Cards */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
              {/* Organization Code Card */}
              <div className="bg-white dark:bg-gray-800 rounded-2xl shadow-sm border border-gray-200 dark:border-gray-700 p-6 hover:shadow-md transition-shadow">
                <div className="flex items-center justify-between mb-4">
                  <div className="flex items-center space-x-3">
                    <div className="w-12 h-12 bg-blue-100 dark:bg-blue-900/20 rounded-lg flex items-center justify-center">
                      <Shield className="h-6 w-6 text-blue-600 dark:text-blue-400" />
                    </div>
                    <div>
                      <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
                        Organization Code
                      </h3>
                      <p className="text-sm text-gray-500 dark:text-gray-400">
                        Share with team members
                      </p>
                    </div>
                  </div>
                </div>
                
                <div className="bg-gray-50 dark:bg-gray-700 rounded-lg p-4 mb-4">
                  <div className="flex items-center justify-between">
                    <code className="text-2xl font-mono font-bold text-gray-900 dark:text-white tracking-wider">
                      {orgCode}
                    </code>
                    <button
                      onClick={() => copyToClipboard(orgCode, 'orgCode')}
                      className="flex items-center space-x-2 px-3 py-2 bg-blue-600 hover:bg-blue-700 text-white text-sm font-medium rounded-lg transition-colors"
                    >
                      {copiedField === 'orgCode' ? (
                        <>
                          <Check className="h-4 w-4" />
                          <span>Copied!</span>
                        </>
                      ) : (
                        <>
                          <Copy className="h-4 w-4" />
                          <span>Copy</span>
                        </>
                      )}
                    </button>
                  </div>
                </div>
                
                <p className="text-sm text-gray-600 dark:text-gray-400">
                  Team members need this code to join your organization
                </p>
              </div>

              {/* Passkey Card */}
              <div className="bg-white dark:bg-gray-800 rounded-2xl shadow-sm border border-gray-200 dark:border-gray-700 p-6 hover:shadow-md transition-shadow">
                <div className="flex items-center justify-between mb-4">
                  <div className="flex items-center space-x-3">
                    <div className="w-12 h-12 bg-teal-100 dark:bg-teal-900/20 rounded-lg flex items-center justify-center">
                      <Shield className="h-6 w-6 text-teal-600 dark:text-teal-400" />
                    </div>
                    <div>
                      <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
                        Organization Passkey
                      </h3>
                      <p className="text-sm text-red-500 dark:text-red-400 font-medium">
                        Keep this confidential
                      </p>
                    </div>
                  </div>
                </div>
                
                <div className="bg-gray-50 dark:bg-gray-700 rounded-lg p-4 mb-4">
                  <div className="flex items-center justify-between">
                    <code className="text-2xl font-mono font-bold text-gray-900 dark:text-white tracking-wider">
                      {passkey}
                    </code>
                    <button
                      onClick={() => copyToClipboard(passkey, 'passkey')}
                      className="flex items-center space-x-2 px-3 py-2 bg-teal-600 hover:bg-teal-700 text-white text-sm font-medium rounded-lg transition-colors"
                    >
                      {copiedField === 'passkey' ? (
                        <>
                          <Check className="h-4 w-4" />
                          <span>Copied!</span>
                        </>
                      ) : (
                        <>
                          <Copy className="h-4 w-4" />
                          <span>Copy</span>
                        </>
                      )}
                    </button>
                  </div>
                </div>
                
                <p className="text-sm text-gray-600 dark:text-gray-400">
                  Required along with the organization code for secure access
                </p>
              </div>
            </div>

            {/* Onboarding Instructions */}
            <div className="bg-gradient-to-r from-blue-50 to-teal-50 dark:from-blue-900/10 dark:to-teal-900/10 rounded-2xl p-6 mb-8 border border-blue-200 dark:border-blue-800">
              <h3 className="text-xl font-semibold text-gray-900 dark:text-white mb-4 flex items-center space-x-2">
                <Users className="h-6 w-6 text-blue-600 dark:text-blue-400" />
                <span>Team Onboarding</span>
              </h3>
              
              <div className="space-y-3">
                <p className="text-gray-700 dark:text-gray-300">
                  <strong>Share both credentials</strong> with your Managers and Employees so they can securely join your organization:
                </p>
                
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="bg-white dark:bg-gray-800 rounded-lg p-4 border border-gray-200 dark:border-gray-700">
                    <p className="text-sm font-medium text-gray-900 dark:text-white mb-1">
                      1. Organization Code
                    </p>
                    <code className="text-sm text-blue-600 dark:text-blue-400 font-mono">
                      {orgCode}
                    </code>
                  </div>
                  
                  <div className="bg-white dark:bg-gray-800 rounded-lg p-4 border border-gray-200 dark:border-gray-700">
                    <p className="text-sm font-medium text-gray-900 dark:text-white mb-1">
                      2. Organization Passkey
                    </p>
                    <code className="text-sm text-teal-600 dark:text-teal-400 font-mono">
                      {passkey}
                    </code>
                  </div>
                </div>
                
                <div className="bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg p-3 mt-4">
                  <p className="text-sm text-yellow-800 dark:text-yellow-200">
                    <strong>Security Reminder:</strong> Keep the passkey confidential and only share it with trusted team members.
                  </p>
                </div>
              </div>
            </div>

            {/* Future Functionality */}
            <div className="bg-white dark:bg-gray-800 rounded-2xl shadow-sm border border-gray-200 dark:border-gray-700 p-6">
              <h3 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">
                Quick Actions
              </h3>
              
              <div className="space-y-4">
                <button
                  disabled
                  className="w-full sm:w-auto flex items-center justify-center space-x-2 px-6 py-3 bg-gray-100 dark:bg-gray-700 text-gray-400 dark:text-gray-500 font-medium rounded-lg cursor-not-allowed relative group"
                >
                  <Users className="h-5 w-5" />
                  <span>+ Add New Employee</span>
                  
                  {/* Tooltip */}
                  <div className="absolute bottom-full left-1/2 transform -translate-x-1/2 mb-2 px-3 py-2 bg-gray-900 dark:bg-gray-700 text-white text-sm rounded-lg opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap">
                    Coming soon - Direct employee invitation system
                  </div>
                </button>
                
                <p className="text-sm text-gray-500 dark:text-gray-400">
                  More management features coming soon. For now, share the credentials above with your team members.
                </p>
              </div>
            </div>
          </>
        )}
      </div>
    </AdminLayout>
  );
};

export default DashboardPage;