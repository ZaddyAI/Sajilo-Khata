**Sajilo Khata**

Nepal SMS Expense Tracker & Savings Goals

Technical Documentation • v1.0

Built with Flutter + Firebase • Supports all major Nepal banks & wallets • BS/AD dual calendar

# **1\. Project Overview**

Sajilo Khata is a Flutter mobile application that automatically tracks income and expenses by reading SMS messages from Nepali banks and digital wallets. Users can also add transactions manually. All data is stored in Firebase Firestore and syncs across devices on login. A savings goals feature lets users set targets (e.g. "Rs. 80,000 for a laptop by Dashain") and track progress over time.

## **1.1 Why This App**

- No existing Nepali expense tracker parses bank SMS automatically
- Existing apps have poor UX and lack BS date support
- Integrates the developer's own Nepali Calendar Kit package
- Real daily utility - used for NPR, designed for Nepali spending patterns

## **1.2 Tech Stack**

| **Layer**            | **Technology**                          |
| -------------------- | --------------------------------------- |
| **UI Framework**     | Flutter 3.x (Dart)                      |
| **State Management** | BLoC pattern (flutter_bloc)             |
| **Authentication**   | Firebase Auth - Google + Email/Password |
| **Database**         | Cloud Firestore (real-time sync)        |
| **Local Cache**      | Hive (offline-first)                    |
| **Sync Engine**      | Custom SyncService (online/offline)     |
| **SMS Reading**      | telephony package (Android)             |
| **Charts**           | fl_chart                                |
| **Notifications**    | flutter_local_notifications + FCM       |
| **Nepali Dates**     | nepali_calendar_kit (own package)       |
| **ID Generation**    | uuid                                    |
| **Currency API**     | frankfurter.dev (USD ↔ NPR)             |
| **Share**            | share_plus (CSV sharing)                |
| **Network**          | connectivity_plus (online/offline)      |
| **Permissions**      | permission_handler                      |

# **2\. Feature List**

## **2.1 Authentication**

| **Feature**        | **Description**                                 | **Week** |
| ------------------ | ----------------------------------------------- | -------- |
| **Google Sign-In** | One-tap login via Google account                | Week 1   |
| **Email/Password** | Standard email signup and login                 | Week 1   |
| **Profile setup**  | Name, currency preference (NPR default)         | Week 1   |
| **Device sync**    | Login on any device - data loads from Firestore | Week 1   |

## **2.2 SMS Auto-Reader**

| **Feature**         | **Description**                                            | **Week** |
| ------------------- | ---------------------------------------------------------- | -------- |
| **Auto SMS read**   | Reads incoming bank SMS on Android (READ_SMS permission)   | Week 1   |
| **Bank parsers**    | Regex parsers for 7+ Nepal banks and wallets               | Week 1   |
| **Data extraction** | Extracts amount, debit/credit, bank name, datetime         | Week 1   |
| **Manual fallback** | User pastes SMS text - app parses and logs (iOS + unknown) | Week 1   |
| **Unknown SMS**     | Unrecognized messages are silently ignored                 | Week 1   |
| **SMS Groups**      | Select which senders to track (bank filter)                | Week 2   |
| **Auto-toggle**     | Enable/disable auto-tracking in settings                   | Week 2   |

## **2.3 Manual Transactions**

| **Feature**            | **Description**                                          | **Week** |
| ---------------------- | -------------------------------------------------------- | -------- |
| **Add expense/income** | Quick-entry form: amount, category, note, date           | Week 1   |
| **Edit transaction**   | Edit any field of SMS-parsed or manual transactions      | Week 1   |
| **Delete transaction** | Soft delete with confirmation dialog                     | Week 1   |
| **Auto-categorize**    | Keyword matching: Bhatbhateni → Food, Pathao → Transport | Week 1   |

## **2.4 Firebase Sync**

| **Feature**           | **Description**                                               | **Week** |
| --------------------- | ------------------------------------------------------------- | -------- |
| **Firestore storage** | All transactions stored under users/{uid}/transactions        | Week 1   |
| **Offline-first**     | Hive local cache - works without internet, syncs on reconnect | Week 1   |
| **Real-time updates** | Stream-based - UI updates instantly on data change            | Week 1   |

