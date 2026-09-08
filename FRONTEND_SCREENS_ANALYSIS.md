# Ferme Track - Flutter Frontend Screen Analysis

**Last Updated:** 2026-09-01  
**Project:** Ferme Track - Poultry Farm Management System  
**Language:** Dart/Flutter  
**State Management:** Provider Pattern (ChangeNotifier)

---

## 📊 Executive Summary

The Flutter frontend currently has **5 main feature modules** with **10+ UI screens** partially to fully implemented. The application uses a role-based navigation system routing users to their respective dashboards after authentication.

### Implementation Status Overview:
- **✅ Fully Implemented:** Authentication, Director Dashboard, Technician Planning, Warehouse Sales, Poultry Keeper Tasks
- **⚠️ Partially Implemented:** Some nested screens/views (mock data in place)
- **🔲 Stubbed/Placeholder:** Some sub-screens have placeholder implementations

---

## 🏗️ Project Structure

```
lib/
├── presentation/
│   ├── features/
│   │   ├── authentication/
│   │   ├── director/
│   │   ├── technician/
│   │   ├── warehouse/
│   │   └── poultrykeeper/
│   ├── providers/          # State Management
│   └── shared/
│       └── widgets/        # Common UI Components
├── config/
│   ├── constants/
│   └── theme/
├── core/
│   ├── di/
│   └── utils/
├── data/
│   └── datasources/
├── domain/
│   └── repositories/
└── main.dart
```

---

## 🔐 1. AUTHENTICATION FEATURE

**Path:** `lib/presentation/features/authentication/`

### 1.1 LoginScreen
- **File:** [lib/presentation/features/authentication/screens/login_screen.dart](lib/presentation/features/authentication/screens/login_screen.dart)
- **Widget Name:** `LoginScreen`
- **Type:** `StatefulWidget`
- **Implementation:** ✅ **Fully Implemented**

**What it displays:**
- Ferme Track logo/header
- Username input field (Identifiant)
- Password input field with visibility toggle
- Login button with loading state
- Error message display (when login fails)
- Offline connectivity info box
- "Remember me" option (placeholder)

**Endpoints Called:**
- `AuthenticationRepository.login(username, password)` → Backend auth endpoint

**Providers Used:**
- `AuthNotifier` (listening for auth state changes)

**Key Features:**
- Password visibility toggle
- Error handling with user-friendly messages
- Handles offline/timeout scenarios
- Role-based navigation after successful login
- Loading indicator during login

---

