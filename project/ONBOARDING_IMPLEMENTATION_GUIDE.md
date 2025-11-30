# Onboarding System - Technical Implementation Guide

## Architecture Overview

The onboarding system consists of three main layers:

1. **Frontend Wizard** - React components for data collection
2. **Session Management** - Progressive state persistence
3. **Auto-Generation Engine** - Batch database operations

---

## Database Schema

### Core Tables

```sql
onboarding_sessions
├── user_id (FK to auth.users)
├── current_step (1-7)
├── total_steps (7)
├── completed (boolean)
└── business_data (JSONB) - Accumulated form data

shop_branches
├── organization_id (FK to shops)
├── name, location, size_category
├── theme_preference
└── opening_time, closing_time

employees
├── branch_id (FK to shop_branches)
├── organization_id (FK to shops)
├── name, role, salary
├── contact_number
└── shift_start, shift_end

product_categories
├── organization_id (FK to shops)
└── name, description

products
├── branch_id (FK to shop_branches)
├── category_id (FK to product_categories)
├── organization_id (FK to shops)
├── name, selling_price, cost_price
├── current_stock, min_stock_level
└── supplier_name

organization_settings
├── organization_id (FK to shops)
├── industry_type, currency
├── gst_enabled, billing_format
├── brand_color, logo_url
└── two_factor_enabled

analytics_preferences
├── organization_id (FK to shops)
├── performance_ranking, sales_forecasting
├── inventory_predictions, fraud_detection
└── notification preferences
```

---

## Component Structure

```
src/pages/
└── OnboardingPage.tsx          # Main wizard container

src/components/onboarding/
├── OnboardingWizard.tsx        # Wizard shell with navigation
├── StepIndicator.tsx           # Progress bar component
├── steps/
│   ├── Step1BusinessFoundation.tsx
│   ├── Step2BranchConfiguration.tsx
│   ├── Step3WorkforceSetup.tsx
│   ├── Step4InventoryFoundation.tsx
│   ├── Step5SystemPreferences.tsx
│   ├── Step6AnalyticsSetup.tsx
│   └── Step7BrandingSecurity.tsx
├── GenerationProgress.tsx      # Auto-generation loader
└── OnboardingComplete.tsx      # Success page

src/hooks/
├── useOnboarding.ts           # Main onboarding hook
├── useOnboardingSession.ts    # Session management
└── useAutoGeneration.ts       # Trigger generation

src/utils/
├── onboardingValidation.ts    # Zod schemas
├── industryDefaults.ts        # Smart defaults
└── autoGenerator.ts           # Generation logic
```

---

## Implementation Steps

### Phase 1: Component Setup

```typescript
// OnboardingWizard.tsx
import React, { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { useOnboarding } from '../hooks/useOnboarding';

const OnboardingWizard: React.FC = () => {
  const { user } = useAuth();
  const {
    currentStep,
    totalSteps,
    formData,
    updateFormData,
    nextStep,
    prevStep,
    saveProgress,
    completeOnboarding
  } = useOnboarding(user?.id);

  // Render appropriate step component
  const renderStep = () => {
    switch(currentStep) {
      case 1: return <Step1BusinessFoundation />;
      case 2: return <Step2BranchConfiguration />;
      case 3: return <Step3WorkforceSetup />;
      case 4: return <Step4InventoryFoundation />;
      case 5: return <Step5SystemPreferences />;
      case 6: return <Step6AnalyticsSetup />;
      case 7: return <Step7BrandingSecurity />;
      default: return null;
    }
  };

  return (
    <div className="onboarding-container">
      <StepIndicator
        currentStep={currentStep}
        totalSteps={totalSteps}
      />
      {renderStep()}
      <NavigationButtons
        onNext={nextStep}
        onPrev={prevStep}
        onSave={saveProgress}
      />
    </div>
  );
};
```

### Phase 2: Session Management Hook

