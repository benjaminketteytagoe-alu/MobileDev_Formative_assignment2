# CampusSupport — Campus Incident Reporting App

A Flutter + Firebase mobile app where university students report campus problems (broken facilities, water shortages, electricity outages, damaged furniture, sanitation problems, safety concerns) and authorized campus staff review reports and move them from submission to resolution.

## Features

### Students
- **Register & sign in** with email/password or **Google** (ALU domains only)
- **Submit reports** with title, description, category (horizontal picture cards), ALU campus sector (Social Commons, Enterprise Commons, Leadership Centre, Collaboration Street) plus room, urgency, and up to 5 photos **from the camera or the gallery**
- **Submit / Cancel** bar on the report form; Cancel offers to **save a draft** to Firestore, which is restored next time
- **Browse & filter** all reports by category, sector, status, and urgency under a campus-photo hero
- **Search** reports by keyword
- **Upvote** ("Me too") on reports affecting multiple students
- **Report anonymously**: name and avatar stay hidden in the app
- **Flag** false or abusive reports for staff to review
- **Edit/delete** own reports while still in "Submitted" status
- **View status timeline** showing every status change
- **In-app notifications** when report status changes
- **Password reset** via email (the email typed on the login screen is carried over)

### Staff
- Everything students can do, plus:
- **Staff dashboard** with count cards per status
- **Update status** along the workflow: Submitted → In Review → In Progress → Resolved
- **Reject** reports with a required reason, shown to the student in the status history
- **Assign** reports to themselves ("Assign to me" on the report page)
- **See flags** on a report, and delete reports along with their photos, history and votes

### Quality Features
- **ALU branding**: navy / red / gold theme, CampusSupport logo, native + animated splash screen, custom launcher icon
- **Category pictures**: every category has artwork; drop a photo into `assets/images/categories/` and it is used instead (`assets/images/categories/<name>.jpg`)
- **Sign out** from every main tab (app bar button) and from Profile, with confirmation
- **DiceBear avatars**: every person gets a generated avatar on the feed, report page, status history and profile. Initials show until it loads or if it cannot load, and avatars are cached on disk for offline use
- **DiceBear icons and mascots**: category icons and animated empty/error mascots are bundled, so they work offline
- **Motion**: staggered lists, animated status tracker, count-up dashboard, avatar crossfades. All of it respects the system "remove animations" setting
- **Dark mode** following system setting, on every screen
- **Offline resilience** with connectivity banner
- **Duplicate hints** when typing report titles
- **Pull-to-refresh** on all lists
- **Haptic feedback** on buttons
- **Real-time updates** via Firestore streams
- **Security rules** enforcing role-based access server-side

## Tech Stack

| Layer | Technology |
|---|---|
| UI | Flutter 3.x, Material 3 |
| State management | Riverpod |
| Backend | Firebase Auth, Cloud Firestore, Supabase Storage |
| Offline | Firestore offline persistence + connectivity_plus |
| Images | cached_network_image, image_picker with compression |
| Avatars | DiceBear HTTP API (10.x), flutter_svg, flutter_cache_manager |
| Animated SVG | webview_flutter (JavaScript off, strict CSP) |

## Setup

### Prerequisites
- Flutter SDK (latest stable)
- Android Studio / VS Code with Flutter plugins
- Firebase account (free Spark plan)
- Supabase account (free plan), for photo storage