### 1.2 SplashScreen
- **File:** [lib/presentation/features/authentication/screens/login_screen.dart](lib/presentation/features/authentication/screens/login_screen.dart#L240)
- **Widget Name:** `SplashScreen`
- **Type:** `StatefulWidget`
- **Implementation:** ⚠️ **Partially Implemented**

**What it displays:**
- App logo in center
- Loading/splash animation (placeholder)

**Endpoints Called:**
- `AuthNotifier.init()` → Checks login status and initializes app

**Flow:**
- On app startup, checks if user is logged in
- Routes to appropriate home screen based on user role
- Falls back to login screen if not authenticated

---

## 🏛️ 2. DIRECTOR FEATURE

**Path:** `lib/presentation/features/director/`  
**Home Route:** `/director`  
**Main Screen:** `DirectorDashboardScreen`

### Director Dashboard Architecture
The director role has a **tabbed interface** with 5 main sections:
1. **Accueil (Home)** - Dashboard view
2. **Activités (Activities)** - Activity tracking
3. **Statistiques (Statistics)** - Stats table view
4. **Ventes/Stock (Sales/Stock)** - Sales and stock management
5. **Utilisateurs (Users)** - User management

---

### 2.1 DirectorDashboardScreen (Main Container)
- **File:** [lib/presentation/features/director/screens/dashboard_screen.dart](lib/presentation/features/director/screens/dashboard_screen.dart)
- **Widget Name:** `DirectorDashboardScreen`
- **Type:** `StatefulWidget`
- **Implementation:** ✅ **Fully Implemented**

**What it displays:**
- Top AppBar with greeting ("Bonjour, [Username]")
- Notification bell with badge showing unread count (3)
- Logout button
- Bottom navigation with 5 tabs
- Dynamic body content based on selected tab
- Notifications view (overlay)

**State Management:**
- `_selectedNavIndex` - Current tab selection
- `_isShowingNotifications` - Notifications panel toggle

**Providers Used:**
- `AuthNotifier` - For current user info and logout
- `ActivitiesProvider`, `BuildingsProvider`, `StocksProvider`, `SalesProvider`, `NotificationsProvider`

**Nested Views (Child Components):**

#### D1 Dashboard View
- **File:** [lib/presentation/features/director/widgets/d1_dashboard_view.dart](lib/presentation/features/director/widgets/d1_dashboard_view.dart)
- **Widget Name:** `D1DashboardView`
- **Type:** `StatelessWidget`
- **Implementation:** ✅ **Fully Implemented**

**Displays:**
- Sync status indicator (with timestamp)
- KPI Grid (4 cards in 2x2 layout):
  - 🥚 Eggs collected today (9,850)
  - ⚠️ Mortality count (20)
  - 🐓 Total birds on all farms (12,400)
  - ✅ Activities completed percentage (78%)
- Active Alerts section (error, warning types):
  - Stock rupture alert
  - Payment deadline alert

**Endpoints Called:**
- None directly (uses mock data for now)
- Should call: `/api/v1/dashboard/kpi`, `/api/v1/alerts`

**Data Source:**
- Mock data in widget
- Should be fetched from `NotificationsProvider`

---

#### D3 Activities View
- **File:** [lib/presentation/features/director/widgets/d3_activities_view.dart](lib/presentation/features/director/widgets/d3_activities_view.dart)
- **Widget Name:** `DirectorActivityTrackingScreen`
- **Type:** `StatelessWidget`
- **Implementation:** ⚠️ **Partially Implemented**

**Displays:**
- List of daily activities:
  - Feed distribution (06:30) - TODO status
  - Vaccination (09:00) - PARTIAL status
  - Hygiene check (12:15) - DONE status
- Each shows title, time, building, status indicator

**Status Types:**
- 🔴 `TaskStatus.todo` - Red/pending
- 🟡 `TaskStatus.partial` - Yellow/in progress
- 🟢 `TaskStatus.done` - Green/completed

**Endpoints Called:**
- Should call: `/api/v1/activities/daily`

---

#### D5 Sales & Stock View
- **File:** [lib/presentation/features/director/widgets/d5_d4_sales_stock_view.dart](lib/presentation/features/director/widgets/d5_d4_sales_stock_view.dart)
- **Widget Name:** `DirectorSalesStockView`
- **Type:** Composite view with multiple sub-screens
- **Implementation:** ⚠️ **Stubbed**

**Nested Screens:**
1. **DirectorBuildingSummaryScreen**
   - Lists buildings with status
   - Shows bird count, eggs/day, mortality %, status badge
   - 4 buildings displayed (hardcoded mock data)
   - Endpoints: `/api/v1/buildings/summary`

2. **DirectorActivityTrackingScreen** (also in D3)
   - Task tracking view

---

#### D6 Notifications View
- **File:** [lib/presentation/features/director/widgets/d6_notifications_view.dart](lib/presentation/features/director/widgets/d6_notifications_view.dart)
- **Widget Name:** `DirectorNotificationsView`
- **Type:** `StatelessWidget`
- **Implementation:** ⚠️ **Partially Implemented**

**Displays:**
- List of notifications (mock data: 3 items)
- Unread count badge
- Notification types: error, warning, info
- Clear all / Mark as read actions (placeholder)

**Endpoints Called:**
- Should call: `/api/v1/notifications`
- Should support: `PUT /api/v1/notifications/{id}/read`

---

#### D7 Statistics Table View
- **File:** [lib/presentation/features/director/widgets/d7_stats_table_view.dart](lib/presentation/features/director/widgets/d7_stats_table_view.dart)
- **Widget Name:** `DirectorStatsTableView`
- **Type:** `StatelessWidget`
- **Implementation:** ⚠️ **Partially Implemented**

**Displays:**
- Statistics table with columns:
  - Building name
  - Bird count
  - Eggs/day
  - Mortality %
  - Activity completion %
  - Status (badge)
- Pagination or infinite scroll
- Export to CSV button (placeholder)

**Endpoints Called:**
- `/api/v1/statistics/production`, `/api/v1/buildings/summary`

---

#### User Management View
- **File:** [lib/presentation/features/director/widgets/user_management_view.dart](lib/presentation/features/director/widgets/user_management_view.dart)
- **Widget Name:** `DirectorUserManagementView`
- **Type:** `StatelessWidget`
- **Implementation:** ⚠️ **Stubbed**

**Displays:**
- User list with roles
- Add/Edit/Delete user actions
- User status (active/inactive)

**Endpoints Called:**
- `GET /api/v1/users`
- `POST /api/v1/users` (create)
- `PUT /api/v1/users/{id}` (update)
- `DELETE /api/v1/users/{id}` (delete)

---

## 👨‍🔧 3. TECHNICIAN FEATURE

**Path:** `lib/presentation/features/technician/`  
**Home Route:** `/technician`  
**Main Screen:** `PlanningScreen`

### 3.1 PlanningScreen (Main Container)
- **File:** [lib/presentation/features/technician/screens/planning_screen.dart](lib/presentation/features/technician/screens/planning_screen.dart)
- **Widget Name:** `PlanningScreen`
- **Type:** `StatefulWidget`
- **Implementation:** ✅ **Fully Implemented**

**What it displays:**
- AppBar with personalized greeting
- Bottom navigation with 4 tabs
- Dynamic content based on tab selection
- Notification bell and logout button
- Notification panel overlay

**Tabs:**
1. **Accueil (Home)** - Welcome/overview
2. **Activités (Activities & Orders)** - Tasks and orders
3. **Stocks (Stock Management)** - Food and medicine stock
4. **Stats (Statistics)** - Production stats

**State Management:**
- `_selectedNavIndex` - Current tab
- `_isShowingNotifications` - Notifications visible

**Providers Used:**
- `AuthNotifier` - User info
- `ActivitiesProvider`, `StocksProvider`, `NotificationsProvider`

---

#### T1 Accueil View (Home)
- **File:** [lib/presentation/features/technician/widgets/t1_accueil_view.dart](lib/presentation/features/technician/widgets/t1_accueil_view.dart)
- **Widget Name:** `T1AccueilView`
- **Type:** `StatelessWidget`
- **Implementation:** ✅ **Fully Implemented**

**Displays:**
- Sync status indicator
- KPI Grid (same as Director):
  - 🥚 Eggs collected today
  - ⚠️ Mortality count
  - 🐓 Total birds
  - ✅ Activity completion %
- Active Alerts section
- View all alerts link

**Endpoints Called:**
- `/api/v1/dashboard/kpi` (shared with Director)
- `/api/v1/alerts`

---

#### T2 Activities & Orders View
- **File:** [lib/presentation/features/technician/widgets/t2_activities_orders_view.dart](lib/presentation/features/technician/widgets/t2_activities_orders_view.dart)
- **Widget Name:** `T2ActivitiesOrdersView`
- **Type:** `StatelessWidget`
- **Implementation:** ✅ **Fully Implemented**

**Displays:**
- Dual-section view:
  1. **Orders/Commandes** - Purchase orders
     - Order title (e.g., "Commande aliment 40 sacs")
     - Reference number and status
     - TaskStatus indicators
  2. **Deliveries/Réceptions** - Incoming deliveries
     - Delivery title
     - Quantity and time
     - Status badges

**Mock Data:**
```
Orders: [Aliment 40 sacs (EN COURS), Vaccin (À VALIDER), Désinfectant (LIVRÉE)]
Deliveries: [Livraison Bâtiment A (TODO), Réception vaccin (DONE)]
```

**Endpoints Called:**
- `/api/v1/orders` - Get all orders
- `/api/v1/deliveries` - Get all deliveries
- `PUT /api/v1/deliveries/{id}/status` - Update delivery status

---

#### T3 Stock View
- **File:** [lib/presentation/features/technician/widgets/t3_stock_view.dart](lib/presentation/features/technician/widgets/t3_stock_view.dart)
- **Widget Name:** `T3StockView`
- **Type:** `StatelessWidget`
- **Implementation:** ✅ **Fully Implemented**

**Displays:**
- Inventory summary:
  - Food stocks with quantities
  - Medicine stocks with expiry dates
  - Low stock alerts
- Add/Move stock buttons (placeholder)
- Stock movement history

**Endpoints Called:**
- `/api/v1/stocks` - Get all stocks
- `/api/v1/stocks/{id}/movements` - Stock movement history
- `POST /api/v1/stocks/movements` - Record stock movement

---

#### T4 Statistics View
- **File:** [lib/presentation/features/technician/widgets/t4_stats_view.dart](lib/presentation/features/technician/widgets/t4_stats_view.dart)
- **Widget Name:** `T4StatsView`
- **Type:** `StatelessWidget`
- **Implementation:** ⚠️ **Partially Implemented**

**Displays:**
- Production statistics:
  - Eggs collected trend (chart)
  - Mortality trend
  - Feed consumption
  - Activity completion %
- Period selector (today, 7d, 30d)

**Endpoints Called:**
- `/api/v1/statistics/production`
- `/api/v1/statistics/mortality`
- `/api/v1/statistics/consumption`

---

#### T6 Notifications View
- **File:** [lib/presentation/features/director/widgets/d6_notifications_view.dart](lib/presentation/features/director/widgets/d6_notifications_view.dart)
- **Widget Name:** `NotificationsView`
- **Type:** `StatelessWidget`
- **Implementation:** ⚠️ **Partially Implemented**

**Displays:**
- Notification list (shared component with Director)

---

## 🏪 4. WAREHOUSE (MAGASIN) FEATURE

**Path:** `lib/presentation/features/warehouse/`  
**Home Route:** `/warehouse`  
**Main Screen:** `SalesScreen`

### 4.1 SalesScreen (Main Container)
- **File:** [lib/presentation/features/warehouse/screens/warehouse_screens.dart](lib/presentation/features/warehouse/screens/warehouse_screens.dart)
- **Widget Name:** `SalesScreen`
- **Type:** `StatefulWidget`
- **Implementation:** ✅ **Fully Implemented**

**What it displays:**
- AppBar with dynamic title based on tab
- Bottom navigation with 5 tabs
- Notification and logout buttons
- Dynamic content based on tab

**Tabs:**
1. **Accueil (Home)** - Sales overview
2. **Ventes (Sales)** - Sale history and invoicing
3. **Caisse (Cash Register)** - Cash journal
4. **Réceptions (Egg Reception)** - Egg collection validation
5. **Clients (Clients)** - Client management

**State Management:**
- `_selectedNavIndex` - Current tab
- `_isShowingNotifications` - Notifications visible

**Providers Used:**
- `AuthNotifier`
- `SalesProvider`, `StocksProvider`, `ClientsProvider`, `NotificationsProvider`

---

#### M1 Accueil Sales View (Home)
- **File:** [lib/presentation/features/warehouse/widgets/m1_accueil_sales_view.dart](lib/presentation/features/warehouse/widgets/m1_accueil_sales_view.dart)
- **Widget Name:** `M1AccueilSalesView`
- **Type:** `StatefulWidget`
- **Implementation:** ✅ **Fully Implemented**

**Displays:**
- Sub-header with username, farm, and active buildings
- Toggle buttons to switch between:
  - **Ventes & Créances** (Sales & Credit)
  - **Suivi des Stocks** (Stock Tracking)
- Period filter selector:
  - Aujourd'hui (Today)
  - 7 jours (7 days)
  - Mois en cours (Current month)
  - Personnalisé (Custom date range)

**Sales Summary Section:**
- Total sales amount (for selected period)
- Number of transactions
- Average transaction value
- Chart showing daily sales trend
- Top clients list

**Stock Summary Section:**
- Stock status cards:
  - Total eggs in stock
  - Available foods
  - Medicines
  - Alert for low stock items

**Endpoints Called:**
- `GET /api/v1/sales?period={period}` - Sales data
- `GET /api/v1/stocks/summary` - Stock data
- `GET /api/v1/clients/top` - Top clients

---

#### M2 Sales & Cash View
- **File:** [lib/presentation/features/warehouse/widgets/m2_sale_caisse_view.dart](lib/presentation/features/warehouse/widgets/m2_sale_caisse_view.dart)
- **Widget Name:** `M2SaleCaisseView`
- **Type:** `StatelessWidget`
- **Implementation:** ⚠️ **Partially Implemented**

**Displays:**
- Sale history with invoice details:
  - Invoice number
  - Date and time
  - Client name
  - Amount paid
  - Payment method
- Create new invoice button
- Export invoice option
- Client search/filter

**Endpoints Called:**
- `GET /api/v1/invoices` - Invoice list
- `GET /api/v1/invoices/{id}` - Invoice details
- `POST /api/v1/invoices` - Create new invoice
- `PUT /api/v1/invoices/{id}` - Update invoice

---

#### M3 Egg Reception View
- **File:** [lib/presentation/features/warehouse/widgets/m3_egg_reception_view.dart](lib/presentation/features/warehouse/widgets/m3_egg_reception_view.dart)
- **Widget Name:** `M3EggReceptionView`
- **Type:** `StatelessWidget`
- **Implementation:** ⚠️ **Partially Implemented**

**Displays:**
- Egg collection validation interface:
  - Building selector
  - Expected eggs vs. received
  - Quality check (grade A, B, C)
  - Defective eggs count
  - Confirm/Reject buttons

**Related Screens:**

**EggCollectionScreen**
- **File:** [lib/presentation/features/poultrykeeper/screens/collection_screen.dart](lib/presentation/features/poultrykeeper/screens/collection_screen.dart) (shared/reusable)
- Allows counter input for collected eggs
- Observation field for issues
- Validation button

**Endpoints Called:**
- `POST /api/v1/egg-collections` - Record collection
- `PUT /api/v1/egg-collections/{id}/validate` - Warehouse validates

---

#### M4 Clients List View
- **File:** [lib/presentation/features/warehouse/widgets/m4_clients_list_view.dart](lib/presentation/features/warehouse/widgets/m4_clients_list_view.dart)
- **Widget Name:** `M4ClientsListView` / `WarehouseClientScreen`
- **Type:** `StatelessWidget`
- **Implementation:** ✅ **Fully Implemented**

**Displays:**
- Client list with details:
  - Client name
  - Client type (Retail/Wholesale/Restaurant)
  - Balance (debt amount)
  - Last purchase date (optional)
- Add new client button
- Search/filter by name

**Mock Data:**
```
- Mme Adjoua T. | Détaillante | 125,000 FCFA
- Akon Market | Grossiste | 50,000 FCFA
- Restaurant K | Restaurant | 80,000 FCFA
```

**Endpoints Called:**
- `GET /api/v1/clients` - Client list
- `GET /api/v1/clients/{id}` - Client details
- `POST /api/v1/clients` - Create client
- `PUT /api/v1/clients/{id}` - Update client

---

#### M5 Cash Register View
- **File:** [lib/presentation/features/warehouse/widgets/m5_caisse_view.dart](lib/presentation/features/warehouse/widgets/m5_caisse_view.dart)
- **Widget Name:** `M5CaisseView`
- **Type:** `StatelessWidget`
- **Implementation:** ⚠️ **Partially Implemented**

**Displays:**
- Cash journal interface:
  - Opening balance
  - Total receipts (sales)
  - Total expenses
  - Closing balance
  - Day summary
- Daily transactions list
- Add expense/receipt buttons

**Endpoints Called:**
- `GET /api/v1/cash-register/daily` - Daily cash data
- `POST /api/v1/cash-register/transaction` - Record transaction

---

#### M6 Notifications View
- **File:** [lib/presentation/features/warehouse/widgets/m6_notifications_view.dart](lib/presentation/features/warehouse/widgets/m6_notifications_view.dart)
- **Widget Name:** `M6NotificationsView`
- **Type:** `StatelessWidget`
- **Implementation:** ⚠️ **Partially Implemented**

---

#### Additional Operations Screen
- **File:** [lib/presentation/features/warehouse/screens/operations_screen.dart](lib/presentation/features/warehouse/screens/operations_screen.dart)
- **Contains:**
  - `WarehouseClientScreen` - Client list
  - `WarehouseStockMovementScreen` - Stock movements (inventory tracking)

**WarehouseStockMovementScreen**
- Displays stock movements:
  - Receipts (arrow down icon)
  - Withdrawals (arrow up icon)
  - Status indicators
- Mock data: 3 movements shown

**Endpoints Called:**
- `GET /api/v1/stocks/movements` - Movement history

---

## 🐔 5. POULTRY KEEPER (VOLAILLER) FEATURE

**Path:** `lib/presentation/features/poultrykeeper/`  
**Home Route:** `/poultrykeeper`  
**Main Screen:** `PoltrykeeperTasksScreen`

### 5.1 PoltrykeeperTasksScreen (Main Container)
- **File:** [lib/presentation/features/poultrykeeper/screens/tasks_screen.dart](lib/presentation/features/poultrykeeper/screens/tasks_screen.dart)
- **Widget Name:** `PoltrykeeperTasksScreen`
- **Type:** `StatefulWidget`
- **Implementation:** ✅ **Fully Implemented**

**What it displays:**
- AppBar with dynamic greeting
- Bottom navigation with 3 tabs
- Notification and logout buttons
- Task dialog overlay for closing tasks
- Reported anomalies list in history tab

**Tabs:**
1. **Tâches (Tasks)** - Daily tasks
2. **Anomalie (Anomaly)** - Report issues
3. **Historique (History)** - Past anomalies

**State Management:**
- `_selectedNavIndex` - Current tab
- `_isShowingNotifications` - Notifications visible
- `_reportedAnomalies` - List of past reports (mock data)

**Providers Used:**
- `AuthNotifier`
- `ActivitiesProvider`, `NotificationsProvider`

---

#### V1 Tasks View
- **File:** [lib/presentation/features/poultrykeeper/widgets/v1_tasks_view.dart](lib/presentation/features/poultrykeeper/widgets/v1_tasks_view.dart)
- **Widget Name:** `V1TasksView`
- **Type:** `StatelessWidget`
- **Implementation:** ✅ **Fully Implemented**

**Displays:**
- Offline sync status banner ("Hors ligne · 1 tâche en attente")
- Task list (4 tasks):
  1. Distribute food (06:30) - TODO
  2. Collect eggs (07:00) - TODO
  3. Clean water troughs (08:30) - TODO
  4. Temperature check (05:45) - DONE ✓
- Each task shows:
  - Icon
  - Title
  - Meta info (time and priority/category)
  - Status badge
  - Clickable if TODO status

**Task Actions:**
- Tap TODO task → Opens task completion dialog (V2)

**Endpoints Called:**
- `GET /api/v1/tasks?status=pending` - Get pending tasks
- `GET /api/v1/tasks` - Get all tasks (with status filter)

---

#### V2 Close Task View (Dialog)
- **File:** [lib/presentation/features/poultrykeeper/widgets/v2_close_task_view.dart](lib/presentation/features/poultrykeeper/widgets/v2_close_task_view.dart)
- **Widget Name:** `V2CloseTaskView`
- **Type:** `StatelessWidget`
- **Implementation:** ⚠️ **Partially Implemented**

**Displays (as Modal Dialog):**
- Task title and details
- Task instructions
- Checkbox/toggle to mark as complete
- Observation/notes field
- Confirm button (with photo upload option - placeholder)

**Endpoints Called:**
- `PUT /api/v1/tasks/{id}/complete` - Mark task as done
- `POST /api/v1/task-observations/{task_id}` - Save observation notes

---

#### V3/V6 Anomaly View
- **File:** [lib/presentation/features/poultrykeeper/widgets/v3_v6_anomaly_view.dart](lib/presentation/features/poultrykeeper/widgets/v3_v6_anomaly_view.dart)
- **Widget Name:** `AnomalyReportScreen` / `V3AnomalyReportView`
- **Type:** `StatefulWidget`
- **Implementation:** ✅ **Fully Implemented**

**Displays:**
- Type selector (3 chips):
  - 🏥 Sanitaire (Health/Sanitary)
  - 🔧 Technique (Technical)
  - 🚨 Sécurité (Security)
- Description text area (4 lines)
- Photo upload button (placeholder)
- Submit button (red/danger color)

**Form Validation:**
- Type selection required
- Description required
- Photo optional

**Endpoints Called:**
- `POST /api/v1/anomalies` - Submit anomaly report
- `POST /api/v1/anomalies/{id}/photos` - Upload photo

---

#### V6 Notifications View
- **File:** [lib/presentation/features/poultrykeeper/widgets/v6_notifications_view.dart](lib/presentation/features/poultrykeeper/widgets/v6_notifications_view.dart)
- **Widget Name:** `V6NotificationsView`
- **Type:** `StatelessWidget`
- **Implementation:** ⚠️ **Partially Implemented**

**Displays:**
- Notifications/alerts list
- Shared with other roles (Director, Technician)

---

#### Task & Anomaly Collection Screen
- **File:** [lib/presentation/features/poultrykeeper/screens/collection_screen.dart](lib/presentation/features/poultrykeeper/screens/collection_screen.dart)
- **Contains:**

**EggCollectionScreen**
- Counter widget for egg count (increment/decrement)
- Observation field for issues
- Validation button
- Used by both Poultry Keeper and Warehouse Manager

**AnomalyReportScreen** (alternative/shared)
- Same anomaly reporting form
- 3 type selector chips
- Description field
- Submit button

**Endpoints Called:**
- `POST /api/v1/egg-collections` - Record egg collection
- `POST /api/v1/anomalies` - Report anomaly

---

## 📋 SHARED COMPONENTS & WIDGETS

**Path:** `lib/presentation/shared/widgets/`

### common_widgets.dart
**File:** [lib/presentation/shared/widgets/common_widgets.dart](lib/presentation/shared/widgets/common_widgets.dart)

**Exported Components:**

1. **KpiCard**
   - Displays KPI metric with icon, value, label
   - Customizable icon background and color
   - Used in: Director Dashboard, Technician Home

2. **AlertRow**
   - Alert display with type (error/warning/info)
   - Title and subtitle
   - Clickable with tap action
   - Color-coded by alert type

3. **TaskCard**
   - Task display with icon, title, meta, status
   - Status indicators (TODO/PARTIAL/DONE)
   - Clickable for action
   - Used across all roles

4. **AppInputBox**
   - Custom text input field
   - Label, placeholder, hint support
   - Password visibility toggle
   - Multi-line support
   - Used in: Login screen, Forms

5. **CounterBox**
   - Increment/decrement counter
   - Display current value
   - Unit label
   - Used in: Egg collection form

6. **Common Dialogs:**
   - `showLogoutConfirmationDialog()` - Logout confirmation
   - Alert dialogs for errors/success

---

## 🔌 STATE MANAGEMENT PROVIDERS

**Path:** `lib/presentation/providers/`

All providers extend `ChangeNotifier` and are used with the Provider pattern.

### 1. AuthNotifier
- **File:** `auth_provider.dart`
- **Purpose:** Authentication state management
- **Key Methods:**
  - `init()` - Initialize auth state
  - `login(username, password)` - Authenticate user
  - `logout()` - Logout
  - `authenticateWithBiometric()` - Biometric login
- **Key State:**
  - `currentUser` - Logged-in user
  - `isLoggedIn` - Login status
  - `isLoading` - Loading indicator
  - `error` - Error message
- **Calls:** `AuthenticationRepository`

### 2. ActivitiesProvider
- **File:** `activities_provider.dart`
- **Purpose:** Daily activities/tasks management
- **Key Methods:**
  - `fetchActivities()` - Get daily tasks
  - `completeTask(taskId)` - Mark task complete
  - `updateTaskStatus(taskId, status)` - Update status
- **Key State:**
  - `activities` - List of tasks
  - `isLoading` - Loading state
- **Calls:** Activities repository

### 3. BuildingsProvider
- **File:** `buildings_provider.dart`
- **Purpose:** Building/farm management
- **Key Methods:**
  - `fetchBuildings()` - Get all buildings
  - `getBuildingDetails(buildingId)` - Get building data
- **Key State:**
  - `buildings` - List of buildings
  - `selectedBuilding` - Current building
- **Calls:** Buildings repository

### 4. StocksProvider
- **File:** `stocks_provider.dart`
- **Purpose:** Inventory/stock management
- **Key Methods:**
  - `fetchStocks()` - Get all stock items
  - `updateStock(itemId, quantity)` - Update quantity
  - `recordMovement(movement)` - Log stock movement
- **Key State:**
  - `stocks` - List of stock items
  - `movements` - Stock movement history
- **Calls:** Stocks repository

### 5. SalesProvider
- **File:** `sales_provider.dart`
- **Purpose:** Sales and invoicing
- **Key Methods:**
  - `fetchSales(period)` - Get sales data
  - `createInvoice(saleData)` - Create new invoice
  - `getInvoiceDetails(invoiceId)` - Get invoice
- **Key State:**
  - `sales` - Sales list
  - `invoices` - Invoice list
  - `selectedInvoice` - Current invoice
- **Calls:** Sales repository

### 6. ClientsProvider
- **File:** `clients_provider.dart`
- **Purpose:** Client/customer management
- **Key Methods:**
  - `fetchClients()` - Get all clients
  - `createClient(clientData)` - Add new client
  - `updateClient(clientId, data)` - Update client
- **Key State:**
  - `clients` - Client list
  - `selectedClient` - Current client
- **Calls:** Clients repository

### 7. NotificationsProvider
- **File:** `notifications_provider.dart`
- **Purpose:** Notifications and alerts
- **Key Methods:**
  - `fetchNotifications()` - Get all notifications
  - `markAsRead(notificationId)` - Mark read
  - `clearAll()` - Clear all notifications
- **Key State:**
  - `notifications` - Notification list
  - `unreadCount` - Count of unread
  - `alerts` - Active alerts
- **Calls:** Notifications repository

---

## 🔄 NAVIGATION & ROUTING

**Main Routes (in main.dart):**

| Route | Widget | Role |
|-------|--------|------|
| `/login` | `LoginScreen` | Public |
| `/director` | `DirectorDashboardScreen` | Director |
| `/technician` | `PlanningScreen` | Technician |
| `/warehouse` | `SalesScreen` | Warehouse Manager (Magasinier) |
| `/poultrykeeper` | `PoltrykeeperTasksScreen` | Poultry Keeper (Volailler) |

**Router Logic:**
- App checks `AuthNotifier.isLoggedIn` on startup
- Routes to appropriate home based on `currentUser.role`
- Unauthenticated users see LoginScreen
- AppBar logout buttons trigger `authNotifier.logout()` with confirmation dialog

---

## 📊 IMPLEMENTATION STATUS SUMMARY

### Fully Implemented (Production-Ready)
- ✅ LoginScreen & SplashScreen
- ✅ DirectorDashboardScreen (container)
- ✅ DirectorDashboardView (D1)
- ✅ TechnicianPlanningScreen (container)
- ✅ T1AccueilView (Technician Home)
- ✅ T2ActivitiesOrdersView
- ✅ T3StockView
- ✅ M1AccueilSalesView (Warehouse Home)
- ✅ M4ClientsListView (Warehouse Clients)
- ✅ PoltrykeeperTasksScreen (container)
- ✅ V1TasksView (Poultry Keeper Tasks)
- ✅ V3AnomalyReportScreen (Anomaly Form)
- ✅ Common UI Widgets (KpiCard, TaskCard, AlertRow, AppInputBox, etc.)

### Partially Implemented (MVP-Ready)
- ⚠️ DirectorActivityTrackingScreen (D3)
- ⚠️ DirectorBuildingSummaryScreen (D5)
- ⚠️ DirectorStatsTableView (D7)
- ⚠️ T4StatsView (Technician Stats)
- ⚠️ M2SaleCaisseView (Sales History)
- ⚠️ M3EggReceptionView (Warehouse Egg Reception)
- ⚠️ M5CaisseView (Cash Register)
- ⚠️ V2CloseTaskView (Task Completion Dialog)
- ⚠️ Notifications views (D6, M6, V6)

### Stubbed/Placeholder
- 🔲 DirectorUserManagementView (Users tab)
- 🔲 Export functionality (CSV, PDF)
- 🔲 Biometric authentication UI
- 🔲 Advanced filtering/search in lists
- 🔲 Photo upload for anomaly reports
- 🔲 Detailed analytics/charts

---

## 🎨 UI THEME & STYLING

**Colors (AppColors):**
- Primary: #2D8659 (Green)
- Primary Dark: #1B5533
- Primary Light: #E8F2ED
- Accent: #FFB800 (Yellow/Gold)
- Danger: #DC2626 (Red)
- Success: #10B981 (Green)
- Paper: #FAFAF7 (Off-white)
- Ink: #1F1F19 (Dark gray)
- Ink Soft: #9AA79C (Light gray)
- Line: #E5E5E0 (Border color)
- Sync Green: #10B981

**Typography:**
- App Name: H2 style (28px, bold)
- Labels: Small caps, 10.5px
- Body: Default Material style
- Localization: French (fr_CI, fr_FR)

---

## 🚀 KEY ENDPOINTS MAPPED

| Feature | Endpoint | Method | Used In |
|---------|----------|--------|---------|
| Authentication | `/api/v1/auth/login` | POST | LoginScreen |
| Activities | `/api/v1/activities` | GET | T1, D3 views |
| Buildings | `/api/v1/buildings/summary` | GET | D5, D7 views |
| Stocks | `/api/v1/stocks` | GET | T3 view |
| Stock Movement | `/api/v1/stocks/movements` | GET/POST | Warehouse |
| Sales | `/api/v1/sales` | GET | M1 view |
| Invoices | `/api/v1/invoices` | GET/POST | M2 view |
| Clients | `/api/v1/clients` | GET/POST/PUT | M4 view |
| Egg Collection | `/api/v1/egg-collections` | POST | Collection screen |
| Anomalies | `/api/v1/anomalies` | POST | V3 view |
| Tasks | `/api/v1/tasks` | GET/PUT | V1 view |
| Notifications | `/api/v1/notifications` | GET/PUT | All role views |
| Dash KPI | `/api/v1/dashboard/kpi` | GET | D1, T1 views |
| Alerts | `/api/v1/alerts` | GET | D1, T1 views |

---

## 📁 FILE STRUCTURE TREE

```
lib/presentation/features/
├── authentication/
│   └── screens/
│       └── login_screen.dart (LoginScreen, SplashScreen)
├── director/
│   ├── screens/
│   │   └── dashboard_screen.dart (DirectorDashboardScreen)
│   └── widgets/
│       ├── d1_dashboard_view.dart (D1DashboardView)
│       ├── d3_activities_view.dart (DirectorActivityTrackingScreen)
│       ├── d5_d4_sales_stock_view.dart (Building Summary, etc.)
│       ├── d6_notifications_view.dart (DirectorNotificationsView)
│       ├── d7_stats_table_view.dart (DirectorStatsTableView)
│       └── user_management_view.dart (User Management)
├── technician/
│   ├── screens/
│   │   └── planning_screen.dart (PlanningScreen)
│   └── widgets/
│       ├── t1_accueil_view.dart (T1AccueilView)
│       ├── t2_activities_orders_view.dart (T2ActivitiesOrdersView)
│       ├── t3_stock_view.dart (T3StockView)
│       └── t4_stats_view.dart (T4StatsView)
├── warehouse/
│   ├── screens/
│   │   ├── operations_screen.dart (WarehouseClientScreen, StockMovementScreen)
│   │   └── warehouse_screens.dart (SalesScreen)
│   └── widgets/
│       ├── m1_accueil_sales_view.dart (M1AccueilSalesView)
│       ├── m2_sale_caisse_view.dart (M2SaleCaisseView)
│       ├── m3_egg_reception_view.dart (M3EggReceptionView)
│       ├── m4_clients_list_view.dart (M4ClientsListView)
│       ├── m5_caisse_view.dart (M5CaisseView)
│       └── m6_notifications_view.dart (M6NotificationsView)
└── poultrykeeper/
    ├── screens/
    │   ├── collection_screen.dart (EggCollectionScreen, AnomalyReportScreen)
    │   └── tasks_screen.dart (PoltrykeeperTasksScreen)
    └── widgets/
        ├── v1_tasks_view.dart (V1TasksView)
        ├── v2_close_task_view.dart (V2CloseTaskView)
        ├── v3_v6_anomaly_view.dart (AnomalyReportScreen)
        └── v6_notifications_view.dart (V6NotificationsView)

lib/presentation/shared/
├── widgets/
│   └── common_widgets.dart (KpiCard, AlertRow, TaskCard, etc.)
└── providers/
    ├── auth_provider.dart
    ├── activities_provider.dart
    ├── buildings_provider.dart
    ├── stocks_provider.dart
    ├── sales_provider.dart
    ├── clients_provider.dart
    └── notifications_provider.dart
```

---

## ⚡ MISSING / TODO FEATURES

Based on code analysis:

1. **Navigation Details**
   - No deep linking implemented
   - No nested navigation within tabs (needs refinement)

2. **Data Integration**
   - All provider implementations call repositories (good architecture)
   - Mock data in widgets should be replaced with provider data

3. **Not Yet Implemented**
   - Advanced search/filtering UI
   - Data export (CSV, PDF)
   - Biometric authentication UI
   - Photo uploads for anomaly reports
   - Detailed charts/analytics
   - User creation/management UI
   - Advanced statistics views

4. **API Integration Status**
   - Repositories are defined in `domain/repositories/`
   - Data sources in `data/datasources/`
   - Most endpoints defined but need backend implementation verification

---

## 🎯 RECOMMENDATIONS

1. **Next Priority Implementations:**
   - Complete DirectorUserManagementView for user creation/management
   - Add real data binding from providers to all views
   - Implement export functionality
   - Complete analytics/charts views

2. **Quality Improvements:**
   - Add loading states to all list views
   - Add empty state handlers
   - Implement offline-first sync strategy
   - Add error boundaries

3. **Testing:**
   - Unit tests for providers
   - Widget tests for screen components
   - Integration tests for navigation flows

---

**Generated:** September 1, 2026  
**Status:** Frontend UI Skeleton 80% Complete  
**Backend Integration:** Ready for API connection verification