## **2.5 Dashboard & Reports**

| **Feature**          | **Description**                                       | **Week** |
| -------------------- | ----------------------------------------------------- | -------- |
| **Monthly summary**  | Total income, expenses, and net balance for the month | Week 2   |
| **Pie chart**        | Spending breakdown by category (fl_chart)             | Week 2   |
| **Bar chart**        | Daily spend over the last 30 days                     | Week 2   |
| **BS / AD toggle**   | Switch between Bikram Sambat and Gregorian dates      | Week 2   |
| **Transaction list** | Scrollable list - debit in red, credit in green       | Week 2   |
| **Currency convert** | USD ↔ NPR live exchange rate (frankfurter.dev)        | Week 2   |

## **2.6 Savings Goals**

| **Feature**             | **Description**                                         | **Week** |
| ----------------------- | ------------------------------------------------------- | -------- |
| **Create goal**         | Name, emoji, target amount, and deadline (BS or AD)     | Week 2   |
| **Manual contribute**   | Add savings to any goal at any time                     | Week 2   |
| **Auto-contribute**     | On credit SMS, prompt: "Add to a goal?"                 | Week 2   |
| **Progress bar**        | Visual progress with % saved and amount remaining       | Week 2   |
| **Status badge**        | On Track / Behind / Achieved - calculated from deadline | Week 2   |
| **Daily target**        | "Save Rs. X/day" - remaining ÷ days left                | Week 2   |
| **Multiple goals**      | Unlimited goals, sorted by nearest deadline             | Week 2   |
| **Goal achieved alert** | Push notification when 100% is reached                  | Week 2   |

## **2.7 Notifications & Export**

| **Feature**       | **Description**                                       | **Week** |
| ----------------- | ----------------------------------------------------- | -------- |
| **SMS log alert** | Push notification when new transaction is auto-logged | Week 2   |
| **Budget alert**  | Notify at 80% and 100% of monthly budget limit        | Week 2   |
| **Goal alert**    | Celebrate when a savings goal is achieved             | Week 2   |
| **CSV export**    | Export all/expense/income transactions as CSV         | Week 2   |
| **Share**         | Share CSV via any app (share_plus)                    | Week 2   |

# **3\. Project Structure**

The project follows a feature-first architecture. Each feature is self-contained with its own screens, BLoC, repository, and widgets. Core utilities and models are shared across features.

## **3.1 Top-Level Structure**

| **Path**                    | **Purpose**                                              |
| --------------------------- | -------------------------------------------------------- |
| lib/main.dart               | App entry point - Firebase init, BLoC providers, routing |
| lib/core/                   | Shared code: models, services, utils, constants          |
| lib/features/               | One folder per feature, self-contained                   |
| pubspec.yaml                | Package dependencies                                     |
| android/AndroidManifest.xml | SMS permissions (READ_SMS, RECEIVE_SMS)                  |

## **3.2 Core Layer**

| **Path**                                 | **Purpose**                                                   |
| ---------------------------------------- | ------------------------------------------------------------- |
| core/models/transaction_model.dart       | TransactionModel - data class + Firestore serialization       |
| core/models/goal_model.dart              | GoalModel - includes progress/status calculations             |
| core/services/firebase_service.dart      | All Firestore reads, writes, streams - single source of truth |
| core/services/sms_service.dart           | SMS parsing, duplicate check, auto-import                     |
| core/services/notification_service.dart  | Push notifications (FCM + local)                              |
| core/services/sync_service.dart          | Offline/online sync orchestration                             |
| core/services/local_storage_service.dart | Hive local cache for preferences                              |
| core/services/exchange_rate_service.dart | USD ↔ NPR conversion via frankfurter.dev                      |
| core/utils/categorizer.dart              | Keyword → category auto-assignment                            |
| core/constants/app_theme.dart            | Light & dark MaterialTheme definitions                        |

## **3.3 Features Layer**

