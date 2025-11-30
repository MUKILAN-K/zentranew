# Zentra Onboarding Flow Design

## Overview
This document outlines the intelligent, progressive onboarding flow that collects minimum required information to auto-generate a complete multi-shop management system.

## Design Principles

1. **Progressive Disclosure** - Present information in logical steps, never overwhelming users
2. **Smart Defaults** - Provide intelligent suggestions based on industry and context
3. **Clear Purpose** - Explain why each piece of information is needed
4. **Visual Progress** - Show completion percentage and step indicators
5. **Data Validation** - Real-time validation to ensure accuracy
6. **Skip Options** - Allow users to skip optional fields and complete later

## Onboarding Steps (7 Total)

### Step 1: Business Foundation (Required)
**Purpose:** Establish business identity and scale for system personalization

**Fields:**
- Business Name (text, required)
- Industry Type (dropdown, required)
  - Options: Supermarket, Clothing Store, Hardware Store, Pharmacy, Restaurant, Electronics Shop, Mobile Shop, Bakery, Stationery, Other
- Total Number of Branches (number, required, min: 1, max: 100)

**Why We Need This:**
- Business name personalizes your dashboard and invoices
- Industry type enables smart product suggestions and analytics templates
- Branch count determines system architecture and pricing tier

**Smart Features:**
- Industry icons preview
- Estimated setup time based on branch count
- Industry-specific feature highlights

---

### Step 2: Branch Configuration (Per Branch)
**Purpose:** Create individual shop dashboards with location-specific settings

**For Each Branch:**
- Shop Name (text, required) - e.g., "Downtown Store", "Airport Mall Branch"
- Location (text, required) - City/Area
- Size Category (radio, required)
  - Small (1-500 sq ft) - Basic inventory, 1-3 staff
  - Medium (500-2000 sq ft) - Standard inventory, 4-10 staff
  - Large (2000+ sq ft) - Extensive inventory, 10+ staff
- Theme Preference (color picker, optional)
  - Light, Dark, or Custom brand color
- Operating Hours (time range, optional)
  - Default: 9 AM - 9 PM

**Why We Need This:**
- Shop names help distinguish locations in reports
- Location enables regional analytics and logistics
- Size category optimizes inventory suggestions and staff recommendations
- Theme creates branded experience for each location
- Hours enable shift planning and customer service scheduling

**Smart Features:**
- Duplicate branch details for similar locations
- Map preview showing all branch locations
- Auto-suggest operating hours based on industry

---

### Step 3: Workforce Setup (Per Branch)
**Purpose:** Enable employee management, payroll tracking, and access control

**Global Input:**
- Total Employees Across All Branches (number, optional)
  - Used for bulk allocation

**Per Branch:**
- Number of Employees (number, required, min: 1)
- Add Employee Details (repeatable form):
  - Name (text, required)
  - Role (dropdown, required)
    - Manager, Cashier, Staff, Auditor
  - Monthly Salary (number, optional)
  - Contact Number (text, required for managers)
  - Shift Timing (optional)
    - Morning (6 AM - 2 PM)
    - Day (9 AM - 6 PM)
    - Evening (2 PM - 10 PM)
    - Night (10 PM - 6 AM)
    - Custom

**Why We Need This:**
- Employee count determines dashboard complexity
- Roles define access permissions automatically
- Salary enables payroll tracking and cost analysis
- Contact info required for manager notifications
- Shifts optimize staff scheduling and labor cost tracking

**Smart Features:**
- Quick add multiple employees with same role
- Import from spreadsheet option
- Role-based salary suggestions by industry
- Auto-assign one manager per branch requirement

---

### Step 4: Inventory Foundation (Per Branch)
**Purpose:** Set up product catalog and stock management system

**Category Setup:**
- Number of Product Categories (number, required, min: 1, max: 50)
- Category Names (repeatable, required)
  - Industry-specific suggestions shown

**Product Entry Options:**
1. **Quick Start** - Add 5-10 key products now
2. **Bulk Import** - Upload spreadsheet (template provided)
3. **Skip & Add Later** - Set up inventory from dashboard

