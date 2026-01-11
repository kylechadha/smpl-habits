# System Design & Implementation

## 1. Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      Flutter App                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   UI Layer  │  │   Services  │  │   State (Riverpod)  │  │
│  │   Screens   │◄─┤  Auth, DB   │◄─┤   Providers         │  │
│  │   Widgets   │  │  Decay calc │  │   Models            │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Firebase Backend                          │
│  ┌─────────────────────┐  ┌─────────────────────────────┐   │
│  │   Firebase Auth     │  │   Firestore                  │   │
│  │   Google Sign-In    │  │   Offline persistence       │   │
│  └─────────────────────┘  │   Real-time sync            │   │
│                           └─────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

**Key principles:**
- Offline-first: Firestore handles caching, app works without network
- Real-time sync: Changes appear across devices automatically
- Simple state: Riverpod for dependency injection and reactive state
- Thin service layer: Most logic lives in providers, services are just wrappers

---

## 2. Data Model (Firestore)

### Collection: `users/{userId}/habits`

```typescript
{
  id: String,              // Document ID (auto-generated)
  name: String,            // Max 50 chars
  frequency_type: "daily" | "weekly",
  frequency_count: Int,    // 1 for daily, 1-7 for weekly
  sort_order: Int,         // Manual ordering
  created_at: Timestamp,
  updated_at: Timestamp
}
```

### Collection: `users/{userId}/logs`

**Composite document ID**: `{habitId}_{YYYY-MM-DD}`

```typescript
{
  habit_id: String,
  logged_date: String,     // YYYY-MM-DD format
  created_at: Timestamp
}
```

**Why composite IDs:**
- Natural uniqueness constraint: same habit + date = same doc ID
- Direct lookup: to check if logged today, just get doc by ID
- Toggle is a simple set/delete operation
- Idempotent: offline writes don't create duplicates
- No need for compound queries to find existing logs

**Example:**
```
Log ID: "abc123_2026-01-11"
→ Habit "abc123" logged on January 11, 2026
→ To toggle: set() if missing, delete() if exists
```

### Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null 
                        && request.auth.uid == userId;
    }
  }
}
```

---

## 3. Decay Algorithm

### Health Color Thresholds

From the design mockups:
- **Blue (overflow)**: 100%+ (glowing, pulsing bar)
- **Green**: 70-99%
- **Yellow**: 40-69%
- **Red**: Below 40%

### Core Parameters

```dart
const int GRACE_PERIOD_DAILY = 1;      // Days before decay starts
const double BASE_DECAY_RATE = 5.0;    // % lost per missed day
const double DECAY_ACCELERATION = 1.5; // Multiplier per consecutive miss
const double MAX_HEALTH = 150.0;       // Overflow cap
const double MIN_HEALTH = 0.0;
```

### Weekly Grace Period

For weekly habits, grace period = `7 / frequency_count` days (rounded up).
- 7x/week = 1 day grace (same as daily)
- 3x/week = 3 days grace
- 1x/week = 7 days grace

### Calculation Algorithm

```dart
double calculateHealth(Habit habit, List<Log> logs) {
  // Create a set of logged dates for O(1) lookup
  final loggedDates = logs.map((l) => l.loggedDate).toSet();

  double health = 100.0;
  final today = getCurrentDay(); // Respects 2am boundary
  final gracePeriod = habit.isDaily ? 1 : (7 / habit.frequencyCount).ceil();
  int consecutiveMisses = 0;

  // Walk FORWARD through time (oldest to newest)
  for (int daysAgo = 89; daysAgo >= 0; daysAgo--) {
    final date = today.subtract(Duration(days: daysAgo));
    final wasLogged = loggedDates.contains(date);

    if (wasLogged) {
      // Recovery: inverse of decay, reset consecutive misses
      health = min(MAX_HEALTH, health + recoveryAmount(health));
      consecutiveMisses = 0;
    } else if (daysAgo < 90 - gracePeriod) {
      // Only decay after grace period from start of tracking
      consecutiveMisses++;
      health = max(MIN_HEALTH, health - decayAmount(consecutiveMisses));
    }
  }

  return health;
}

double decayAmount(int consecutiveMisses) {
  // Accelerating decay: 5%, 7.5%, 11.25%, ...
  return BASE_DECAY_RATE * pow(DECAY_ACCELERATION, consecutiveMisses - 1);
}