| **Path**                                                   | **Purpose**                                                                    |
| ---------------------------------------------------------- | ------------------------------------------------------------------------------ |
| features/auth/bloc/auth_bloc.dart                          | AuthBloc - Google/email login, logout, session check                           |
| features/auth/bloc/auth_event.dart                         | Auth events (AuthCheckRequested, AuthLoginRequested, etc)                      |
| features/auth/bloc/auth_state.dart                         | Auth states (AuthInitial, AuthLoading, AuthAuthenticated, AuthUnauthenticated) |
| features/auth/screens/login_screen.dart                    | Login screen with Google + Email options                                       |
| features/auth/screens/signup_screen.dart                   | Email signup screen                                                            |
| features/auth/screens/profile_screen.dart                  | Profile management, logout                                                     |
| features/auth/widgets/auth_widgets.dart                    | Reusable auth UI components                                                    |
| features/sms/screens/sms_settings_screen.dart              | SMS senders filter, auto-toggle settings                                       |
| features/transactions/bloc/transaction_bloc.dart           | TransactionBloc - add, edit, delete, list                                      |
| features/transactions/bloc/transaction_event.dart          | Transaction events (Load, Add, Update, Delete)                                 |
| features/transactions/bloc/transaction_state.dart          | Transaction states (Loading, Loaded, Error)                                    |
| features/transactions/screens/transaction_list_screen.dart | Full transaction list with filters                                             |
| features/transactions/screens/add_transaction_screen.dart  | Manual add/edit form                                                           |
| features/transactions/widgets/transaction_tile.dart        | Individual transaction card UI                                                 |
| features/goals/bloc/goal_bloc.dart                         | GoalBloc - create, contribute, status update                                   |
| features/goals/bloc/goal_event.dart                        | Goal events (Load, Add, Contribute, Delete)                                    |
| features/goals/bloc/goal_state.dart                        | Goal states (Loading, Loaded, Error)                                           |
| features/goals/screens/goals_list_screen.dart              | All savings goals with progress                                                |
| features/goals/screens/add_goal_screen.dart                | Create new goal form                                                           |
| features/goals/screens/goal_detail_screen.dart             | Goal detail + contribution history                                             |
| features/dashboard/screens/dashboard_screen.dart           | Monthly summary + charts + quick actions                                       |

# **4\. Data Models**

## **4.1 TransactionModel**

| **Field**     | **Type** | **Notes**                              |
| ------------- | -------- | -------------------------------------- |
| **id**        | String   | UUID v4 - Firestore document ID        |
| **amount**    | double   | Transaction amount in NPR              |
| **type**      | enum     | debit or credit                        |
| **source**    | enum     | sms or manual                          |
| **category**  | String   | Auto-assigned or user-selected         |
| **bank**      | String?  | Bank/wallet name from SMS parser       |
| **note**      | String?  | Optional user note or SMS description  |
| **dateAD**    | DateTime | Gregorian transaction date             |
| **dateBS**    | String   | Bikram Sambat date (from calendar kit) |
| **createdAt** | DateTime | Record creation timestamp              |

## **4.2 GoalModel**

| **Field**               | **Type** | **Notes**                            |
| ----------------------- | -------- | ------------------------------------ |
| **id**                  | String   | UUID v4                              |
| **name**                | String   | Goal title e.g. "New Laptop"         |
| **emoji**               | String   | Visual identifier e.g. 🖥️            |
| **targetAmount**        | double   | Total savings needed in NPR          |
| **savedAmount**         | double   | Amount saved so far                  |
| **deadlineAD**          | DateTime | Target date in Gregorian             |
| **deadlineBS**          | String   | Target date in Bikram Sambat         |
| **status**              | enum     | onTrack \| behind \| achieved        |
| **progressPercent**     | double   | Computed: savedAmount / targetAmount |
| **requiredDailyAmount** | double   | Computed: remaining / daysLeft       |

# **5\. Firestore Database Schema**

All user data is scoped under users/{uid}/ to ensure privacy and cross-device sync. Firestore security rules should restrict read/write access to the authenticated owner only.

users/{uid}/ profile: { name, currency, updatedAt } transactions/{txId}: { amount, type, source, category, bank, note, dateAD, dateBS, createdAt } goals/{goalId}: { name, emoji, targetAmount, savedAmount, deadlineAD, deadlineBS, status, createdAt }

## **5.1 Firestore Security Rules**

rules_version = '2'; service cloud.firestore { match /databases/{database}/documents { match /users/{userId}/{document=\*\*} { allow read, write: if request.auth != null && request.auth.uid == userId; } } }