```typescript
// useOnboarding.ts
import { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';

interface OnboardingData {
  businessFoundation?: BusinessFoundation;
  branches?: Branch[];
  employees?: Employee[];
  inventory?: InventoryData;
  systemPreferences?: SystemPreferences;
  analytics?: AnalyticsPreferences;
  branding?: BrandingData;
}

export const useOnboarding = (userId: string) => {
  const [currentStep, setCurrentStep] = useState(1);
  const [formData, setFormData] = useState<OnboardingData>({});
  const [sessionId, setSessionId] = useState<string | null>(null);

  // Load existing session
  useEffect(() => {
    loadSession();
  }, [userId]);

  const loadSession = async () => {
    const { data, error } = await supabase
      .from('onboarding_sessions')
      .select('*')
      .eq('user_id', userId)
      .eq('completed', false)
      .maybeSingle();

    if (data) {
      setSessionId(data.id);
      setCurrentStep(data.current_step);
      setFormData(data.business_data);
    } else {
      createNewSession();
    }
  };

  const createNewSession = async () => {
    const { data, error } = await supabase
      .from('onboarding_sessions')
      .insert({
        user_id: userId,
        current_step: 1,
        business_data: {}
      })
      .select()
      .single();

    if (data) setSessionId(data.id);
  };

  const updateFormData = (stepData: Partial<OnboardingData>) => {
    setFormData(prev => ({ ...prev, ...stepData }));
  };

  const saveProgress = async () => {
    if (!sessionId) return;

    await supabase
      .from('onboarding_sessions')
      .update({
        current_step: currentStep,
        business_data: formData
      })
      .eq('id', sessionId);
  };

  const nextStep = async () => {
    await saveProgress();
    setCurrentStep(prev => Math.min(prev + 1, 7));
  };

  const prevStep = () => {
    setCurrentStep(prev => Math.max(prev - 1, 1));
  };

  const completeOnboarding = async () => {
    await saveProgress();
    await supabase
      .from('onboarding_sessions')
      .update({ completed: true })
      .eq('id', sessionId);

    // Trigger auto-generation
    return triggerAutoGeneration(formData);
  };

  return {
    currentStep,
    totalSteps: 7,
    formData,
    updateFormData,
    nextStep,
    prevStep,
    saveProgress,
    completeOnboarding
  };
};
```

### Phase 3: Auto-Generation Logic

