# Onboarding System - Data Flow & Collection Map

## Complete Data Collection Reference

This document maps exactly what data is collected at each step and how it's stored in the database.

---

## Step 1: Business Foundation

### Data Collected
```typescript
{
  businessName: string;        // "Mobile Hub"
  industryType: string;        // "Electronics Shop"
  totalBranches: number;       // 3
}
```

### Database Impact
```sql
-- Updates: shops table
INSERT INTO shops (
  name,                        -- businessName
  manager_id,                  -- current user ID
  industry_type,               -- industryType
  total_branches,              -- totalBranches
  org_code,                    -- auto-generated
  passkey                      -- auto-generated
)
```

### Smart Defaults Generated
- org_code: "ORG-A1B2C3D4"
- passkey: "PASS-X1Y2Z3A4B5C6"
- manager_id: current authenticated user

---

## Step 2: Branch Configuration

### Data Collected (Per Branch)
```typescript
{
  branches: [
    {
      name: string;            // "Mobile Hub Andheri"
      location: string;        // "Andheri West, Mumbai"
      sizeCategory: string;    // "Medium"
      themePreference: string; // "Light"
      openingTime: string;     // "10:00"
      closingTime: string;     // "22:00"
    }
  ]
}
```

### Database Impact
```sql
-- Creates: shop_branches records (one per branch)
INSERT INTO shop_branches (
  organization_id,             -- FK to shops
  name,                        -- branch.name
  location,                    -- branch.location
  size_category,               -- branch.sizeCategory
  theme_preference,            -- branch.themePreference
  opening_time,                -- branch.openingTime
  closing_time,                -- branch.closingTime
  is_active                    -- default: true
)
```

### Multiplier Effect
For 3 branches → 3 records in shop_branches table

---

## Step 3: Workforce Setup

### Data Collected (Per Branch, Per Employee)
```typescript
{
  employees: [
    {
      name: string;            // "Ramesh Kumar"
      role: string;            // "Manager"
      salary: number;          // 35000
      contactNumber: string;   // "+91-9876543210"
      shiftStart: string;      // "10:00"
      shiftEnd: string;        // "18:00"
      branchName: string;      // "Mobile Hub Andheri"
    }
  ]
}
```

### Database Impact
```sql
-- Creates: employees records
INSERT INTO employees (
  branch_id,                   -- FK from branch name
  organization_id,             -- FK to shops
  name,                        -- employee.name
  role,                        -- employee.role
  salary,                      -- employee.salary
  contact_number,              -- employee.contactNumber
  shift_start,                 -- employee.shiftStart
  shift_end,                   -- employee.shiftEnd
  is_active                    -- default: true
)
```

### Multiplier Effect
For 12 employees across 3 branches → 12 records in employees table

### Role Mapping
- Manager: Full branch access
- Cashier: POS and billing access
- Staff: Inventory access
- Auditor: Read-only analytics access

---

## Step 4: Inventory Foundation

### Phase A: Categories
```typescript
{
  categories: [
    {
      name: string;            // "iPhone Accessories"
      description: string;     // "Cases, chargers for iPhone"
    }
  ]
}
```

### Database Impact - Categories
```sql
-- Creates: product_categories records
INSERT INTO product_categories (
  organization_id,             -- FK to shops
  name,                        -- category.name
  description                  -- category.description
)
```

### Phase B: Products
```typescript
{
  products: [
    {
      name: string;            // "iPhone 15 Case"
      categoryName: string;    // "iPhone Accessories"
      branchName: string;      // "Mobile Hub Andheri"
      sellingPrice: number;    // 499
      costPrice: number;       // 299
      currentStock: number;    // 50
      minStockLevel: number;   // 10
      supplierName: string;    // "XYZ Distributors"
    }
  ]
}
```