**For Quick Start Products:**
- Product Name (text, required)
- Category (dropdown, from categories created)
- Selling Price (currency, required)
- Cost Price (currency, required)
- Current Stock (number, required)
- Minimum Stock Level (number, required) - For alerts
- Supplier Name (text, optional)

**Why We Need This:**
- Categories organize inventory and enable analytics by type
- Key products establish pricing models and margin analysis
- Stock levels activate low-stock alerts immediately
- Supplier info enables reorder automation
- Cost vs selling price enables profit margin tracking

**Smart Features:**
- Industry-specific category templates
- Common product suggestions by category
- Margin calculator (shows profit percentage)
- Bulk stock entry for similar items
- Barcode scanning ready notification

---

### Step 5: System Preferences (Global)
**Purpose:** Configure billing, taxation, and business operations

**Currency & Taxation:**
- Currency (dropdown, required)
  - Default: INR (Indian Rupee)
  - Options: INR, USD, EUR, GBP, etc.
- GST/Tax System (toggle, required)
  - Enable GST (default: Yes for India)
  - Tax percentage (auto-filled by region)

**Billing Configuration:**
- Invoice Format (radio, required)
  - Simple - Basic itemized bill
  - Detailed - With GST breakdown, terms & conditions
- Enable Discounts (toggle, default: Yes)
- Enable Offers/Promotions (toggle, default: Yes)

**Why We Need This:**
- Currency ensures correct pricing display
- GST compliance required for legal invoicing
- Billing format affects customer experience
- Discount capabilities enable sales strategies

**Smart Features:**
- Auto-detect region and suggest tax settings
- Preview invoice templates
- Compliance checklist by country

---

### Step 6: Intelligence & Analytics Setup
**Purpose:** Configure AI insights and notification preferences

**Desired Insights (Multi-select):**
- Shop Performance Ranking (default: enabled)
  - Compare sales across branches
- Sales Forecasting (default: enabled)
  - Predict future revenue with 95% accuracy
- Inventory Predictions (default: enabled)
  - Smart restock suggestions
- Fraud Detection (default: enabled)
  - Unusual transaction alerts

**Dashboard Style:**
- Modern (colorful charts, animations)
- Classic (clean tables, simple graphs)
- Minimal (key metrics only)

**Notification Preferences (Toggles):**
- Low Stock Alerts (default: enabled)
  - Email + In-app when stock hits minimum level
- Daily Summaries (default: enabled)
  - Morning email with yesterday's performance
- Performance Alerts (default: enabled)
  - Significant changes in sales or traffic

**Why We Need This:**
- Insights selection activates relevant AI models
- Dashboard style personalizes user experience
- Notifications prevent stockouts and keep owners informed
- Alert preferences prevent notification fatigue

**Smart Features:**
- Industry-recommended insight packages
- Sample alert previews
- Notification frequency options (real-time, daily digest, weekly)

---

### Step 7: Branding & Security (Optional)
**Purpose:** Add final touches for professional appearance and security

**Branding (All Optional):**
- Business Logo (image upload, max 2MB)
  - Used on invoices, reports, customer-facing displays