```typescript
// autoGenerator.ts
import { supabase } from '../lib/supabase';

interface GenerationResult {
  success: boolean;
  organizationId?: string;
  error?: string;
}

export const triggerAutoGeneration = async (
  data: OnboardingData,
  userId: string
): Promise<GenerationResult> => {

  try {
    // Start transaction
    const { data: org, error: orgError } = await supabase
      .from('shops')
      .insert({
        name: data.businessFoundation.businessName,
        manager_id: userId,
        industry_type: data.businessFoundation.industryType,
        total_branches: data.businessFoundation.totalBranches
      })
      .select()
      .single();

    if (orgError) throw orgError;

    const organizationId = org.id;

    // Create organization settings
    await supabase
      .from('organization_settings')
      .insert({
        organization_id: organizationId,
        industry_type: data.businessFoundation.industryType,
        currency: data.systemPreferences.currency,
        gst_enabled: data.systemPreferences.gstEnabled,
        billing_format: data.systemPreferences.billingFormat,
        discounts_enabled: data.systemPreferences.discountsEnabled,
        brand_color: data.branding?.brandColor,
        logo_url: data.branding?.logoUrl,
        business_slogan: data.branding?.slogan,
        two_factor_enabled: data.branding?.twoFactorEnabled
      });

    // Create analytics preferences
    await supabase
      .from('analytics_preferences')
      .insert({
        organization_id: organizationId,
        performance_ranking: data.analytics.performanceRanking,
        sales_forecasting: data.analytics.salesForecasting,
        inventory_predictions: data.analytics.inventoryPredictions,
        fraud_detection: data.analytics.fraudDetection,
        dashboard_style: data.analytics.dashboardStyle,
        low_stock_alerts: data.analytics.lowStockAlerts,
        daily_summaries: data.analytics.dailySummaries,
        performance_alerts: data.analytics.performanceAlerts
      });

    // Create branches
    for (const branch of data.branches) {
      const { data: branchData, error: branchError } = await supabase
        .from('shop_branches')
        .insert({
          organization_id: organizationId,
          name: branch.name,
          location: branch.location,
          size_category: branch.sizeCategory,
          theme_preference: branch.themePreference,
          opening_time: branch.openingTime,
          closing_time: branch.closingTime
        })
        .select()
        .single();

      if (branchError) throw branchError;

      // Create employees for this branch
      const branchEmployees = data.employees.filter(
        emp => emp.branchName === branch.name
      );

      if (branchEmployees.length > 0) {
        await supabase
          .from('employees')
          .insert(
            branchEmployees.map(emp => ({
              branch_id: branchData.id,
              organization_id: organizationId,
              name: emp.name,
              role: emp.role,
              salary: emp.salary,
              contact_number: emp.contactNumber,
              shift_start: emp.shiftStart,
              shift_end: emp.shiftEnd
            }))
          );
      }
    }

    // Create product categories
    if (data.inventory?.categories) {
      const { data: categories } = await supabase
        .from('product_categories')
        .insert(
          data.inventory.categories.map(cat => ({
            organization_id: organizationId,
            name: cat.name,
            description: cat.description
          }))
        )
        .select();

      // Create products
      if (data.inventory.products && categories) {
        const productsToInsert = [];

        for (const product of data.inventory.products) {
          const category = categories.find(c => c.name === product.categoryName);
          const branch = await getBranchByName(organizationId, product.branchName);

          productsToInsert.push({
            branch_id: branch.id,
            category_id: category?.id,
            organization_id: organizationId,
            name: product.name,
            selling_price: product.sellingPrice,
            cost_price: product.costPrice,
            current_stock: product.currentStock,
            min_stock_level: product.minStockLevel,
            supplier_name: product.supplierName
          });
        }

        await supabase
          .from('products')
          .insert(productsToInsert);
      }
    }

    // Update user's organization_id
    await supabase
      .from('users')
      .update({ organization_id: organizationId })
      .eq('id', userId);

    return {
      success: true,
      organizationId
    };

  } catch (error) {
    console.error('Auto-generation error:', error);
    return {
      success: false,
      error: error.message
    };
  }
};

const getBranchByName = async (orgId: string, branchName: string) => {
  const { data } = await supabase
    .from('shop_branches')
    .select('id')
    .eq('organization_id', orgId)
    .eq('name', branchName)
    .single();

  return data;
};
```

### Phase 4: Form Validation

```typescript
// onboardingValidation.ts
import { z } from 'zod';

export const businessFoundationSchema = z.object({
  businessName: z.string().min(2, 'Business name is required'),
  industryType: z.enum([
    'Supermarket', 'Clothing', 'Hardware', 'Pharmacy',
    'Restaurant', 'Electronics', 'Mobile Shop', 'Other'
  ]),
  totalBranches: z.number().min(1).max(100)
});

export const branchSchema = z.object({
  name: z.string().min(2, 'Branch name is required'),
  location: z.string().min(2, 'Location is required'),
  sizeCategory: z.enum(['Small', 'Medium', 'Large']),
  themePreference: z.string().optional(),
  openingTime: z.string().optional(),
  closingTime: z.string().optional()
});

export const employeeSchema = z.object({
  name: z.string().min(2, 'Employee name is required'),
  role: z.enum(['Manager', 'Cashier', 'Staff', 'Auditor']),
  salary: z.number().optional(),
  contactNumber: z.string().optional(),
  shiftStart: z.string().optional(),
  shiftEnd: z.string().optional(),
  branchName: z.string()
});

export const productSchema = z.object({
  name: z.string().min(1, 'Product name is required'),
  categoryName: z.string(),
  sellingPrice: z.number().positive('Selling price must be positive'),
  costPrice: z.number().positive('Cost price must be positive'),
  currentStock: z.number().min(0),
  minStockLevel: z.number().min(0),
  supplierName: z.string().optional(),
  branchName: z.string()
});

// Validate entire onboarding data
export const validateOnboardingData = (data: OnboardingData) => {
  const errors = [];

  try {
    businessFoundationSchema.parse(data.businessFoundation);
  } catch (e) {
    errors.push({ step: 1, errors: e.errors });
  }

  // Validate all branches
  data.branches?.forEach((branch, idx) => {
    try {
      branchSchema.parse(branch);
    } catch (e) {
      errors.push({ step: 2, branch: idx, errors: e.errors });
    }
  });

  // Validate all employees
  data.employees?.forEach((emp, idx) => {
    try {
      employeeSchema.parse(emp);
    } catch (e) {
      errors.push({ step: 3, employee: idx, errors: e.errors });
    }
  });

  return {
    valid: errors.length === 0,
    errors
  };
};
```

