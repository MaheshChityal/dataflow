# HDFC Data Fusion — Frontend (Flutter Web)

> Production-grade documentation for the Flutter Web application that implements HDFC's **Data Fusion** (also branded *HDFC Data Orchestration* / `DATA FUSION`) platform. Internal project name: **`vizualizer`**.

This document is written so that a developer (or an AI agent) can reproduce the project end-to-end **without access to the original source code**.

---

## Table of Contents

1. [Project Overview](#1--project-overview)
2. [System Architecture](#2--system-architecture)
3. [Tech Stack](#3--tech-stack)
4. [Folder Structure](#4--folder-structure)
5. [Setup Instructions](#5--setup-instructions)
6. [Authentication & Authorization](#6--authentication--authorization)
7. [API Documentation](#7--api-documentation)
8. [Business Logic](#8--business-logic)
9. [Database Design](#9--database-design-inferred-from-api-payloads)
10. [State Management](#10--state-management)
11. [UI/UX Flow](#11--uiux-flow)
12. [Third-party Integrations](#12--third-party-integrations)
13. [Testing](#13--testing)
14. [Deployment](#14--deployment)
15. [Error Handling & Logging](#15--error-handling--logging)
16. [Performance Considerations](#16--performance-considerations)
17. [Security Best Practices](#17--security-best-practices)
18. [Recreate Instructions](#18--recreate-instructions-exact-sequence)
19. [Code-Level Explanation](#19--code-level-explanation-key-functions)
20. [Example Requests & Outputs](#20--example-requests--outputs)
21. [Appendix A — Sample Test Files](#appendix-a--sample-test-files-in-repo)
22. [Appendix B — Known Typos / Quirks](#appendix-b--known-typos--quirks-preserve-for-wire-compat)

---

## 1. 📌 Project Overview

### 1.1 Purpose
**Data Fusion** is a single-page web application built with **Flutter Web** that lets internal HDFC Bank employees visually define, configure, upload, and approve **data pipelines** that merge, join, and transform data from multiple enterprise sources (Manual CSV/Excel, Finacle Core, Laser Banking, Databases, etc.).

### 1.2 Problems It Solves
- **Manual/ad-hoc data merging** across siloed banking systems currently done through spreadsheets and ad-hoc scripts.
- **Lack of visual pipeline authoring** — non-engineers must rely on dev teams to write joins. This tool gives a drag-and-drop canvas (like n8n / Alteryx) for building joins visually.
- **Governance / approvals** — every template (data product) must be reviewed by Unit Head / UAT / SpocManager before going live. The tool enforces this via the **Maker–Checker** flow.
- **Reusable templates** — business users create a template once (sources, join rules, output format, schedule) and operations simply uploads data files per cycle.

### 1.3 Target Users
| Role                    | What they do                                                                 |
| ----------------------- | ---------------------------------------------------------------------------- |
| **Maker (Data Analyst)** | Creates templates, configures pipelines, uploads manual data                 |
| **Checker (Manager)**    | Reviews and approves / rejects uploaded requests                             |
| **Unit Head / SPOC**     | Signs off on the template creation (their approval file is attached)         |
| **Ops users**            | Run manual uploads on a schedule against existing templates                  |

### 1.4 Key Features
1. **Login with refresh-token rotation** (HDFC SSO-backed REST API, 401 auto-refresh).
2. **Template Creation** — multi-section form (General Info / Output Format / Approvals / File Upload) with multipart upload of approval PDFs.
3. **Template Configuration** — drag-and-drop pipeline canvas (zoom/pan via `InteractiveViewer`) with source nodes, join nodes, and output nodes, Bezier edges, port-to-port connection, live join preview.
4. **Join Engine (client-side)** — in-browser execution of INNER / LEFT / RIGHT / FULL OUTER / CROSS joins for live preview.
5. **Source Configuration** — register new data sources in the Source Master.
6. **Manual Upload** — upload one or more CSV/XLSX/TXT/JSON files per template slot.
7. **Checker page** — list incoming maker requests, download their files, approve/reject with remarks.
8. **Offline detection** — blocks outgoing requests when `navigator.onLine` is false (web) / `connectivity_plus` on mobile/desktop.
9. **Secure storage** — tokens persisted via `flutter_secure_storage` (IndexedDB on web, Keychain/Keystore on native).

---

## 2. 🏗️ System Architecture

### 2.1 High-level diagram (textual)
```
┌──────────────────────────────────────────────────────────────────────┐
│                         Browser (Flutter Web)                        │
│  ┌───────────────────────────────────────────────────────────────┐   │
│  │                   MaterialApp (PipelineApp)                   │   │
│  │  scaffoldMessengerKey (global) → SnackBar from ApiService     │   │
│  ├───────────────────────────────────────────────────────────────┤   │
│  │  MultiProvider                                                 │  │
│  │   ├─ ApiService      ← Dio + interceptor (401→refresh→retry) │   │
│  │   ├─ StorageService  ← flutter_secure_storage                │   │
│  │   ├─ AuthService                                              │   │
│  │   ├─ TemplateService                                          │   │
│  │   ├─ PipelineService                                          │   │
│  │   ├─ MasterDataService                                        │   │
│  │   ├─ AuthProvider      (ChangeNotifier)                       │   │
│  │   └─ TemplateProvider  (ChangeNotifier)                       │   │
│  ├───────────────────────────────────────────────────────────────┤   │
│  │  home: auth.isLoggedIn  →  DashboardPage   (drawer nav)       │   │
│  │                      else LoginPage                           │   │
│  └───────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────┘
                                    │  HTTPS / JWT Bearer
                                    ▼
┌──────────────────────────────────────────────────────────────────────┐
│               Backend REST API  (out of scope of this repo)         │
│  Base URL (dev):  http://localhost:8080/api/v1/                      │
│  Base URL (uat):  https://hbenetppuatdb01.hdfcbankuat.com/DataORCAPI/api/ │
│                                                                      │
│  /account/login            (auth)                                    │
│  /account/refresh          (token rotation)                          │
│  /template/*               (master data + CRUD)                      │
│  /auth/logout                                                        │
└──────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
                           Relational database
            (Tables: Users, Templates, TemplateConfig, SourceMaster,
             Departments, Approvals, ManualUploads, CheckerTasks, …)
```

### 2.2 Interaction / Data Flow (step-by-step)
1. User loads `/` → Flutter bootstrapper mounts `PipelineApp`.
2. `AuthProvider._tryAutoLogin()` runs: calls `StorageService.loadSession()` → if a token exists, sets it on `ApiService` and flags `isLoggedIn = true`.
3. If not logged in, `LoginPage` submits `POST /account/login` (via `AuthService.login`) → stores session via `StorageService.saveSession()`.
4. `DashboardPage` shows a drawer with six sections. Default landing = Welcome.
5. User opens **Template Creation** → form fires parallel `GET` master-data calls: `GetDepartment`, `GetApprovalList`, `GetSourceMasterList`. User fills the form + attaches approval files.
6. Submit → `TemplateService.createTemplate()` → `POST /template/AddTemplate` as `multipart/form-data` containing a JSON field `TemplateRuequest` and zero-or-more `Files`.
7. Backend returns `{status:"Success", reqID:"7"}`.
8. User opens **Template Configuration** → selects dept, template → drags sources from the palette onto the canvas → configures each (file + columns + separator), confirms each.
9. When all sources are confirmed, the JOIN palette item unlocks → user drags it in, wires edges, chooses column mappings.
10. Output node is dropped, format picked (`csv` / `xlsx` / `pipe` / `json`), columns/aliases/filters/sort set.
11. User hits **Submit Mapping** → `PipelineService.submitMapping()` → `POST /template/AddTemplateConfig` as `multipart/form-data`. Response: `{templateId, configId}`.
12. At run-time, Ops uses **Manual Upload** to upload data for that template; Checker approves it.

### 2.3 Error & resilience flow
- `Dio` interceptor: every request is logged; on `401` the interceptor:
  1. Uses a mutex (`_isRefreshing`) so only one refresh runs.
  2. Calls the injected `refreshFn` (reads stored refresh token + employeeCode, `POST /account/refresh`).
  3. On success: sets new token, wakes waiters, retries the original request.
  4. On failure: invokes `showMessage("Session expired. Please login again.")`, calls `logoutFn` (if configured), returns a synthetic 401.
- Offline guard: any `get/post/put/delete/postMultipart` first calls `_hasConnection()`. On web this reads `window.navigator.onLine`; on native it uses `connectivity_plus`.

---

## 3. 🧩 Tech Stack

| Layer               | Technology                                                                                           | Why                                                                           |
| ------------------- | ---------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| Language            | Dart `^3.9.2`                                                                                        | Flutter's native language                                                     |
| Framework           | Flutter (Material 3) — Flutter SDK                                                                   | Single codebase for web/mobile/desktop; rich layout engine                    |
| Runtime target      | **Flutter Web** (Canvas/Skia renderer)                                                               | Banking-internal web app                                                      |
| State management    | `provider ^6.1.0` (`ChangeNotifier` + `ChangeNotifierProxyProvider`)                                 | Lightweight, no boilerplate, idiomatic                                        |
| HTTP client         | `dio ^5.7.0`                                                                                         | Interceptors (401 retry), multipart, cancellation                             |
| Secure storage      | `flutter_secure_storage ^9.2.2` (web IndexedDB with `WebOptions(dbName: 'hdfc_pipeline')`)           | Persist JWT tokens + session                                                  |
| File picker         | `file_picker ^6.1.1`                                                                                 | Cross-platform file chooser for CSV/XLSX                                      |
| Connectivity        | `connectivity_plus ^6.1.4`                                                                           | Native offline detection                                                      |
| Web interop         | `web ^1.1.1`                                                                                         | `navigator.onLine` on web, Blob download trigger                              |
| Lints               | `flutter_lints ^5.0.0`                                                                               | Project-standard lint set                                                     |
| Testing             | `flutter_test` (SDK)                                                                                 | Widget tests                                                                  |
| Fonts (declared)    | `DM Sans` (UI) and `JetBrainsMono` (tabular/code)                                                    | Brand-consistent typography                                                   |

---

## 4. 📁 Folder Structure

```
frontend/
├── README.md
├── analysis_options.yaml              # Lint config (uses flutter_lints/analysis_options.yaml)
├── devtools_options.yaml
├── pubspec.yaml                       # Package manifest (see §3)
├── pubspec.lock
├── vizualizer.iml                     # IntelliJ project file
├── .metadata                          # Flutter scaffold metadata
├── assets/
│   └── images/
│       └── HDFC_Bank_Logo.svg.png     # Logo used in login + drawer + dashboard
├── test_files/                        # Sample data files used for QA
│   ├── valid_columns.csv
│   ├── valid_columns_pipe.txt
│   ├── valid_query.txt
│   ├── valid_query_with.txt
│   ├── invalid_columns_paragraph.txt
│   ├── invalid_columns_raw_numbers.csv
│   ├── invalid_columns_sentence_headers.csv
│   ├── invalid_query_numbers.txt
│   └── invalid_query_paragraph.txt
├── web/
│   ├── index.html                     # Flutter bootstrap host; title="DATA FUSION"
│   ├── manifest.json                  # PWA manifest (name/short_name/icons)
│   ├── favicon.png
│   └── icons/                         # 192 / 512 px PWA icons (+ maskable variants)
├── test/
│   └── login_page_test.dart           # Widget tests for LoginPage using mock AuthProvider
└── lib/
    ├── main.dart                      # Entrypoint, DI wiring, MaterialApp, global scaffoldMessengerKey
    ├── config/
    │   └── api_config.dart            # baseUrl + endpoint constants
    ├── theme/
    │   └── app_theme.dart             # AppColors + AppTextStyles
    ├── models/                        # Pure data classes (toJson/fromJson)
    │   ├── api_response.dart
    │   ├── login_request.dart
    │   ├── login_response.dart
    │   ├── master_models.dart
    │   ├── template_info.dart
    │   ├── template_request.dart
    │   ├── pipeline_models.dart
    │   └── pipeline_config.dart
    ├── services/                      # Thin HTTP wrappers (stateless callers of ApiService)
    │   ├── api_service.dart
    │   ├── auth_service.dart
    │   ├── storage_service.dart
    │   ├── template_service.dart
    │   ├── pipeline_service.dart
    │   └── master_data_service.dart
    ├── providers/                     # ChangeNotifier glue
    │   ├── auth_provider.dart
    │   ├── template_provider.dart
    │   └── pipeline_master_provider.dart
    ├── controllers/
    │   └── pipeline_controller.dart   # In-memory pipeline state machine (nodes/edges, drag ports, join execution)
    ├── utils/
    │   ├── join_engine.dart           # Pure function JoinEngine.execute() — INNER/LEFT/RIGHT/FULL/CROSS
    │   ├── connectivity_check_stub.dart
    │   ├── connectivity_check_web.dart
    │   ├── file_download_stub.dart
    │   └── file_download_web.dart
    ├── pages/
    │   ├── login_page.dart
    │   ├── dashboard_page.dart
    │   ├── welcome_page.dart
    │   ├── template_creation_page.dart
    │   ├── template_configuration_page.dart
    │   ├── configuration_upload_page.dart
    │   ├── source_configuration_page.dart
    │   ├── manual_upload_page.dart
    │   └── checker_page.dart
    └── widgets/
        ├── top_bar.dart
        ├── sidebar.dart
        ├── status_bar.dart
        ├── config_panel.dart
        ├── source_preview_sidebar.dart
        ├── mapping_preview_dialog.dart
        ├── pipeline_canvas_page.dart
        ├── edge_painter.dart
        └── nodes/
            ├── source_node_body.dart
            ├── join_node_body.dart
            └── output_node_body.dart
```

### File-by-file role map

- **`lib/main.dart`** — Creates service singletons, wires the `ApiService.configure()` callbacks (message + refresh), builds the `MultiProvider`, and returns `PipelineApp` which picks `LoginPage` or `DashboardPage` based on `AuthProvider`.
- **`lib/config/api_config.dart`** — Single source of truth for the base URL and every endpoint string.
- **`lib/services/api_service.dart`** — The HTTP backbone. Handles 401 refresh, multipart uploads, offline detection, raw GET/POST.
- **`lib/controllers/pipeline_controller.dart`** — Canvas-state machine. Owns `nodes`, `edges`, drag state, executes joins recursively, auto-fixes edge direction (join → source swaps to source → join).
- **`lib/utils/join_engine.dart`** — Pure SQL-style join implementation (no I/O). Used for live preview and by the Output node to compose the final dataset.

Full model catalogue inside `lib/models/`:
- `api_response.dart` — Generic `ApiResponse<T>` + `SubmitMappingResponse` + `CreateTemplateResponse` + `AddSourceMasterResponse` + `TemplateListItem`.
- `login_request.dart` — `LoginRequest` (14 fields) with `_staticEmployeeCode='n2346'`.
- `login_response.dart` — `LoginUser` + `LoginResponse`.
- `master_models.dart` — `DepartmentItem`, `ApprovalItem`, `SourceTypeItem`, `SourceMasterItem`, `SourceMasterFilterItem`, `SourceListItem`, `OperationItem`.
- `template_info.dart` — `ManualTemplateInfo` + `TemplateInfo`.
- `template_request.dart` — `TemplateRequest` (create) with nested `Template[]` / `OutputFormats` / `Approvals`.
- `pipeline_models.dart` — `NodeType` enum + `NodeTypeExt` + `DragNodeData` + `ColumnMapping` + `OutputFilter` + `OutputSort` + `PipelineNode` + `PipelineEdge`.
- `pipeline_config.dart` — Hardcoded `templatesByDept` / `templateSourceCount` / `joinTypes` + demo data.

---

## 5. ⚙️ Setup Instructions

### 5.1 Prerequisites
- **Flutter SDK** ≥ 3.35 (Dart `^3.9.2`) — `flutter --version` must report a Dart that satisfies `^3.9.2`.
- **Chrome** or **Edge** (for `flutter run -d chrome`).
- Backend API reachable at `http://localhost:8080/api/v1/` (dev default) or the UAT URL commented in `api_config.dart`.
- Optional: **Android Studio / VS Code** with the Flutter plugin for debugging.

### 5.2 Installation
```bash
cd frontend
flutter pub get                   # Installs pubspec dependencies
flutter run -d chrome             # Launches local dev server (~port 5000-5999)
# or
flutter build web --release       # Produces build/web/ for deployment
```

### 5.3 Environment variables
This project does **not** use `.env` files. All environment-specific values live in `lib/config/api_config.dart`:

```dart
// lib/config/api_config.dart
class ApiConfig {
  // Dev
  static const String baseUrl = 'http://localhost:8080/api/v1/';
  // UAT (uncomment to use)
  // static const String baseUrl = 'https://hbenetppuatdb01.hdfcbankuat.com/DataORCAPI/api/';
  …
}
```
Switch environments by editing that one line before `flutter build web`.

#### Sample `.env`-style override (if you decide to introduce `flutter_dotenv`)
```env
API_BASE_URL=http://localhost:8080/api/v1/
ENV=dev
```

---

## 6. 🔐 Authentication & Authorization

### 6.1 Flow
1. **Login page** collects `username` + `password` (no signup screen — HDFC SSO/backend-issued credentials).
2. `AuthProvider.login()` builds a `LoginRequest` and calls `AuthService.login()` → `POST {base}/account/login`.
3. On success the response (`{ token, refreshToken, user: {...} }`) is saved via `StorageService.saveSession()` (encrypted IndexedDB on web using `flutter_secure_storage`'s `WebOptions(dbName:'hdfc_pipeline', publicKey:'hdfc_key')`).
4. The access token is set on `ApiService` (`_authToken`) and attached as `Authorization: Bearer <token>` to every subsequent request.
5. On cold reload, `AuthProvider._tryAutoLogin()` re-hydrates the session before UI is shown.
6. **Logout** (`AuthProvider.logout()`) → `POST /auth/logout` → clears all secure storage keys and token, navigates to `/login`.

### 6.2 Token refresh (silent)
Implemented entirely inside `ApiService`'s Dio interceptor `onError`:
- If `status == 401` AND the request path does **not** contain `login` / `refresh` AND we haven't already retried, run `_performTokenRefresh()`.
- Refresh body:
  ```json
  {
    "token": "<stored-refresh-token>",
    "userId": "<employeeCode>",
    "expiryDate": "",
    "isRevoked": false
  }
  ```
- Response gives `accessToken` / `refreshToken` → persisted via `StorageService.updateTokens()`. The retry attaches the new token and resolves the original request. Waiters block on a `Completer<void>` queue so only one refresh at a time.

### 6.3 Roles
The `LoginUser` model carries `role`, `department`, `profileDescription`, `profileId`. In the current UI the app simply gates by `isLoggedIn`. Roles are carried server-side and influence what data the backend returns (e.g. Checker only sees pending requests for their department).

### 6.4 Storage keys
`StorageService` (`flutter_secure_storage`) keys:

| Key                     | Value                                             |
| ----------------------- | ------------------------------------------------- |
| `auth_token`            | JWT access token                                  |
| `auth_refresh_token`    | Refresh token                                     |
| `auth_user`             | JSON-encoded `LoginUser`                          |
| `nav_page_index`        | Last selected drawer index (int as string)        |

---

## 7. 🌐 API Documentation

All endpoints are relative to `ApiConfig.baseUrl` (`http://localhost:8080/api/v1/` by default). All authenticated requests carry `Authorization: Bearer <token>` (except the two auth endpoints). Content type defaults to `application/json`; multipart endpoints are explicitly called out.

### 7.1 `POST account/login`
Sign in.

- **Headers:** `Content-Type: application/json`
- **Body (LoginRequest):**
```json
{
  "Id": 0,
  "Name": "admin",
  "EmployeeCode": "n2346",
  "Email": "",
  "password": "admin123",
  "Location": "",
  "LOCATIONCODE": "",
  "City": "",
  "Department": "",
  "ContactNumber": "",
  "Role": "",
  "IPAddress": "",
  "ProfileDescription": "",
  "ProfileId": ""
}
```
- **200 OK response (LoginResponse):**
```json
{
  "token": "eyJhbGciOi…",
  "refreshToken": "abc123…",
  "user": {
    "id": 7,
    "name": "Amit Sharma",
    "employeeCode": "n2346",
    "email": "amit@hdfcbank.com",
    "location": "Mumbai Corp Office",
    "locationcode": "MUM01",
    "city": "Mumbai",
    "department": "Finance",
    "contactNumber": "9900990099",
    "role": "1",
    "ipAddress": "10.0.0.1",
    "profileDescription": "Maker",
    "profileId": "P-100"
  }
}
```
- **401 / 500:** `{ "message": "Invalid credentials" }`
- **Internal flow:** `LoginPage._submit → AuthProvider.login → AuthService.login → ApiService.post → StorageService.saveSession → setToken → AuthProvider.notifyListeners → MaterialApp rebuild shows DashboardPage`.

### 7.2 `POST account/refresh`
Rotate access token. Not called directly by UI — only by the interceptor on 401.

- **Body:**
```json
{ "token": "<refresh>", "userId": "n2346", "expiryDate": "", "isRevoked": false }
```
- **Response:** `{ "accessToken": "…", "refreshToken": "…" }`

### 7.3 `POST auth/logout`
Invalidate session server-side. Empty body.

### 7.4 Master data endpoints (all GET unless noted)

| Endpoint                                            | Query params                       | Purpose                                                | Returns (shape)                                                                                     |
| --------------------------------------------------- | ---------------------------------- | ------------------------------------------------------ | --------------------------------------------------------------------------------------------------- |
| `template/GetDepartment`                            | —                                  | Department list                                        | `[{ "dpt_Id": 1, "dpt_Name": "Finance" }, …]`                                                      |
| `template/GetApprovalList`                          | —                                  | Approval types                                         | `[{ "id": 1, "approvalName": "Unit Head" }, …]`                                                    |
| `template/GetSourceType`                            | —                                  | Palette source types (DB / Manual / FC / Laser / API)  | `[{ "id": 2, "sourceName": "Finacle Core", "sourceValue": "FC", "sourceType": 3 }, …]`             |
| `template/GetOperations`                            | —                                  | Join/filter operators                                  | `[{ "id": 1, "operationName": "Equal", "operationValue": "=" }, …]`                                |
| `template/GetSourceMasterList`                      | —                                  | All registered sources                                 | List of `SourceMasterItem`                                                                         |
| `template/GetSourceMasterListFilterwise` (POST)     | body `{template_id, department_id}` | Filtered source master for canvas                      | Same shape as above, filtered                                                                      |
| `template/GetTemplates?deptId=<id>`                 | `deptId`                           | Templates for a dept                                   | List of `TemplateInfo`                                                                             |
| `template/GetManualTemplateDetails?DeptId=<id>`     | `DeptId`                           | Templates for manual upload                            | `[{ "templateId": 10, "templateName":"Daily MIS", "sourceCount":3, "manualCount":2 }, …]`          |
| `template/GetSourceList?DeptId=<id>&TemplateId=<id>` | Both required                      | Sources wired up to a template                         | `[{ "id": 3, "s_Name": "Branch Txn CSV" }, …]`                                                     |
| `template/GetCheckerTayList` (POST)                 | body `{template_id, department_id, Request_id}` | Tasks to be approved                        | List of arbitrary row maps (the Checker page renders up to 8 columns)                              |

### 7.5 Mutation / upload endpoints

#### `POST template/AddTemplate` (multipart/form-data)
- **Field** `TemplateRuequest` (yes, typo preserved): stringified JSON — see `TemplateRequest.toJson()`:
```json
{
  "Template": [{
    "TemplateName": "Daily MIS",
    "Department": "Finance",
    "Frequency": "Daily",
    "NormalVolume": 500,
    "PeakVolume": 1200,
    "SourceCount": 3,
    "NumberOfOutputs": 2,
    "BenefitType": "Cost Saving",
    "BenefitAmount": 15000,
    "BenefitInTat": "2 days",
    "GoLiveDate": "2026-05-01",
    "DeactivateDate": null,
    "SpocPerson": "Amit Sharma",
    "SpocManager": "R. Menon",
    "UnitHead": "S. Iyer",
    "Priority": "High",
    "SourceList": "5,9,17"
  }],
  "OutputFormats": [{ "TemplateTempId": null, "FormatName": "Unimailing" }],
  "Approvals": [{ "TemplateTempId": null, "Approval_Type": "Unit Head", "ApprovalFile": "approval_uh.pdf" }]
}
```
- **Files:** zero or more under field key `Files`.
- **Response:** `{ "status": "Success", "reqID": "7" }`

#### `POST template/AddTemplateConfig` (multipart/form-data)
- **Field** `TemplateConfig`: stringified pipeline payload composed by `widgets/nodes/join_node_body.dart`.
- **Files:** any uploaded source column or query files, sent under field key `Files`.
- **Response:** `{ "templateId": 7, "configId": 12 }`.

#### `POST template/AddSourceMasterList` (JSON)
- **Body:**
```json
{ "sourceType":"2","AppName":"CoreDB","ITGRC":5001,"Name":"Customer DB","DBVault":"VLT-01","Createdby":"n2346","department_id":1 }
```
- **Response:** `{ "status":"Success","reqID":17 }`

#### `POST template/UploadManualData` (multipart/form-data)
- **Field** `ManualFileUploadList`: `{"manualFileUploadslist":[{Template_id,department_id,source_id,filename,createdBy}, …]}`
- **Files:** each file under field key `Files`
- **Response:** `{ "status":"Success","reqID":123 }`

#### `POST template/UploadManualDataChecker` (JSON)
Checker approve / reject:
```json
{ "Template_id":"10","department_id":"1","Request_id":"123","CheckerBy":"n2000","Remart":"Looks good","isApproved":"Y" }
```
Response: `{ "status":"Success","reqID":123 }`

#### `GET template/DownloadFile?filename=…&template_id=…`
Streams file bytes (`responseType: bytes`). On web, `utils/file_download_web.dart` builds a Blob and triggers an `<a download>`.

### 7.6 Status codes
- `200` — ok
- `401` — expired/invalid token → handled by interceptor
- `400` — validation error; body contains `{message: "..."}`.
- `500` — server error; UI surfaces a red SnackBar.

### 7.7 Internal function flow (representative example: Create Template)
```
TemplateCreationPage._save()
 └── TemplateProvider.saveTemplate(model, fileBytes, fileNames)
      └── TemplateService.createTemplate(request, approvalFileBytes, approvalFileNames)
           └── ApiService.postMultipart(
                 ApiConfig.templateCreateEndpoint,
                 fields: {'TemplateRuequest': jsonEncode(request.toJson())},
                 fileEntries: [(key:'Files', bytes, filename), …],
                 fromData: CreateTemplateResponse.fromJson,
               )
                ├── _offlineGuard()                  # aborts if offline
                ├── Dio.post(..., contentType:'multipart/form-data; boundary=...')
                ├── Interceptor attaches Authorization header
                ├── _handleResponse → ApiResponse<CreateTemplateResponse>
                └── Returns to provider → success → reqId shown in dialog
```

---

## 8. 🧠 Business Logic

### 8.1 Template lifecycle (Maker → Checker → Ops)
```
TemplateCreation ──► /template/AddTemplate  ── returns reqID
        │
        ▼
TemplateConfiguration (canvas build + submit mapping) ──► /template/AddTemplateConfig
        │
        ▼
(Backend marks template active)
        │
        ▼
ManualUpload   ──► /template/UploadManualData  (Ops user)
        │
        ▼
Checker page   ──► /template/GetCheckerTayList  (Manager searches)
        │
        ├─► /template/DownloadFile         (review artefacts)
        └─► /template/UploadManualDataChecker   (approve / reject)
```

### 8.2 Pipeline controller state machine (`lib/controllers/pipeline_controller.dart`)
Each canvas has three coordinated states:
1. **Sidebar state** — `sidebarDept`, `sidebarTemplate`, `sidebarTemplateId`, `requiredSourceCount`.
2. **Graph state** — `nodes: List<PipelineNode>`, `edges: List<PipelineEdge>`, plus `selectedNodeId` / `selectedEdgeId`.
3. **Port drag state** — `portDragFromNodeId`, `portDragCurrentPos` (used by `EdgePainter` to draw a live line).

Key invariants enforced:
- **`canAddSource`** — `sidebar.requiredSourceCount` caps how many source nodes can be on the canvas.
- **`allSourceNodesConfirmed`** — true only when (count met) AND (every source `confirmState == confirmed`). Join palette is unlocked based on this.
- **`shouldAnimateJoin`** — pulses the join palette item after all sources are confirmed but before a join exists.
- **Edge auto-direction** — `addEdge` swaps endpoints so join can never be a source of an edge that leads to a source node.
- **Join resync** — whenever an edge is added or removed on a join node, `_syncJoinSources()` rebinds `leftSrcId` / `rightSrcId` to the first two incoming edges and seeds an empty `ColumnMapping`.
- **Recursive join execution** — `getNodeRows()` handles chained joins (`join1 → join2 → output`).
- **Output pipeline order** — `getOutputResult()` does `filter → sort → select → alias`, matching SQL `WHERE → ORDER BY → SELECT AS`.

### 8.3 Join engine (`lib/utils/join_engine.dart`)
Pure deterministic function:
- **INNER JOIN** — cartesian filtered by mapping equality.
- **LEFT JOIN** — keeps every left row; fills right with `—` when nothing matches.
- **RIGHT JOIN** — symmetric.
- **FULL OUTER JOIN** — tracks matched-right indices; appends unmatched from either side.
- **CROSS JOIN** — cartesian product.

All string comparison (`'${lr[col]}' == '${rr[col]}'`). Multiple `ColumnMapping`s are AND'ed.

### 8.4 Output processing pipeline (Output node)
1. Gather rows from the single incoming edge (join or source).
2. Deduplicate column names across all rows.
3. Auto-populate `outputSelectedCols` on first render.
4. Apply WHERE via `OutputFilter.matches(row)` — supports `= != > < >= <= contains starts with`.
5. Apply ORDER BY via `sortRules` (numeric compare if both sides parse as double, else string compare, flipped when `ascending == false`).
6. Apply `columnAliases` (`{originalName: "Renamed"}`).
7. Return `{cols: displayCols, rows: finalRows, allCols, totalBeforeFilter}`.

### 8.5 Edge cases handled
- **Empty mappings** → join engine returns `[]`; `diagnoseOutputIssue()` surfaces human-readable errors.
- **Sources without uploaded data** → output node shows `Upload data rows in <name>`.
- **Missing connection to output** → diagnostic says "Connect at least 2 sources to JOIN".
- **Duplicate edge** — `addEdge` is idempotent.
- **Offline** — network calls blocked with `No internet connection. Please check your network.`
- **Concurrent 401s** — all queued behind one refresh via `_refreshWaiters`.
- **Login refresh loop** — endpoints containing `login` or `refresh` skip 401 handling.
- **Missing employeeCode** — defaulted to `'n2346'` static constant (pending SSO wiring — see `LoginRequest._staticEmployeeCode`).

---

## 9. 🗄️ Database Design (inferred from API payloads)

> The backend is out of scope of this repo, but the schema is fully implied by the request/response shapes. Here is the reference model.

### 9.1 Tables / Collections

**Users**

| Column | Type | Notes |
| - | - | - |
| id | INT PK | |
| name | VARCHAR(120) | |
| employeeCode | VARCHAR(20) UNIQUE | e.g. `n2346` |
| email | VARCHAR(150) | |
| password_hash | VARCHAR | bcrypt / Argon2 |
| location | VARCHAR(80) | |
| locationCode | VARCHAR(20) | |
| city | VARCHAR(80) | |
| departmentId | INT FK → Departments | |
| contactNumber | VARCHAR(15) | |
| role | VARCHAR(20) | `Maker`/`Checker`/`Admin` |
| ipAddress | VARCHAR(40) | |
| profileDescription | VARCHAR(80) | |
| profileId | VARCHAR(20) | |

**Departments**  (`dpt_Id`, `dpt_Name`)

**Approvals master**  (`id`, `approvalName`) — e.g. Unit Head, UAT Sign Off, SpocManager.

**SourceTypes**  (`id`, `sourceName`, `sourceValue`, `sourceType`) — where `sourceType` is 1=Manual, 2=QRS, 3=FC (see `SourceMasterItem.sourceTypeLabel`).

**SourceMaster**

| Column | Type | Notes |
| - | - | - |
| id | INT PK | |
| name | VARCHAR(120) | |
| sourceType | INT FK | |
| appName | VARCHAR(80) | |
| itgrc | INT | ITGRC reference |
| dbVault | VARCHAR(40) | |
| createdBy | VARCHAR(20) | employeeCode |
| department_id | INT FK | |

**Operations**  (`id`, `operationName`, `operationValue`) — comparison operators for filters/joins.

**Templates**

| Column | Type |
| - | - |
| templateId | INT PK |
| templateName | VARCHAR(120) |
| department | VARCHAR(80) / INT FK |
| frequency | ENUM(Daily/Weekly/…/On-Demand) |
| sourceCount | INT |
| numberOfOutputs | INT |
| normalVolume | INT |
| peakVolume | INT |
| priority | ENUM(Low/Medium/High/Critical) |
| benefitType | VARCHAR |
| benefitAmount | DECIMAL |
| benefitInTAT | VARCHAR |
| goLiveDate | DATE NULLABLE |
| deactivateDate | DATE NULLABLE |
| spocPerson | VARCHAR |
| spocManager | VARCHAR |
| unitHead | VARCHAR |
| status | ENUM(Pending/Active/Revoked) |
| createdAt | TIMESTAMP |

**Template_OutputFormats**  (`id`, `templateId` FK, `formatName`) — 1:N.

**Template_Approvals**  (`id`, `templateId` FK, `approval_Type`, `approvalFile`) — stores file paths.

**Template_Sources** (join table) — (`templateId`, `sourceId`) composite PK → from `SourceList: "5,9,17"`.

**TemplateConfig** (pipeline layout + mappings)

| Column | Type |
| - | - |
| configId | INT PK |
| templateId | INT FK |
| payloadJson | TEXT | Full JSON from `PipelineService.submitMapping` |
| createdBy | VARCHAR |
| createdAt | TIMESTAMP |

**ManualUpload**

| Column | Type |
| - | - |
| reqId | INT PK |
| templateId | INT FK |
| departmentId | INT FK |
| sourceId | INT FK → SourceMaster |
| filename | VARCHAR |
| filePath | VARCHAR |
| createdBy | VARCHAR |
| status | ENUM(Pending, Approved, Rejected) |
| checkerBy | VARCHAR NULLABLE |
| remark | VARCHAR NULLABLE |
| createdAt | TIMESTAMP |

### 9.2 Relationships
- `Templates.department` → `Departments.dpt_Id` (N:1).
- `Template_OutputFormats.templateId`, `Template_Approvals.templateId`, `Template_Sources.templateId` → `Templates.templateId` (1:N).
- `Template_Sources.sourceId` → `SourceMaster.id` (N:1).
- `ManualUpload.templateId` → `Templates.templateId`; `ManualUpload.sourceId` → `SourceMaster.id`.

### 9.3 Sample data
```json
{
  "Departments":  [{"dpt_Id":1,"dpt_Name":"Finance"},{"dpt_Id":2,"dpt_Name":"Operations"}],
  "SourceTypes":  [{"id":1,"sourceName":"Manual Upload","sourceValue":"Manual","sourceType":1},
                   {"id":3,"sourceName":"Finacle Core","sourceValue":"FC","sourceType":3}],
  "SourceMaster": [{"id":5,"name":"Customer DB","sourceType":3,"appName":"CoreDB","itgrc":5001,"dbVault":"VLT-01","createdBy":"n2346","department_id":1}],
  "Templates":    [{"templateId":10,"templateName":"Daily MIS","department":"Finance","frequency":"Daily","sourceCount":3,"numberOfOutputs":2,"status":"Active"}]
}
```

---

## 10. 🔄 State Management

### 10.1 Scheme
- **`provider` package**, specifically `ChangeNotifier` + `ChangeNotifierProxyProvider{n}` where a provider depends on services.
- Services and providers are created **once** in `main.dart` and passed to a `MultiProvider`.
- `PipelineController` and `PipelineMasterProvider` are **scoped** — they are created in `TemplateConfigurationPage` so they reset every time you enter that screen.

### 10.2 Provider topology
```
MultiProvider
├── Provider<ApiService>.value           (created eagerly in main)
├── Provider<StorageService>.value
├── Provider<AuthService>.value
├── Provider<TemplateService>
├── Provider<PipelineService>
├── Provider<MasterDataService>
├── ChangeNotifierProxyProvider2<AuthService, StorageService, AuthProvider>
└── ChangeNotifierProxyProvider<TemplateService, TemplateProvider>

scope: TemplateConfigurationPage
└── MultiProvider
    ├── ChangeNotifierProvider<PipelineController>
    └── ChangeNotifierProvider<PipelineMasterProvider>(lazy: false)
```

### 10.3 Data flow between components
- UI widgets use `context.read<X>()` for one-shot reads, `context.watch<X>()` / `Consumer<X>` to rebuild when `notifyListeners()` fires.
- `PipelineCanvasPage` wraps the canvas in a `Consumer<PipelineController>`. `Sidebar`, `ConfigPanel`, `StatusBar`, `TopBar` independently subscribe so each rebuilds only when relevant.
- `EdgePainter` passes `super(repaint: ctrl)` — `CustomPainter` repaints automatically whenever the controller notifies.

---

## 11. 🖥️ UI/UX Flow

### 11.1 Screen map

| # | Screen                              | Purpose                                                                 |
| - | ----------------------------------- | ----------------------------------------------------------------------- |
| 0 | **LoginPage**                       | Username/password → `/dashboard`                                        |
| 1 | **DashboardPage**                   | Drawer host + AppBar with user avatar / logout                          |
|   | ├─ **WelcomePage**                  | Default landing (blue gradient banner with user info)                   |
|   | ├─ **TemplateCreationPage**         | Multi-section form to create a template                                 |
|   | ├─ **TemplateConfigurationPage**    | Visual pipeline canvas                                                  |
|   | ├─ **SourceConfigurationPage**      | Register a new data source                                              |
|   | ├─ **ManualUploadPage**             | Upload manual CSV/XLSX files against a template                         |
|   | └─ **CheckerPage**                  | Approve/reject uploaded requests                                        |

### 11.2 User journey (Maker happy path)
1. **Login** → dashboard lands on Welcome (because `savePageIndex(0)` is called on every fresh login).
2. Open drawer → **Template Creation** → fill name/dept/frequency/volumes/source-count/outputs; pick approvals; upload a PDF per approval; **Save Template** → success dialog shows `reqID`.
3. Drawer → **Source Configuration** (if a new source is needed) → pick dept + source type + fill ITGRC/DB Vault → **Save Source**.
4. Drawer → **Template Configuration** → pick dept + template (this populates `requiredSourceCount`) → drag source palette items onto the canvas; click each to open the right-side **ConfigPanel** → enter name / separator / upload CSV / upload query → **Confirm**.
5. When all sources confirmed, Join palette item glows → drag it onto canvas. Wire sources → join → drop an Output node. Set column mappings in the join body; configure the output (format, selected columns, aliases, filters, sort).
6. Click **Submit** inside the join node → **Mapping Preview dialog** appears with a 5-step review (Sources, Joins, Output, Files, Confirm) → **Submit** button calls `PipelineService.submitMapping()`.

### 11.3 User journey (Ops)
1. Drawer → **Manual Upload** → pick dept → pick template (shows `manualCount` slots) → attach a file per slot → **Save**.

### 11.4 User journey (Checker)
1. Drawer → **Checker** → pick dept + template + enter Request ID → **Fetch** → paginated results table.
2. Per row: download file, enter remark, tap **Approve** or **Reject**.

### 11.5 Visual language
- **Primary blue:** `0xFF2563EB`, HDFC accent blue `0xFF004C8F`, green `0xFF059669`, amber `0xFFD97706`, red `0xFFDC2626`, violet `0xFF7C3AED`.
- Fonts: `DM Sans` (UI), `JetBrainsMono` (tables, IDs).
- Rounded-12 cards on a light slate background (`0xFFF1F5F9`).
- All dropdowns are `OverlayEntry`-based (not Material `DropdownButton`) with a search input and `CompositedTransformFollower` for positioning.

---

## 12. 🔗 Third-party Integrations

### 12.1 HDFC Data Orchestration API
Single external dependency. All details in §7. No OAuth, just username/password + Bearer JWT. CORS must allow the deployed origin.

### 12.2 `flutter_secure_storage`
Configured with `WebOptions(dbName: 'hdfc_pipeline', publicKey: 'hdfc_key')` so the IndexedDB namespace is deterministic.

### 12.3 `dio`
Wired once (`ApiService` constructor) with `baseUrl`, `contentType`, connect/receive/send timeouts (60s debug / 120s release). A single `InterceptorsWrapper` handles logging, header injection, and 401 retries.

### 12.4 `connectivity_plus`
Used only on native platforms. On the Flutter Web build, the conditional import (`dart.library.html` / `package:web`) replaces it with `navigator.onLine`.

### 12.5 `package:web`
- `utils/connectivity_check_web.dart` → `web.window.navigator.onLine`.
- `utils/file_download_web.dart` → creates a Blob, uses `URL.createObjectURL`, and clicks a hidden `<a download>` to trigger downloads of checker files.

Example snippet:
```dart
final blob = web.Blob(jsBytes, web.BlobPropertyBag(type:'application/octet-stream'));
final url  = web.URL.createObjectURL(blob);
final a    = web.document.createElement('a') as web.HTMLAnchorElement
  ..href = url ..download = filename;
web.document.body!.appendChild(a); a.click(); web.document.body!.removeChild(a);
web.URL.revokeObjectURL(url);
```

---

## 13. 🧪 Testing

### 13.1 What exists
- `test/login_page_test.dart` — 18 widget tests for `LoginPage`, covering:
  - Rendering (title, fields, visibility toggle, footer).
  - Validation (empty fields, whitespace-only).
  - Success path (navigates to `/dashboard`, shows loading indicator, disables button).
  - Failure path (custom error SnackBar, fallback "Login failed", can retry).
  - Keyboard submission (Enter on password submits).

### 13.2 How to run
```bash
flutter test                         # runs all tests in test/
flutter test --coverage              # emits coverage/lcov.info
```

### 13.3 Example test case
```dart
testWidgets('navigates to /dashboard on successful login', (tester) async {
  await tester.pumpWidget(buildLoginPage(MockAuthProvider(loginResult: true)));
  await tester.enterText(find.byType(TextField).first, 'admin');
  await tester.enterText(find.byType(TextField).last, 'admin123');
  await tester.tap(find.text('Sign In').last);
  await tester.pumpAndSettle();
  expect(find.text('Dashboard'), findsOneWidget);
});
```

### 13.4 Suggested additions (to round out coverage)
- Unit tests for `JoinEngine.execute` — each of the 5 join types with matching and non-matching rows.
- Unit tests for `PipelineController.addEdge` auto-direction correction and `syncJoinSources`.
- Integration tests for `ApiService` 401-refresh flow using `DioAdapter` / `http_mock_adapter`.
- Golden tests for `SourceNodeBody`, `JoinNodeBody`, `OutputNodeBody`.

### 13.5 Sample API test (curl)
```bash
# Login
curl -X POST http://localhost:8080/api/v1/account/login \
 -H 'Content-Type: application/json' \
 -d '{"Name":"admin","password":"admin123","EmployeeCode":"n2346","Id":0,"Email":"","Location":"","LOCATIONCODE":"","City":"","Department":"","ContactNumber":"","Role":"","IPAddress":"","ProfileDescription":"","ProfileId":""}'

# Depts
curl -H "Authorization: Bearer <TOKEN>" http://localhost:8080/api/v1/template/GetDepartment
```

---

## 14. 🚀 Deployment

### 14.1 Build
```bash
flutter clean
flutter pub get
flutter build web --release --base-href /datafusion/   # '/' if hosted at root
```
Output goes to `build/web/`.

### 14.2 Hosting
- Serve `build/web/` as static files from **IIS / Nginx / Apache**. HDFC deploys this behind IIS at `https://hbenetppuatdb01.hdfcbankuat.com/DataORCAPI/` (reverse proxy to the API at `/DataORCAPI/api/`).
- Ensure the web server sends `Cache-Control: no-cache` for `index.html` but allows long-lived caching for hashed assets (`main.dart.js`, `flutter.js`, etc.).
- **CORS**: the API must allow the deploy origin.
- **Base href**: the `<base href="$FLUTTER_BASE_HREF">` in `web/index.html` is substituted at build time by the `--base-href` flag.

### 14.3 CI/CD (recommended, not in repo)
```yaml
# .github/workflows/build.yml
name: build
on: [push]
jobs:
  web:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { channel: stable }
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
      - run: flutter build web --release
      - uses: actions/upload-artifact@v4
        with: { name: web, path: build/web }
```

---

## 15. ⚠️ Error Handling & Logging

### 15.1 Error surface
- **Global SnackBars** — `ApiService` has an injected `showMessage` callback that is wired to the global `scaffoldMessengerKey` in `main.dart`. Session expiry + offline notifications are raised this way.
- **Per-page SnackBars** — each page (`LoginPage`, `ManualUploadPage`, `CheckerPage`, `SourceConfigurationPage`) shows a `SnackBar` with `backgroundColor: AppColors.red` on failure.
- **Error state** — `AuthProvider.error`, `TemplateProvider.error` hold the last server message; widgets can read them.
- **Offline guard** returns an `ApiResponse.error('No internet connection…', statusCode: 0)` without hitting the wire.

### 15.2 Logging
- Every request prints a structured bracketed log via `debugPrint`:
  ```
  ┌─ [API REQUEST] POST https://.../account/login
  │  Body: {…}
  └─────────────────────────────────
  ┌─ [API RESPONSE] POST … → 200
  │  { "token":… }
  └─────────────────────────────────
  ```
- Errors include the DioExceptionType and response body.
- This is verbose by design on dev builds and quiet in release builds (`debugPrint` is a no-op when assertions are off unless you keep it — see Flutter docs).

---

## 16. 📊 Performance Considerations

- **`CustomPainter` for edges** — edges aren't widgets. They're drawn in one pass by `EdgePainter`, which repaints only when the `PipelineController` calls `notifyListeners()`. Hit-testing is done manually (`hitTestDisconnect`, `hitTestEdge`) for tap events.
- **`InteractiveViewer`** with `constrained: false` so panning doesn't force a 3000×2000 layout.
- **Lazy master data** — each page loads only the master data it needs and waits for `AuthProvider.initialized` before calling the API (avoids firing calls before the token is rehydrated).
- **Parallel master-data loads** (`Future.wait([getSourceTypes(), getOperations()])` in `PipelineMasterProvider`).
- **Selectors / Consumers scoped** — the canvas uses multiple `Consumer<PipelineController>` scopes so a node drag doesn't rebuild `Sidebar`.
- **Refresh mutex** — one in-flight refresh across concurrent 401s.
- **Image asset** — only one PNG logo; everything else is Material Icons.
- **Build time savings** — `flutter build web --release` produces tree-shaken JS; Canvas renderer is default on desktop browsers. Use `--web-renderer canvaskit` only if you need identical rendering to Skia mobile.

---

## 17. 🔒 Security Best Practices

### 17.1 Data at rest
- Tokens stored via `flutter_secure_storage`. On web this maps to an encrypted IndexedDB namespace.
- Never store the password — only tokens.
- `session.clearSession()` is called on logout and on any refresh failure.

### 17.2 Transport
- HTTPS is mandatory in UAT/prod (the UAT base URL demonstrates this).
- The Bearer token is attached by a single interceptor — never hand-stitched per call.

### 17.3 Input validation (client-side)
- `TemplateRequest.isGeneralInfoValid`, `isOutputFormatValid`, `isApprovalValid`, `isFileUploaded`, `isComplete` gate form submission.
- Form fields in `SourceConfigurationPage` / `TemplateCreationPage` use `TextFormField.validator` (required + numeric checks).
- File pickers restrict `allowedExtensions` to `['csv','xlsx','xls','txt','json']`.
- Column-file parser rejects SQL/paragraph-style input (see tests in `test_files/`).

### 17.4 Anti-pitfalls baked in
- The 401 interceptor skips endpoints containing `login` or `refresh` so a refresh failure can't infinite-loop.
- `postMultipart` JSON-encodes scalar fields instead of concatenating strings.
- `Dio.setToken(null)` on every logout.
- No `eval`/`dart:js` beyond the file-download trigger.

### 17.5 Things the next engineer must handle server-side
- Rate-limit login and refresh.
- Sanitise filenames / bytes (the frontend sends raw user files).
- Enforce `role` at the API boundary — the UI hides Checker-only screens only by convention, not by contract.

---

## 18. 🛠️ Recreate Instructions (exact sequence)

Follow these numbered steps to rebuild the project from scratch using only this document.

### Phase 0 — Environment
```bash
flutter --version                 # must satisfy Dart ^3.9.2
flutter config --enable-web
```

### Phase 1 — Scaffold project
```bash
flutter create --platforms=web --project-name vizualizer frontend
cd frontend
```
Overwrite `pubspec.yaml` with:
```yaml
name: vizualizer
description: "gather data from different sources"
publish_to: "none"
version: 0.1.0
environment:
  sdk: ^3.9.2
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.0
  file_picker: ^6.1.1
  dio: ^5.7.0
  flutter_secure_storage: ^9.2.2
  connectivity_plus: ^6.1.4
  web: ^1.1.1
dev_dependencies:
  flutter_lints: ^5.0.0
  flutter_test:
    sdk: flutter
flutter:
  uses-material-design: true
  assets:
    - assets/images/
```
Run `flutter pub get`.

### Phase 2 — Assets and web shell
1. Create `assets/images/` and place `HDFC_Bank_Logo.svg.png`.
2. Edit `web/index.html` → set `<title>DATA FUSION</title>` and iOS web-app meta `DATA FUSION`.
3. Edit `web/manifest.json` → `name: "DATA FUSION"`, `short_name: "DATA FUSION"`, icon paths as default.

### Phase 3 — Theme
Create `lib/theme/app_theme.dart` with `AppColors` + `AppTextStyles` exactly as documented (colors and fonts listed in §11.5 and §3).

### Phase 4 — Config
Create `lib/config/api_config.dart` with the endpoint constants from §4. Default `baseUrl = 'http://localhost:8080/api/v1/'`.

### Phase 5 — Models (in order)
1. `lib/models/api_response.dart` — `ApiResponse<T>`, `SubmitMappingResponse`, `CreateTemplateResponse`, `AddSourceMasterResponse`, `TemplateListItem`.
2. `lib/models/login_request.dart` — `LoginRequest` (14 fields, `_staticEmployeeCode = 'n2346'`, `toJson`).
3. `lib/models/login_response.dart` — `LoginUser`, `LoginResponse`.
4. `lib/models/master_models.dart` — `DepartmentItem`, `ApprovalItem`, `SourceTypeItem`, `SourceMasterFilterItem`, `SourceMasterItem`, `SourceListItem`, `OperationItem`.
5. `lib/models/template_info.dart` — `ManualTemplateInfo`, `TemplateInfo`.
6. `lib/models/template_request.dart` — `TemplateRequest` with `toJson()` emitting `Template[]`, `OutputFormats`, `Approvals`.
7. `lib/models/pipeline_models.dart` — `NodeType` enum + `NodeTypeExt`, `DragNodeData`, `ColumnMapping`, `OutputFilter`, `OutputSort`, `PipelineNode`, `PipelineEdge`.
8. `lib/models/pipeline_config.dart` — `PipelineConfig.templatesByDept`, `templateSourceCount`, `joinTypes`, demo data.

### Phase 6 — Utils
Create the four utility files:
- `utils/connectivity_check_stub.dart` + `utils/connectivity_check_web.dart` (conditional import).
- `utils/file_download_stub.dart` + `utils/file_download_web.dart`.
- `utils/join_engine.dart` — implement `JoinEngine.execute` for all five join types.

### Phase 7 — Services
Implement in order (each depends only on `ApiService`):
1. `services/api_service.dart` — Dio, interceptors (log + 401 refresh with mutex + retry + offline guard), helpers: `get/post/put/delete`, `postMultipart`, `uploadMultipart`, `getFileBytes`, `getRawData`, `postRawData`, `configure()`.
2. `services/storage_service.dart` — the 7 keys + `saveSession`, `loadSession`, `clearSession`, `updateTokens`, `savePageIndex`, `loadPageIndex`.
3. `services/auth_service.dart` — `login`, `logout`, `refreshToken`.
4. `services/template_service.dart` — `createTemplate` (multipart).
5. `services/pipeline_service.dart` — `submitMapping` (multipart).
6. `services/master_data_service.dart` — all 12+ methods from §7.4.

### Phase 8 — Providers
1. `providers/auth_provider.dart` — auto-login, login, logout.
2. `providers/template_provider.dart` — `saveTemplate` with loading/error/successMessage/reqId.
3. `providers/pipeline_master_provider.dart` — loads `sourceTypes` + `operations` in parallel.

### Phase 9 — Pipeline controller
`controllers/pipeline_controller.dart` — nodes/edges CRUD, port drag, edge auto-direction, `_syncJoinSources`, `getNodeRows`, `getOutputResult` (filter → sort → select → alias), `diagnoseOutputIssue`, `initFromSources`, `seedDemoData`, all the `updateNode*` setters.

### Phase 10 — Pages
Build in this order (each can be tested standalone):
1. `pages/login_page.dart` — Sign-in form, SnackBar errors, navigates to `/dashboard`.
2. `pages/welcome_page.dart` — Greeting banner pulled from `AuthProvider.user`.
3. `pages/dashboard_page.dart` — 6-item drawer (`Home, Template Creation, Template Configuration, Source Configuration, Manual Upload, Checker`) + AppBar avatar + logout.
4. `pages/source_configuration_page.dart` — two custom overlay dropdowns (dept + sourceType) + 4 text fields → calls `addSourceMaster`.
5. `pages/template_creation_page.dart` — general info + output formats + approvals + per-approval file upload → calls `TemplateProvider.saveTemplate`.
6. `pages/template_configuration_page.dart` — wraps `PipelineCanvasPage` with the pipeline providers.
7. `pages/manual_upload_page.dart` — dept + template + N slot cards (based on `manualCount`).
8. `pages/checker_page.dart` — dept + template + Request ID → paginated results → approve/reject + download.
9. `pages/configuration_upload_page.dart` — placeholder (not in drawer by default, comment left in `dashboard_page.dart`).

### Phase 11 — Widgets (canvas)
1. `widgets/top_bar.dart` — title + Clear button calling `ctrl.clearCanvas()`.
2. `widgets/status_bar.dart` — `x nodes / y connections / Pipeline configured`.
3. `widgets/edge_painter.dart` — cubic-bezier edges, disconnect button, port-drag live line, hit tests.
4. `widgets/nodes/source_node_body.dart` — source card.
5. `widgets/nodes/join_node_body.dart` — join card + mapping form + submit dialog.
6. `widgets/nodes/output_node_body.dart` — output card + sample table + format chips.
7. `widgets/config_panel.dart` — right-side node-config stepper.
8. `widgets/source_preview_sidebar.dart` — appears when `allSourceNodesConfirmed`.
9. `widgets/mapping_preview_dialog.dart` — five-step review dialog before `PipelineService.submitMapping`.
10. `widgets/sidebar.dart` — dept/template dropdowns + palette + pulse animations.
11. `widgets/pipeline_canvas_page.dart` — `InteractiveViewer` + `DragTarget<DragNodeData>` + port overlay.

### Phase 12 — Entrypoint
`lib/main.dart` — build the MultiProvider, `configure` the `ApiService` callbacks, define `PipelineApp` with `home: auth.initialized ? (isLoggedIn ? DashboardPage : LoginPage) : loading-spinner`, routes `/login` and `/dashboard`.

### Phase 13 — Tests
Create `test/login_page_test.dart` as per §13.

### Phase 14 — Verification
```bash
flutter analyze     # expect 0 issues
flutter test        # 18 LoginPage tests green
flutter run -d chrome
```
Login with dev credentials, exercise each drawer item against a mocked backend (Postman / MSW).

---

## 19. 📌 Code-Level Explanation (key functions)

### 19.1 `ApiService._performTokenRefresh()` (api_service.dart)
```dart
Future<bool> _performTokenRefresh() async {
  try {
    if (_refreshFn == null) return false;           // 1. refresher wasn't injected
    final newToken = await _refreshFn!.call();      // 2. delegates to AuthService.refreshToken
    if (newToken != null && newToken.isNotEmpty) {
      _authToken = newToken;                        // 3. set the new access token on the client
      return true;
    }
    return false;                                   // 4. surface failure — triggers logout upstream
  } catch (e) {
    debugPrint('[ApiService] Token refresh error: $e');
    return false;
  }
}
```
This is the **only** place the access token gets rotated at runtime. The injected `_refreshFn` (wired in `main.dart`) internally calls `StorageService.loadSession()` → `AuthService.refreshToken()` → `StorageService.updateTokens()`.

### 19.2 `PipelineController.addEdge` (pipeline_controller.dart)
```dart
void addEdge(String fromId, String toId) {
  final fromNode = findNode(fromId);
  final toNode = findNode(toId);
  if (fromNode == null || toNode == null) return;
  // Auto-correct — a join cannot be upstream of a source
  if (toNode.type.isSource && fromNode.type == NodeType.join) {
    final tmp = fromId; fromId = toId; toId = tmp;
  }
  if (edges.any((e) => e.fromNodeId == fromId && e.toNodeId == toId)) return; // idempotent
  edges.add(PipelineEdge(id: _nextEdgeId(), fromNodeId: fromId, toNodeId: toId));
  final target = findNode(toId);
  if (target != null && target.type == NodeType.join) _syncJoinSources(target);
  notifyListeners();
}
```
Note the implicit contract: if the user drew the edge "backwards", it silently swaps endpoints. This is why the UI can allow the user to drag from either end.

### 19.3 `JoinEngine.execute` — LEFT JOIN branch
```dart
case 'LEFT JOIN':
  for (final lr in leftRows) {
    bool matched = false;
    for (final rr in rightRows) {
      if (matches(lr, rr)) { result.add({...lr, ...rr}); matched = true; }
    }
    if (!matched) result.add({...lr, ...emptyOf(rightRows.first)});
  }
```
`matches` returns true iff every `ColumnMapping` equates string-wise on the row. Unmatched left rows are filled with the shape of the right side's columns set to `'—'`.

### 19.4 `AuthProvider._tryAutoLogin`
```dart
Future<void> _tryAutoLogin() async {
  try {
    final session = await _storage.loadSession();
    if (session != null && session.token.isNotEmpty) {
      _authService.setToken(session.token);
      _user = session;
    }
  } catch (_) {}
  _initialized = true;
  notifyListeners();
}
```
Why `_initialized`: `MaterialApp.home` reads it — showing a spinner until storage resolves so we never flash the login screen before auto-login completes.

### 19.5 `StorageService.saveSession`
```dart
await Future.wait([
  _storage.write(key: _tokenKey, value: session.token),
  _storage.write(key: _refreshTokenKey, value: session.refreshToken),
  _storage.write(key: _userKey, value: jsonEncode({/* 12 user fields */})),
]);
```
Three parallel writes. The user blob is hand-serialized (instead of `session.user.toJson()`) because the model is immutable-by-constructor and the keys must match `LoginUser.fromJson`'s expected shape.

### 19.6 `MasterDataService.uploadManualData`
Encodes the list of entries under a single form field `ManualFileUploadList` containing `{"manualFileUploadslist":[{Template_id,department_id,source_id,filename,createdBy}, …]}`, plus each file under the repeating `Files` field. This is how the backend associates each binary with metadata.

---

## 20. 📎 Example Requests & Outputs

### 20.1 Login
**Request**
```
POST http://localhost:8080/api/v1/account/login
Content-Type: application/json

{"Id":0,"Name":"admin","EmployeeCode":"n2346","password":"admin123", "Email":"","Location":"","LOCATIONCODE":"","City":"","Department":"","ContactNumber":"","Role":"","IPAddress":"","ProfileDescription":"","ProfileId":""}
```
**Response 200**
```json
{
  "token":"eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJuMjM0NiJ9.abc",
  "refreshToken":"a1b2c3d4-refresh",
  "user":{"id":7,"name":"Amit Sharma","employeeCode":"n2346","email":"amit@hdfcbank.com","department":"Finance","role":"1"}
}
```

### 20.2 Get Departments
**Request**
```
GET http://localhost:8080/api/v1/template/GetDepartment
Authorization: Bearer <TOKEN>
```
**Response**
```json
[{"dpt_Id":1,"dpt_Name":"Finance"},{"dpt_Id":2,"dpt_Name":"Operations"},{"dpt_Id":5,"dpt_Name":"Risk Management"}]
```

### 20.3 Add Source Master
**Request**
```
POST http://localhost:8080/api/v1/template/AddSourceMasterList
Authorization: Bearer <TOKEN>
Content-Type: application/json

{"sourceType":"3","AppName":"FinacleCore","ITGRC":5001,"Name":"FC Txn Master","DBVault":"VLT-01","Createdby":"n2346","department_id":1}
```
**Response**
```json
{"status":"Success","reqID":17}
```

### 20.4 Create Template (multipart)
**Request (conceptual)**
```
POST http://localhost:8080/api/v1/template/AddTemplate
Authorization: Bearer <TOKEN>
Content-Type: multipart/form-data; boundary=----WebKitFormBoundary…

------WebKitFormBoundary…
Content-Disposition: form-data; name="TemplateRuequest"

{"Template":[{"TemplateName":"Daily MIS","Department":"Finance","Frequency":"Daily","NormalVolume":500,"PeakVolume":1200,"SourceCount":3,"NumberOfOutputs":2,"BenefitType":"Cost Saving","BenefitAmount":15000,"BenefitInTat":"2 days","GoLiveDate":"2026-05-01","DeactivateDate":null,"SpocPerson":"Amit Sharma","SpocManager":"R. Menon","UnitHead":"S. Iyer","Priority":"High","SourceList":"5,9,17"}],"OutputFormats":[{"TemplateTempId":null,"FormatName":"Unimailing"}],"Approvals":[{"TemplateTempId":null,"Approval_Type":"Unit Head","ApprovalFile":"approval_uh.pdf"}]}
------WebKitFormBoundary…
Content-Disposition: form-data; name="Files"; filename="approval_uh.pdf"
Content-Type: application/pdf

<binary>
------WebKitFormBoundary…--
```
**Response**
```json
{"status":"Success","reqID":"7"}
```

### 20.5 Submit Template Configuration (multipart)
Request payload (`TemplateConfig` field, JSON):
```json
{
  "templateId": 7,
  "templateName": "Daily MIS",
  "department": "Finance",
  "sources": [
    {"id":5,"type":"fc","name":"FC Txn Master","separator":",","columnFile":"valid_columns.csv","queryFile":"valid_query.txt","selectedCols":["customer_id","first_name","last_name"]},
    {"id":9,"type":"manual","name":"Branch Upload","separator":"|","columnFile":"valid_columns_pipe.txt"}
  ],
  "joins": [
    {"leftSourceId":"n1","leftCol":"customer_id","rightSourceId":"n2","rightCol":"customer_id","joinType":"LEFT JOIN","operationValue":"="}
  ],
  "edges": [
    {"from":"n1","to":"n3"}, {"from":"n2","to":"n3"}, {"from":"n3","to":"n4"}
  ],
  "output": {
    "format":"csv",
    "selectedCols":["customer_id","first_name","last_name","balance"],
    "aliases": {"balance":"Current Balance"},
    "filters": [{"column":"balance","operator":">","value":"10000"}],
    "sort":   [{"column":"balance","ascending":false}]
  }
}
```
Response:
```json
{"templateId":7,"configId":12}
```

### 20.6 Checker fetch + approval
**Fetch**
```
POST http://localhost:8080/api/v1/template/GetCheckerTayList
Authorization: Bearer <TOKEN>
Content-Type: application/json

{"template_id":"10","department_id":"1","Request_id":"123"}
```
**Response**
```json
[
  {"requestId":123,"filename":"branch_txn.csv","uploadedBy":"n1001","uploadedAt":"2026-04-20T10:15:00Z","status":"Pending","rowCount":1248}
]
```
**Approve**
```
POST http://localhost:8080/api/v1/template/UploadManualDataChecker
Authorization: Bearer <TOKEN>

{"Template_id":"10","department_id":"1","Request_id":"123","CheckerBy":"n2000","Remart":"All rows reconcile","isApproved":"Y"}
```
**Response:** `{"status":"Success","reqID":123}`

### 20.7 Download file
```
GET http://localhost:8080/api/v1/template/DownloadFile?filename=branch_txn.csv&template_id=10
Authorization: Bearer <TOKEN>
```
Response: raw bytes. The Flutter Web client pipes them through `utils/file_download_web.dart` to create a browser download.

---

## Appendix A — Sample test files (in repo)

| File                                       | Purpose                                                 |
| ------------------------------------------ | ------------------------------------------------------- |
| `test_files/valid_columns.csv`             | `customer_id,first_name,…` valid header + 3 rows         |
| `test_files/valid_columns_pipe.txt`        | Pipe-separated variant                                  |
| `test_files/valid_query.txt`               | `SELECT c.customer_id, c.first_name… FROM customers c…` |
| `test_files/valid_query_with.txt`          | Query with CTE                                          |
| `test_files/invalid_columns_paragraph.txt` | Used to test rejection of free-text uploads             |
| `test_files/invalid_columns_raw_numbers.csv` | Rows without proper headers                           |
| `test_files/invalid_columns_sentence_headers.csv` | Header row with non-identifier tokens            |
| `test_files/invalid_query_numbers.txt`     | Reject a file that's just numbers                       |
| `test_files/invalid_query_paragraph.txt`   | Reject paragraph-like content masquerading as query     |

These are used by the source-node config panel validator to differentiate a real CSV/query file from random uploads.

---

## Appendix B — Known typos / quirks (preserve for wire-compat)

- API form-field name is `TemplateRuequest` (sic). The backend expects this exact key. Preserved in `template_service.dart`.
- Checker API uses `"Remart"` (sic) instead of `"Remark"`. Preserved in `master_data_service.dart`.
- `LoginRequest._staticEmployeeCode = 'n2346'` is hardcoded until SSO resolves employee code dynamically.
- `lib/pages/configuration_upload_page.dart` exists but is not wired into the drawer (commented out in `dashboard_page.dart`).

---

*End of documentation. This specification — together with the dependency list in §3, the endpoint catalogue in §7, and the recreate plan in §18 — is sufficient to rebuild the Flutter Web frontend of HDFC Data Fusion from scratch.*
