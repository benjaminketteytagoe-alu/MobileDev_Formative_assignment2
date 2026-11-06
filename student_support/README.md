# CampusSupport — Campus Incident Reporting App

A Flutter + Firebase mobile app where university students report campus problems (broken facilities, water shortages, electricity outages, damaged furniture, sanitation problems, safety concerns) and authorized campus staff review reports and move them from submission to resolution.

## Features

### Students
- **Register & sign in** with email/password or **Google** (ALU domains only), and **verify the ALU email** before reaching the app
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
| Backend | Firebase Auth, Cloud Firestore, Firebase Storage |
| Offline | Firestore offline persistence + connectivity_plus |
| Images | cached_network_image, image_picker with compression |
| Avatars | DiceBear HTTP API (10.x), flutter_svg, flutter_cache_manager |
| Animated SVG | webview_flutter (JavaScript off, strict CSP) |

## Setup

### Prerequisites
- Flutter SDK (latest stable)
- Android Studio / VS Code with Flutter plugins
- Firebase account

### Firebase Configuration

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Register an Android app with package name `com.example.student_support`
3. Download `google-services.json` and place it in `android/app/`
4. Enable **Email/Password** and **Google** authentication in Firebase Console (Google also needs your debug SHA-1 in the Firebase project settings)
5. Create a Firestore database (start in test mode, then deploy the rules below)
6. Enable Firebase Storage

### Install & Run

```bash
cd student_support
flutter pub get
flutter run
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
firebase deploy --only firestore:rules,firestore:indexes,storage
```

## Demo Accounts

| Role | Email | Password |
|---|---|---|
| Student | `student@alustudent.com` | `Password1!` |
| Staff | `staff@alueducation.com` | `Password1!` |

> **Note:** Create these accounts in the app first. For the staff account, you must also manually set the role in Firestore:
> 1. Open Firebase Console → Firestore
> 2. Create document in `users` collection with the staff user's UID
> 3. Set `role: "staff"` and verify the email in Auth console

## How to Promote a User to Staff

1. In Firebase Console → Authentication, find the user
2. Verify their email (click "Send verification email" if needed)
3. In Firestore, create/update the document at `users/{uid}`:
   ```
   role: "staff"
   ```
4. The user must sign out and sign in again for the role to take effect

## Folder Structure

```
lib/
├── main.dart                 # App entry, Firebase init, MaterialApp, auth gate + splash
├── core/
│   ├── dicebear.dart         # DiceBear URLs, hashed seeds, bundled art paths
│   ├── theme/                # AppColors, AppPalette (light/dark), AppSpacing, AppRadius, AppTextStyles, AppTheme
│   └── widgets/              # Reusable widgets (IncidentCard, CategoryArt, CategoryPicker, AppLogo, SignOutButton, ...)
├── models/                   # Data models (IncidentModel, UserModel, etc.)
├── services/                 # Firebase services (Auth, Incident, Storage)
├── providers/                # Riverpod providers (auth, incidents, filters)
├── screens/                  # App screens (splash, auth, home, report, detail, staff, profile)
├── navigation/               # App router
└── utils/                    # Helpers (validators, error messages, labels)

assets/images/
├── logo.svg                  # CampusSupport mark ("CS" monogram)
├── categories/               # Your category photos; *.svg is the fallback art
├── dicebear/                 # Bundled DiceBear mascots, category icons, LICENSE.txt
└── app_icon*.png, logo_splash.png   # Generated by tool/generate_brand_assets.py
tool/generate_brand_assets.py # Redraws the PNG icon/splash from the brand colors
tool/fetch_dicebear_assets.py # Re-downloads the bundled DiceBear SVGs
```

## Branding

| Token | Value | Where |
|---|---|---|
| ALU navy (primary) | `#0B2A5B` | `AppColors.aluNavy` |
| ALU red (errors / destructive only) | `#E4312B` | `AppColors.aluRed` |
| ALU gold (accent) | `#F5B014` | `AppColors.aluGold` |

Navy is the only color for primary actions (buttons, FAB, links); gold is a sparing accent (the hero call to action); red means errors and destructive actions only.

These are placeholders until the official hex codes are confirmed. To change them, edit `lib/core/theme/app_colors.dart` and `tool/generate_brand_assets.py`, then rerun the icon commands.

The logo is a "CS" monogram. To use your own, replace the files written by `tool/generate_brand_assets.py` and run `dart run flutter_launcher_icons` and `dart run flutter_native_splash:create`.

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
- The reporter may write only the first `submitted` history entry, in the same batch that creates the report; every later entry must come from verified staff
- `upvoteCount` can change by exactly ±1, and only in the same transaction that creates/deletes the user's own vote document
- **Storage rules** enforce: authenticated reads, owner-only image upload, 5MB limit, image types only
- Role is determined server-side from email domain + user document

## Performance

- `const` constructors on all static widgets
- `ListView.builder` for lists
- Cached network images
- Compressed uploads (max 1280px, 80% quality)
- Stream subscriptions cancelled in `dispose`

## Known Limitations

- Firebase Storage needs the paid Blaze plan, so photos run on the local Storage emulator and exist only on the computer running it (see below)
- Anonymous reports are hidden in the app, but the reporter's user ID stays in the document, so someone reading Firestore directly could match it to their named reports. Hiding it needs Cloud Functions, which also needs Blaze
- Push notifications use in-app notifications only (no FCM)
- Image upload progress shown via button loading state
- Draft photos stay on the phone that took them; a draft opened on another device restores the text only
- Search uses `searchKeywords` array (not full-text search)

## Running with the Storage emulator

Authentication and Firestore use the live Firebase project. Photos use the official Firebase Storage emulator with the same SDK calls and `storage.rules`.

1. Terminal 1: `./tool/run_storage_emulator.sh` (needs Java; photos are kept in `.emulator-data`)
2. Terminal 2: `flutter run --dart-define=STORAGE_EMULATOR_HOST=10.0.2.2`

On a phone over USB, run `adb reverse tcp:9199 tcp:9199` and use `STORAGE_EMULATOR_HOST=127.0.0.1`. Without the flag, the app uses the cloud bucket.

Security-rule tests: `cd rules_test && npm install && npm test`

## License

Educational project for university assessment.