# **6\. SMS Parser**

## **6.1 Supported Banks & Wallets**

| **Bank**  | **Sample SMS Pattern**                                                | **Amount Pattern**   |
| --------- | --------------------------------------------------------------------- | -------------------- |
| **NIMB**  | "AC#050XX2057 Dr by NPR 2500 on 01Dec25" / "Cr by NPR 1600"           | Dr/Cr → debit/credit |
| **NIC**   | "Your 024###32001 has been Credited by NPR 1,013.45 on 14/04/2026"    | Credited/Debited     |
| **ADB**   | "NPR 15,000.00 deposited on 25/03/2026" / "withdrawn on 26/03/2026"   | deposited/withdrawn  |
| **Nabil** | "deposited by NPR 1,500.00 on 06/04/2026" / "withdrawn by NPR 120.00" | deposited/withdrawn  |

## **6.2 How the Parser Works**

- Check sender name against known bank identifiers
- Look for debit/credit keywords in the message body
- Extract NPR amount using regex: NPR {digits} or Rs. {digits}
- Return ParsedSms(amount, type, bank) or null if unrecognized
- Unknown/promotional SMS are silently ignored - no false entries

# **7\. Android Setup - SMS Permissions**

Add the following to android/app/src/main/AndroidManifest.xml inside the &lt;manifest&gt; tag:

&lt;uses-permission android:name="android.permission.READ_SMS"/&gt; &lt;uses-permission android:name="android.permission.RECEIVE_SMS"/&gt;

Request permissions at runtime in Flutter:

import 'package:permission_handler/permission_handler.dart'; future&lt;void&gt; requestSmsPermission() async { await Permission.sms.request(); }

Important: Google Play Store requires a Privacy Policy URL and a declaration explaining why READ_SMS is needed. Prepare this before publishing. The review typically takes 3-7 business days.

# **8\. Auto-Category System**

The Categorizer utility in core/utils/categorizer.dart maps keywords in transaction notes or bank names to categories. This list should be expanded over time based on real user data.

| **Category**        | **Sample Keywords**                                   |
| ------------------- | ----------------------------------------------------- |
| **Food & Dining**   | bhatbhateni, foodmandu, cafe, pizza, momo, restaurant |
| **Transport**       | pathao, indrive, tootle, taxi, bus, petrol, fuel      |
| **Shopping**        | daraz, sastodeal, bigmart, fashion, mall              |
| **Utilities**       | nea, ntc, ncell, broadband, dish home                 |
| **Health**          | hospital, clinic, pharmacy, medical                   |
| **Education**       | school, college, tuition, course, exam fee            |
| **Remittance**      | imepay, western union, money transfer, sent to        |
| **Salary / Income** | salary, payroll, wages, bonus                         |

# **9\. Build Timeline (2 Weeks)**

## **Week 1 - Core**

- Day 1-2: Firebase setup, Auth (Google + Email), Firestore rules
- Day 3-4: TransactionModel, FirebaseService, Hive offline cache
- Day 5-6: SMS parser for all 7 banks, SmsListenerService
- Day 7: Manual add/edit/delete transaction screens

## **Week 2 - Polish**

- Day 8-9: Dashboard - monthly summary, BS/AD toggle
- Day 10: Charts - pie chart by category, bar chart daily spend
- Day 11-12: Savings goals - create, contribute, progress bar
- Day 13: Push notifications - transaction logged, goal achieved
- Day 14: CSV export, testing, bug fixes, README

# **10\. Portfolio Talking Points**

When presenting this project to hirers, highlight:

- SMS parsing pipeline - regex, multi-bank support, graceful fallback
- Offline-first architecture - Hive cache + Firestore sync
- BLoC state management - scalable, testable, production patterns
- Cross-platform considerations - Android SMS vs iOS manual
- Real-world utility - solves a genuine pain point for Nepali users
- Nepali Calendar Kit integration - your own published package
- Savings goal smart calculation - daily savings target algorithm

This project demonstrates: advanced Flutter patterns, Firebase integration, background services, data parsing, chart rendering, and local/remote sync - all in a single coherent product targeting a real market gap.

Built by Gambhir Poudel • gambhirpoudel.com.np