### Firebase Configuration

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Register an Android app with package name `com.example.student_support`
3. Download `google-services.json` and place it in `android/app/`
4. Enable **Email/Password** and **Google** authentication in Firebase Console (Google also needs your debug SHA-1 in the Firebase project settings)
5. Create a Firestore database (start in test mode, then deploy the rules below)
6. Set up Supabase Storage (see [Photo storage](#photo-storage-supabase))

### Install & Run

```bash
cd student_support
flutter pub get
flutter run --dart-define-from-file=supabase.env.json
```

Without the Supabase file the app still runs, but photo uploads show a "not set up" message. In Android Studio, add `--dart-define-from-file=supabase.env.json` under Run > Edit Configurations > Additional run args.

### Run the Tests

```bash
flutter analyze
flutter test

# Security rules, against the Firestore and Storage emulators (needs Java and Node 22 or later)
cd rules_test && npm install && npm test
```

### Deploy Security Rules

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Log in and select the project (firebase.json is already configured,
# so do not run `firebase init` - it can overwrite it)
firebase login
firebase use studentsupport-88445

# Deploy rules and indexes
firebase deploy --only firestore:rules,firestore:indexes
```

## Demo Accounts

| Role | Email | Password |
|---|---|---|
| Student | `student1@alustudent.com` | `Password1` |
| Staff | `staff@alueducation.com` | `Password1` |

> **Note:** Create these accounts in the app first. Every new account starts as a student, so promote the staff account as described below.

## How to Promote a User to Staff

The app never grants staff access by itself, because nobody proves they own the email address they sign up with.

1. The user registers in the app with an `@alueducation.com` address
2. In Firebase Console → Authentication, find the user and copy their UID
3. In Firestore, open `users/{uid}` and change `role` from `"student"` to `"staff"`
4. The user signs out and signs in again

Only `@alueducation.com` accounts can be promoted. The rules ignore a staff role on any other address.

## Folder Structure

```
lib/
├── main.dart                 
├── core/
│   ├── dicebear.dart         
│   ├── theme/                
│   └── widgets/              
├── models/                   
├── services/                 
├── providers/                
├── screens/                  
├── navigation/               
└── utils/                    

assets/images/
├── logo.svg                  
├── categories/               
├── dicebear/                 
└── app_icon*.png, logo_splash.png   
tool/generate_brand_assets.py 
tool/fetch_dicebear_assets.py 
```

## DiceBear

| Use | Style | Licence | How it loads |
|---|---|---|---|
| User avatars | `thumbs` | CC0 1.0 | Live API, then disk cache (90 days) |
| Empty/error mascots | `voxel-bot` | CC0 1.0 | Bundled, `tool/fetch_dicebear_assets.py` |
| Category icons | `icons` (Bootstrap Icons) | MIT | Bundled, `tool/fetch_dicebear_assets.py` |

- **Privacy:** the seed is a salted SHA-256 hash of the user id, so names, emails and Firebase ids are never sent to DiceBear (`lib/core/dicebear.dart`).
- **Reliability:** functional UI never waits on the network. If DiceBear is down or rate limited, avatars stay as initials.
- **Animation:** DiceBear animates with CSS inside the SVG, which `flutter_svg` cannot run, so it draws the first frame. The large profile avatar and the mascots use `AnimatedSvgView`, a WebView with JavaScript off and a content security policy that blocks all loading. Lists never use it, because each WebView is expensive.
- **Limits:** the public API is free for non-commercial use, at 50 SVG requests per second. A commercial release must self-host and set `--dart-define=DICEBEAR_BASE_URL=https://your-host/10.x`.
- **Credits:** the licences are in the app under Profile → Open-source licenses, and in `assets/images/dicebear/LICENSE.txt`.

## Status Workflow

```
Submitted → In Review → In Progress → Resolved
   ↓            ↓            ↓
  Rejected    Rejected     Rejected
```

Every transition writes a history entry with who, when, and an optional note.

## Security Rules

- **Firestore rules** enforce: authenticated reads, owner-only create, owner edit while `submitted`, staff-only status transitions, staff self-assignment, history/votes/notifications access control
- The reporter may write only the first `submitted` history entry, in the same batch that creates the report; every later entry must come from staff
- `upvoteCount` can change by exactly ±1, and only in the same transaction that creates/deletes the user's own vote document
- **Storage policies** enforce: ALU accounts only, uploads to the user's own folder, 5 MB limit, image types only. Anyone holding a photo's link can view it
- Every new account starts as a student. Staff need an `@alueducation.com` email and `role: "staff"`, which only an administrator can set (see [How to Promote a User to Staff](#how-to-promote-a-user-to-staff))

## Performance

- `const` constructors on all static widgets
- `ListView.builder` for lists
- Cached network images
- Compressed uploads (max 1280px, 80% quality)
- Stream subscriptions cancelled in `dispose`

## Known Limitations

- Free Supabase projects pause after a week without activity.
- Anonymous reports are hidden in the app, but the reporter's user ID stays in the document, so someone reading Firestore directly could match it to their named reports. Hiding it needs Cloud Functions, which also needs Blaze
- Push notifications use in-app notifications only (no FCM)
- Image upload progress shown via button loading state
- Email addresses are not confirmed by a link, so staff access is granted by hand
- Anyone holding a photo's link can view it, because the bucket is public
- Draft photos stay on the phone that took them; a draft opened on another device restores the text only
- Search uses `searchKeywords` array (not full-text search)

## Photo storage (Supabase)

Authentication and Firestore use Firebase. Photos use a free Supabase Storage bucket, because Firebase Storage needs the paid Blaze plan.

1. In the Supabase dashboard, add Firebase under Authentication > Third-Party Auth, with the project ID `studentsupport-88445`.
2. Run `supabase/storage_policies.sql` in the SQL Editor. It creates the `incident-photos` bucket and its access policies.
3. Copy `supabase.env.example.json` to `supabase.env.json` and fill in the project URL and publishable key. That file is git-ignored. Never put the secret or `service_role` key in the app.
4. Run `flutter run --dart-define-from-file=supabase.env.json`.

Free Supabase projects pause after a week without activity. Restore the project from the dashboard before a demo.

## License

Educational project for African Leadership University assessment.
