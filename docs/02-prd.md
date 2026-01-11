# Product Requirements Document: smpl-tracker

## Overview

### Problem
Existing habit trackers use a "build up" model where you start at 0% and work toward 100%. This creates the wrong mental model - new habits feel like failures from day one.

### Solution
A habit tracker with a **decay model**: habits start at 100% health and degrade when you miss targets. This surfaces which habits need attention rather than showing incomplete progress.

### Target User
Personal use only. Opinionated design for a single user's workflow.

### Success Criteria
- Daily logging takes one tap per habit
- App opens and is usable in under 1 second
- No lost data
- New phone setup = install app, sign in, data appears

---

## Core Concepts

### Decay Model
- **New habits start at 100%** with a grace period before decay begins
- **Missing targets causes accelerating decay** (consecutive misses hurt more)
- **Recovery mirrors decay** - consistent logging rebuilds health inversely
- **Can hit 0%** - fully neglected habits fail completely
- **Overflow banking** - exceeding targets builds buffer against future decay AND displays above 100%

### Grace Period
Based on target frequency:
- Daily habit: 24 hours before decay starts
- 3x/week habit: ~2.3 days (7÷3) before decay starts

### Time Boundaries
- **Day boundary**: 2:00 AM local time (night owl friendly)
- **Week start**: Sunday
- Calendar days, not rolling hours

---

## MVP Requirements (v1)

### Must Have

#### Habit Management
- Create habit with name and frequency (daily or X times/week)
- Edit habit name and frequency
- Delete habit (permanent, no archive)
- Manual sort order (drag to reorder)

#### Daily Logging
- One-tap to log habit for today (exact interaction TBD in mockups)
- Toggle behavior: re-tap/re-action to undo
- Backfill: can log for any past date
- Binary logging only (done/not done)

#### Health Display
- Show current health % for each habit
- Visual health indicator (style TBD in mockups)
- Display above 100% when exceeding targets

#### Core Algorithm
- Accelerating decay on missed targets
- Matching recovery curve on consistent logs
- Overflow banking for extra logs

#### Cloud Sync
- Firebase Firestore for data storage and sync
- Google Sign-In for authentication (single user, no password management)
- Real-time sync across devices
- New phone = install, sign in, data appears automatically
- Offline-first: app works without network, syncs when available

### Should Have (if easy)
- Single daily reminder notification at configurable time

### Out of Scope (v1)
- Data export (JSON/CSV)
- Multiple logs per day (count-based habits)
- Categories or colors
- Notes or descriptions on habits
- Statistics or history views
- Dark mode
- Specific day scheduling (Mon/Wed/Fri)

---

## Technical Decisions

### Framework
**Flutter** - chosen for rapid iteration and hot reload during UI development. Can build iOS later if desired.

### Backend / Storage
**Firebase** (using existing GCP project from opencamp):
- **Firestore** - NoSQL document database, real-time sync, offline support built-in
- **Firebase Auth** - Google Sign-In for authentication
- No local SQLite needed - Firestore handles offline caching automatically

Why Firebase over Google Drive:
- Real-time sync vs manual backup/restore
- Offline support built into SDK
- Simpler than managing file exports/imports
- Can query data directly for future web UI

### Infrastructure
- New Firebase/GCP project (same Google account, separate from opencamp)
- Firestore in production mode with security rules
- Single-user app, but auth required for security (can't hardcode credentials)

### Distribution
Sideload APK or ADB install for v1. Play Store later if needed.

### Dev Environment
- Android Studio (needs installation)
- Flutter SDK
- Firebase CLI for project setup
- Physical device for testing (daily phone)

---

## Data Model (Firestore)

### Collection: `users/{userId}/habits`
```
{
  id: String (document ID)
  name: String
  frequency_type: "daily" | "weekly"
  frequency_count: Int (for weekly, e.g., 3 for "3x/week")
  sort_order: Int
  created_at: Timestamp
  updated_at: Timestamp
}
```

### Collection: `users/{userId}/logs`
```
{
  id: String (document ID)
  habit_id: String (reference)
  logged_date: String (YYYY-MM-DD format, easier to query)
  created_at: Timestamp
}
```

### Security Rules
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### Computed (client-side)
- `health_percentage`: Calculated from logs and decay algorithm
- `overflow_buffer`: Extra logs beyond target

---

## UX Requirements

### Onboarding
1. App opens to sign-in screen (if not authenticated)
2. "Sign in with Google" button
3. After sign-in, show home screen (empty state if new user)

### Home Screen
1. List of all habits
2. Each habit shows: name, health indicator, quick log action
3. Manual sort order (drag to reorder)
4. Access to habit settings/edit

### Add/Edit Habit
- Name input
- Frequency picker (daily, or X times per week)
- Delete option (with confirmation)

### Settings
- Sign out option
- Account info display

### Interaction (to explore in mockups)
- Log action: tap, swipe, or checkbox - pick during design phase
- Visual health representation: progress bar, color, number - explore options

---

## Open Questions (for design phase)

1. Exact log interaction (tap vs swipe vs checkbox)
2. Visual representation of health (bars, circles, colors, numbers)
3. How to show overflow/above-100% state
4. Empty state when no habits
5. Confirmation flow for delete
6. Sign-in screen design

---

## Future Considerations (v2+)

- Count-based habits (not just binary)
- Per-habit reminders
- Statistics and history views
- Streak visualization
- Dark mode (follow system)
- Widget for home screen
- Web UI (read from same Firestore)
- Data export (JSON/CSV)
- iOS build

---

## Timeline

Target: **This weekend**

Priority order:
1. Dev environment setup (Flutter, Android Studio, Firebase CLI)
2. Firebase project setup (Firestore, Auth, security rules)
3. Google Sign-In flow
4. Data model and Firestore integration
5. Basic CRUD for habits
6. Logging functionality
7. Decay algorithm
8. UI polish based on mockups