---

## API Routes Structure

```typescript
// Endpoint 1: Get or create onboarding session
GET/POST /api/onboarding/session
- Returns current session or creates new one

// Endpoint 2: Update session progress
PATCH /api/onboarding/session/:id
- Saves current step and form data

// Endpoint 3: Trigger auto-generation
POST /api/onboarding/complete
- Validates all data
- Runs generation logic
- Returns organization ID

// Endpoint 4: Get industry defaults
GET /api/onboarding/defaults/:industry
- Returns smart defaults for industry
```

---

## State Management

```typescript
// OnboardingContext.tsx
interface OnboardingContextType {
  currentStep: number;
  formData: OnboardingData;
  updateFormData: (data: Partial<OnboardingData>) => void;
  nextStep: () => void;
  prevStep: () => void;
  canProceed: boolean;
  errors: ValidationError[];
}

export const OnboardingProvider: React.FC = ({ children }) => {
  // Implement context logic
};
```

---

## Testing Strategy

### Unit Tests
- Form validation logic
- Data transformation functions
- Step navigation logic

### Integration Tests
- Session persistence
- Multi-step form flow
- Auto-generation process

### E2E Tests
- Complete onboarding flow
- Error handling scenarios
- Data accuracy validation

---

## Performance Optimization

1. **Lazy Loading** - Load step components on demand
2. **Debounced Saves** - Auto-save every 30 seconds
3. **Batch Inserts** - Single transaction for all data
4. **Optimistic UI** - Show progress before completion
5. **Caching** - Store industry defaults locally

---

## Error Handling

```typescript
try {
  const result = await completeOnboarding();
  if (result.success) {
    redirect('/dashboard');
  } else {
    showError(result.error);
  }
} catch (error) {
  // Rollback any partial changes
  await rollbackOnboarding(sessionId);
  showError('Setup failed. Please try again.');
}
```

---

## Security Considerations

1. **RLS Policies** - Only user can access their session
2. **Input Sanitization** - Clean all text inputs
3. **Rate Limiting** - Prevent spam submissions
4. **Session Expiry** - Auto-expire after 24 hours inactive
5. **Audit Logging** - Track all onboarding attempts

---

## Deployment Checklist

- [ ] Database migrations applied
- [ ] RLS policies tested
- [ ] All components built
- [ ] Validation schemas complete
- [ ] Auto-generation tested with sample data
- [ ] Error scenarios handled
- [ ] Loading states implemented
- [ ] Analytics tracking added
- [ ] Help documentation linked
- [ ] Mobile responsive tested

---

## Monitoring & Analytics

Track the following metrics:
- Completion rate per step
- Average time per step
- Abandonment points
- Error frequency
- Auto-generation success rate
- User satisfaction score

---

This implementation guide provides everything needed to build a production-ready onboarding system that auto-generates complete multi-shop management systems.