double recoveryAmount(double currentHealth) {
  // Recovery is inversely proportional to current health
  // Easier to recover when low, harder when already healthy
  return BASE_DECAY_RATE * (1 + (100 - currentHealth) / 100);
}
```

### Weekly Habits

For weekly habits, the algorithm checks against the weekly target:
1. Get logs for the current week (Sunday to Saturday)
2. If logs >= target, no decay for this week
3. If logs < target and week is complete, apply decay
4. Overflow: extra logs beyond weekly target add to buffer

### Day Boundary

The "current day" starts at 2:00 AM local time:

```dart
DateTime getCurrentDay() {
  final now = DateTime.now();
  // If before 2 AM, it's still "yesterday"
  if (now.hour < 2) {
    return DateTime(now.year, now.month, now.day - 1);
  }
  return DateTime(now.year, now.month, now.day);
}
```

---

## 4. Key Flows

### Authentication

```
┌──────────────┐     ┌─────────────┐     ┌──────────────┐
│  App Launch  │────▶│ Check Auth  │────▶│ Home Screen  │
└──────────────┘     └─────────────┘     └──────────────┘
                           │
                           ▼ (not signed in)
                     ┌─────────────┐
                     │ Sign In     │
                     │ Screen      │
                     └─────────────┘
                           │
                           ▼
                     ┌─────────────┐
                     │ Google      │
                     │ Sign-In     │
                     └─────────────┘
```

**Implementation:**
- `firebase_auth` + `google_sign_in` packages
- Auth state persisted by Firebase
- StreamProvider watches `authStateChanges()`
- Sign out clears local state, redirects to sign-in

### Habit CRUD

**Create:**
1. Tap FAB → modal sheet slides up
2. Enter name, select frequency
3. Save → Firestore add with `sort_order = existing.length`
4. Modal closes, habit appears in list

**Edit:**
1. Long press habit → same modal sheet, prefilled
2. Modify name/frequency
3. Save → Firestore update

**Delete:**
1. Long press → Edit modal includes delete button
2. Tap delete → confirmation dialog
3. Confirm → delete habit doc AND all logs for that habit
4. Modal closes, habit removed from list

**Reorder:**
1. Long press and drag
2. On drop → batch update `sort_order` for affected habits

### Logging

**Today (tap to toggle):**
```dart
void toggleToday(String habitId) async {
  final logId = '${habitId}_${formatDate(getCurrentDay())}';
  final doc = firestore.doc('users/$userId/logs/$logId');
  
  if (await doc.get().exists) {
    await doc.delete();
  } else {
    await doc.set({
      'habit_id': habitId,
      'logged_date': formatDate(getCurrentDay()),
      'created_at': FieldValue.serverTimestamp(),
    });
  }
}
```

**Backfill (swipe drawer):**
1. Swipe left on habit row → reveals 7-day drawer
2. Tap any day checkbox to toggle
3. Same toggle logic with that day's date
4. Tap close or swipe right → drawer closes

### Sync

Firestore handles sync automatically:
- Enable offline persistence (on by default for mobile)
- No explicit sync button needed
- No conflict resolution UI: last-write-wins
- Network indicator optional (could show offline badge)

---

## 5. Implementation Phases

### Phase 1: Foundation

**Goal:** Signed-in user sees empty home screen

- [ ] Flutter project init: `flutter create smpl_tracker`
- [ ] Firebase project setup in console
- [ ] Add Firebase config (google-services.json / GoogleService-Info.plist)
- [ ] Add packages: firebase_core, firebase_auth, google_sign_in
- [ ] Basic app shell with Riverpod provider scope
- [ ] Sign-in screen with Google button
- [ ] Auth state provider, route based on auth
- [ ] Empty home screen with app header

**Deliverable:** Can sign in with Google, see "Habits" title and empty state

### Phase 2: Core Data

**Goal:** Can create habits and see them in list

- [ ] Add cloud_firestore package
- [ ] Habit model class (with Firestore serialization)
- [ ] Log model class
- [ ] HabitService: CRUD operations
- [ ] Habits list provider (StreamProvider from Firestore)
- [ ] Home screen: habit list with basic rows
- [ ] FAB + Add habit modal (name + frequency picker)
- [ ] Create habit flow working

**Deliverable:** Can add habits, they persist across app restarts

### Phase 3: Logging

**Goal:** Can log habits for today and past days

- [ ] LogService: toggle log for date
- [ ] Logs provider (scoped to habit)
- [ ] Tap habit row → toggles today's log
- [ ] Logged check mark appears/disappears
- [ ] Swipe gesture on habit row
- [ ] Backfill drawer UI (7 day checkboxes)
- [ ] Drawer toggle functionality

**Deliverable:** Full logging flow works, persists to Firestore

### Phase 4: Health & Polish

**Goal:** Health bars show correct values, UI matches mockups

- [ ] Decay algorithm implementation
- [ ] Health calculation provider
- [ ] Health bar colors (blue/green/yellow/red)
- [ ] Health percentage display
- [ ] Weekly progress pips for weekly habits
- [ ] Edit habit (long press → prefilled modal)
- [ ] Delete habit with confirmation
- [ ] Drag to reorder

**Deliverable:** App is functionally complete

### Phase 5: Final Polish

**Goal:** Feels good to use

- [ ] Animations: check mark scale-in, health bar transitions
- [ ] Haptic feedback on tap
- [ ] Loading states for async operations
- [ ] Error handling with snackbars
- [ ] Empty state illustration/message
- [ ] Sign out option (settings or profile)
- [ ] Test on physical device
- [ ] Build release APK

**Deliverable:** Shippable v1

---

## 6. Technical Decisions

### State Management: Riverpod

Why Riverpod over Provider/Bloc:
- Compile-time safety for providers
- Better async support (AsyncValue)
- Easy to scope providers to user context
- Good Firestore integration patterns

**Key providers:**
```dart
// Auth state
final authProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// Current user's habits
final habitsProvider = StreamProvider<List<Habit>>((ref) {
  final user = ref.watch(authProvider).value;
  if (user == null) return Stream.value([]);
  return HabitService(user.uid).watchHabits();
});