### Database Impact - Products
```sql
-- Creates: products records
INSERT INTO products (
  branch_id,                   -- FK from branch name
  category_id,                 -- FK from category name
  organization_id,             -- FK to shops
  name,                        -- product.name
  selling_price,               -- product.sellingPrice
  cost_price,                  -- product.costPrice
  current_stock,               -- product.currentStock
  min_stock_level,             -- product.minStockLevel
  supplier_name,               -- product.supplierName
  is_active                    -- default: true
)
```

### Multiplier Effect
- 6 categories → 6 records in product_categories
- 10 products per branch × 3 branches → 30 records in products

---

## Step 5: System Preferences

### Data Collected
```typescript
{
  systemPreferences: {
    currency: string;          // "INR"
    gstEnabled: boolean;       // true
    gstPercentage: number;     // 18
    billingFormat: string;     // "Detailed"
    discountsEnabled: boolean; // true
    offersEnabled: boolean;    // true
  }
}
```

### Database Impact
```sql
-- Creates: organization_settings record (one per org)
INSERT INTO organization_settings (
  organization_id,             -- FK to shops
  industry_type,               -- from Step 1
  currency,                    -- preferences.currency
  gst_enabled,                 -- preferences.gstEnabled
  billing_format,              -- preferences.billingFormat
  discounts_enabled,           -- preferences.discountsEnabled
  brand_color,                 -- from Step 7 (default: #3B82F6)
  two_factor_enabled           -- from Step 7 (default: false)
)
```

### Single Record
Creates 1 record in organization_settings table

---

## Step 6: Analytics Setup

### Data Collected
```typescript
{
  analytics: {
    performanceRanking: boolean;   // true
    salesForecasting: boolean;     // true
    inventoryPredictions: boolean; // true
    fraudDetection: boolean;       // true
    dashboardStyle: string;        // "Modern"
    lowStockAlerts: boolean;       // true
    dailySummaries: boolean;       // true
    performanceAlerts: boolean;    // true
  }
}
```

### Database Impact
```sql
-- Creates: analytics_preferences record (one per org)
INSERT INTO analytics_preferences (
  organization_id,             -- FK to shops
  performance_ranking,         -- analytics.performanceRanking
  sales_forecasting,           -- analytics.salesForecasting
  inventory_predictions,       -- analytics.inventoryPredictions
  fraud_detection,             -- analytics.fraudDetection
  dashboard_style,             -- analytics.dashboardStyle
  low_stock_alerts,            -- analytics.lowStockAlerts
  daily_summaries,             -- analytics.dailySummaries
  performance_alerts           -- analytics.performanceAlerts
)
```

### Single Record
Creates 1 record in analytics_preferences table

---

## Step 7: Branding & Security

### Data Collected
```typescript
{
  branding: {
    logoUrl: string;           // "https://storage/logo.png"
    brandColor: string;        // "#FF5722"
    businessSlogan: string;    // "Your Mobile Partner"
    twoFactorEnabled: boolean; // true
  }
}
```

### Database Impact
```sql
-- Updates: organization_settings record
UPDATE organization_settings SET
  brand_color = branding.brandColor,
  logo_url = branding.logoUrl,
  business_slogan = branding.businessSlogan,
  two_factor_enabled = branding.twoFactorEnabled
WHERE organization_id = current_org_id;
```

### Updates Existing Record
Updates the organization_settings record created in Step 5

---

## Complete Database Footprint Example

### Scenario: 3 branches, 12 employees, 60 products

```
Table                     | Records Created
─────────────────────────────────────────
shops                     | 1
users                     | 1 (updated)
shop_branches             | 3
employees                 | 12
product_categories        | 6
products                  | 60
organization_settings     | 1
analytics_preferences     | 1
onboarding_sessions       | 1 (marked complete)
─────────────────────────────────────────
TOTAL                     | 85 records
```

---

## Data Flow Sequence

### During Onboarding
```
Step 1 → Save to onboarding_sessions.business_data
Step 2 → Save to onboarding_sessions.business_data
Step 3 → Save to onboarding_sessions.business_data
Step 4 → Save to onboarding_sessions.business_data
Step 5 → Save to onboarding_sessions.business_data
Step 6 → Save to onboarding_sessions.business_data
Step 7 → Save to onboarding_sessions.business_data
```