- Primary Brand Color (color picker)
  - Default: Blue (#3B82F6)
  - Applied across dashboards and invoices
- Business Slogan (text, max 100 chars)
  - Appears on invoices and promotional materials

**Security Configuration:**
- Two-Factor Authentication (toggle, default: disabled)
  - Recommended for multi-branch operations
- Device Access Restrictions (optional)
  - Limit dashboard access to registered devices

**Access Control Assignment:**
- Review employee roles and permissions
- Assign branch-specific access for managers
- Set up owner/admin dashboard access

**Why We Need This:**
- Logo creates professional brand identity
- Brand colors ensure consistent visual identity
- 2FA protects against unauthorized access
- Access control maintains data security across branches

**Smart Features:**
- Logo auto-resize and format optimization
- Color scheme preview on sample invoice
- Security score based on configurations
- Permission matrix visual guide

---

## Post-Onboarding Auto-Generation

Once the user completes Step 7 and clicks "Launch My System," the following happens automatically:

### Immediate Actions (< 5 seconds)
1. Create organization in database
2. Generate unique org_code and passkey
3. Create all branch records
4. Set up employee accounts
5. Initialize product categories and inventory
6. Configure organization settings
7. Set analytics preferences
8. Generate first dashboard snapshot

### Background Processing (< 30 seconds)
1. Create role-based access controls
2. Generate initial analytics baseline
3. Set up notification schedules
4. Prepare welcome emails for employees
5. Create sample reports with dummy data
6. Initialize AI models with industry templates

### User Experience
1. Show animated progress indicator
2. Display "Building your system" with checklist
3. Redirect to complete dashboard
4. Show welcome tour highlighting key features
5. Display onboarding summary with next steps

---

## Smart Features Throughout

### Validation
- Real-time field validation
- Duplicate name detection
- Price range checks
- Contact number formatting
- Email validation

### Data Intelligence
- Auto-complete for common entries
- Smart suggestions based on industry
- Error prevention hints
- Data consistency checks

### Progress Tracking
- Step completion percentage
- Save and continue later option
- Editable previous steps
- Estimated time remaining

### Help System
- Contextual tooltips
- Video tutorials per step
- Live chat support
- Sample data preview

---

## Technical Implementation Notes

### Frontend Components Required
1. `OnboardingWizard.tsx` - Main wizard container
2. `StepIndicator.tsx` - Progress visualization
3. `BusinessFoundation.tsx` - Step 1 form
4. `BranchConfiguration.tsx` - Step 2 form
5. `WorkforceSetup.tsx` - Step 3 form
6. `InventoryFoundation.tsx` - Step 4 form
7. `SystemPreferences.tsx` - Step 5 form
8. `AnalyticsSetup.tsx` - Step 6 form
9. `BrandingSecurity.tsx` - Step 7 form
10. `GenerationProgress.tsx` - Auto-generation status

### Backend Requirements
1. Onboarding session management
2. Incremental data saving (per step)
3. Bulk data insertion on completion
4. Default value generation
5. Validation rules engine
6. Auto-generation orchestration

### Database Operations
1. Atomic transaction for all inserts
2. Rollback on any failure
3. Audit logging of onboarding process
4. Session cleanup after completion

---

## User Flow Example

**Scenario:** Rajesh owns 3 mobile phone shops in Mumbai

### Step 1: Business Foundation
- Business Name: "Mobile Hub"
- Industry: Electronics Shop → Mobile Shop
- Branches: 3

### Step 2: Branch Configuration
1. "Mobile Hub Andheri" - Medium, Andheri West, 10 AM - 10 PM
2. "Mobile Hub Powai" - Small, Powai, 11 AM - 9 PM
3. "Mobile Hub Bandra" - Large, Bandra West, 9 AM - 11 PM

### Step 3: Workforce Setup
- Total: 12 employees
- Andheri: 1 Manager, 2 Cashiers, 2 Staff
- Powai: 1 Manager, 1 Cashier, 1 Staff
- Bandra: 1 Manager, 2 Cashiers, 1 Staff

### Step 4: Inventory Foundation
- Categories: iPhone Accessories, Samsung Accessories, Phone Cases, Screen Guards, Chargers, Power Banks
- Quick Start: Add 10 bestselling products per branch
- System suggests: iPhone 15 cases, Samsung Galaxy cases, etc.

### Step 5: System Preferences
- Currency: INR
- GST: Enabled (18%)
- Billing: Detailed
- Discounts: Enabled

### Step 6: Analytics Setup
- All insights enabled
- Dashboard: Modern
- All notifications enabled

### Step 7: Branding
- Upload Mobile Hub logo
- Brand color: Orange
- Slogan: "Your Mobile Partner"
- 2FA: Enabled

### Result
In 8-12 minutes, Rajesh has a complete system with:
- 3 branch dashboards
- 12 employee accounts
- 60+ products tracked
- Real-time inventory
- AI-powered analytics
- Professional invoicing
- Automated alerts

---

## Success Metrics

The onboarding flow is successful when:
1. 90%+ completion rate
2. Average time: 10-15 minutes
3. No step takes more than 3 minutes
4. Users understand their generated system
5. Zero manual configuration needed post-onboarding
6. Immediate system usability

---

## Future Enhancements

1. Import from existing POS systems
2. Integration with accounting software
3. Pre-populated industry templates
4. Video onboarding option
5. Voice-guided setup
6. Mobile app onboarding
7. Multi-language support
8. Onboarding analytics for optimization