// Logs for a specific habit
final logsProvider = StreamProvider.family<List<Log>, String>((ref, habitId) {
  final user = ref.watch(authProvider).value;
  if (user == null) return Stream.value([]);
  return LogService(user.uid).watchLogs(habitId);
});

// Computed health for a habit
final healthProvider = Provider.family<double, String>((ref, habitId) {
  final habit = ref.watch(habitProvider(habitId));
  final logs = ref.watch(logsProvider(habitId)).value ?? [];
  return calculateHealth(habit, logs);
});
```

### Folder Structure

```
lib/
├── main.dart
├── app.dart                    # MaterialApp, router
├── models/
│   ├── habit.dart
│   └── log.dart
├── services/
│   ├── auth_service.dart
│   ├── habit_service.dart
│   └── log_service.dart
├── providers/
│   ├── auth_provider.dart
│   ├── habits_provider.dart
│   └── logs_provider.dart
├── utils/
│   ├── decay.dart              # Health calculation
│   └── date_utils.dart         # Day boundary, formatting
├── screens/
│   ├── sign_in_screen.dart
│   └── home_screen.dart
└── widgets/
    ├── habit_row.dart
    ├── health_bar.dart
    ├── backfill_drawer.dart
    ├── add_habit_modal.dart
    └── weekly_pips.dart
```

### Error Handling

**Network errors:** Firestore offline mode handles gracefully. Show brief snackbar only if operation takes too long.

**Validation errors:** Prevent invalid input (empty name, etc.) via disabled save button.

**Auth errors:** Show error message on sign-in screen, allow retry.

**Pattern:**
```dart
try {
  await operation();
} on FirebaseException catch (e) {
  // Log to console for debugging
  debugPrint('Firebase error: ${e.code} - ${e.message}');
  // Show user-friendly message
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Something went wrong. Try again.')),
  );
}
```

### Performance

- **Native splash:** Use flutter_native_splash for instant launch screen
- **Lazy loading:** Firestore streams only fetch when widget mounts
- **Limit query depth:** Only fetch logs from last 90 days for health calc
- **Batch writes:** Use batched writes when reordering multiple habits

---

## 7. Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^2.24.0
  firebase_auth: ^4.16.0
  cloud_firestore: ^4.14.0
  google_sign_in: ^6.2.0
  
  # State management
  flutter_riverpod: ^2.4.0

  # UI helpers
  flutter_native_splash: ^2.3.0    # Fast app launch
  flutter_slidable: ^3.0.0         # Swipe gestures for backfill drawer
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

**Intentionally omitted:**
- No routing package (simple enough with Navigator)
- No form validation package (minimal forms)
- No analytics (personal use)
- No crash reporting (personal use)

---

## 8. Testing Strategy

### Manual Testing Checklist

Before shipping:
- [ ] Fresh install sign-in flow
- [ ] Create daily habit, log today
- [ ] Create weekly habit, log 3 days
- [ ] Backfill a past day
- [ ] Toggle log off/on
- [ ] Edit habit name
- [ ] Delete habit
- [ ] Reorder habits
- [ ] Kill app, reopen (data persists)
- [ ] Turn off network, use app, turn on (syncs)
- [ ] Sign out and back in

### Device Testing

- Primary: Physical Android phone (daily driver)
- Secondary: Android emulator for quick iterations
- Test on both while developing

---

## Notes

**Intentional simplifications for v1:**
- No unit tests (time constraint, personal use)
- No CI/CD (sideload APK directly)
- No analytics or crash reporting
- No dark mode
- No widget

**If we have extra time:**
- Add daily reminder notification
- Add empty state illustration
- Add subtle animations