### On Completion
```
1. Validate all data
2. Begin transaction
3. Create shops record
4. Create organization_settings
5. Create analytics_preferences
6. Create all shop_branches
7. Create all employees
8. Create all product_categories
9. Create all products
10. Update user's organization_id
11. Mark onboarding_session complete
12. Commit transaction
13. Redirect to dashboard
```

---

## Data Validation Rules

### Business Foundation
- businessName: 2-100 characters
- industryType: Must be from predefined list
- totalBranches: 1-100

### Branch Configuration
- name: 2-100 characters, unique per organization
- location: 2-200 characters
- sizeCategory: Small | Medium | Large
- times: Valid 24-hour format

### Workforce Setup
- name: 2-100 characters
- role: Manager | Cashier | Staff | Auditor
- salary: Optional, >= 0
- contactNumber: Valid phone format for managers

### Inventory Foundation
- categoryName: 2-50 characters
- productName: 1-200 characters
- sellingPrice: > 0
- costPrice: > 0, < sellingPrice
- stock: >= 0
- minStockLevel: >= 0

### System Preferences
- currency: ISO currency code
- billingFormat: Simple | Detailed

### Analytics Setup
- All fields: boolean or string enum

### Branding
- logoUrl: Valid URL or empty
- brandColor: Valid hex color
- slogan: 0-100 characters

---

## Error Handling

### Validation Errors
- Show inline errors immediately
- Prevent proceeding to next step
- Highlight invalid fields
- Provide correction hints

### Database Errors
- Rollback entire transaction
- Show user-friendly error message
- Log detailed error for debugging
- Allow retry with same data

### Network Errors
- Auto-save form data locally
- Show connection status
- Retry failed requests
- Resume from last saved state

---

## Data Relationships

```
shops (1)
  ├─→ users (1:N)
  ├─→ shop_branches (1:N)
  │    └─→ employees (1:N)
  │    └─→ products (1:N)
  ├─→ product_categories (1:N)
  │    └─→ products (1:N)
  ├─→ organization_settings (1:1)
  └─→ analytics_preferences (1:1)
```

---

## Session Storage Structure

```json
{
  "id": "uuid",
  "user_id": "uuid",
  "current_step": 3,
  "total_steps": 7,
  "completed": false,
  "business_data": {
    "businessFoundation": { ... },
    "branches": [ ... ],
    "employees": [ ... ],
    "inventory": { ... },
    "systemPreferences": { ... },
    "analytics": { ... },
    "branding": { ... }
  },
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

---

## Auto-Save Behavior

**Frequency:** Every 30 seconds or on step change
**Storage:** onboarding_sessions.business_data (JSONB)
**Resume:** Automatic on page reload
**Expiry:** 7 days of inactivity

---

## Minimum Required Data

### To Proceed to Auto-Generation
```
✅ businessName
✅ industryType
✅ totalBranches
✅ At least 1 branch configured
✅ At least 1 employee per branch
✅ Currency preference
✅ Billing format
```

### Optional Data
- Product categories and products
- Employee salaries and shifts
- Branding elements
- Specific analytics preferences (uses defaults)

---

## Data Transformation Examples

### Branch Names → Database IDs
```typescript
// Input: "Mobile Hub Andheri"
// Process: Create branch → Get branch.id
// Use: Link employees and products to branch.id
```

### Category Names → Database IDs
```typescript
// Input: "iPhone Accessories"
// Process: Create category → Get category.id
// Use: Link products to category.id
```

### Role Names → Permissions
```typescript
// Input: "Manager"
// Process: Create employee with role
// Use: Grant branch-level admin access
```

---

This data flow map ensures every piece of information collected has a clear purpose and destination in the system, enabling complete auto-generation of the multi-shop management platform.