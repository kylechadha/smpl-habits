# Manual Testing

Checklist for v1 MVP verification.

---

## Pre-Ship Checklist

### Authentication
- [ ] Fresh install opens to sign-in screen
- [ ] Google Sign-In completes successfully
- [ ] After sign-in, navigates to home screen
- [ ] Sign out redirects to sign-in screen
- [ ] Re-sign in restores all data

### Habit CRUD
- [ ] Create habit - defaults to weekly 5x
- [ ] Create daily habit - appears in list
- [ ] Create weekly habit (3x/week) - shows pips
- [ ] Edit habit name - updates immediately
- [ ] Edit habit frequency - updates display
- [ ] Delete habit - removed from list
- [ ] Delete confirmation dialog appears
- [ ] Reorder habits via drag handle (grip dots) - persists
- [ ] New habit appears at bottom of list
- [ ] Long press opens edit modal (doesn't conflict with drag)

### Reset Score
- [ ] Long press habit → tap reset icon (↻ yellow) → confirmation dialog
- [ ] Dialog shows "Health will reset to 100%. Your log history will be kept."
- [ ] Cancel dismisses dialog
- [ ] Reset → health shows 100%, logs still visible in backfill drawer
- [ ] After reset, decay starts fresh from reset date

### Pause / Unpause
- [ ] Long press habit → tap pause icon (⏸) → habit shows PAUSED badge
- [ ] Paused habit: dimmed, no health bar, shows "Paused - long press to resume"
- [ ] Paused habit: tap does nothing (no log toggle)
- [ ] Paused habit: swipe does nothing (no backfill drawer)
- [ ] Paused habit: weekly pips hidden
- [ ] Long press paused habit → tap play icon (▶) → habit resumes
- [ ] Resumed habit: health resets to 100%

### Logging
- [ ] Tap habit - toggles today's log
- [ ] Checkmark appears/disappears with animation
- [ ] Health percentage updates on log
- [ ] Swipe left - reveals rolling 7-day drawer (last 7 days, not week boundaries)
- [ ] Drawer shows today highlighted (brighter label)
- [ ] Tap day in drawer - toggles that day's log
- [ ] Close drawer - returns to normal view
- [ ] Backfill past day - health updates
- [ ] On Sunday, previous Saturday is visible in drawer

### Health Display
- [ ] New habit starts at 100% (green)
- [ ] Overflow shows blue with glow (>100%)
- [ ] Warning shows yellow (40-69%)
- [ ] Critical shows red (<40%)
- [ ] Weekly pips fill correctly
- [ ] Pips count matches "2/3" label

### Data Persistence
- [ ] Kill app, reopen - data persists
- [ ] Clear app from recents, reopen - data persists
- [ ] Device restart - data persists

### Offline Behavior
- [ ] Turn off network - app still functions
- [ ] Create habit offline - appears in list
- [ ] Log habit offline - checkmark appears
- [ ] Turn on network - data syncs
- [ ] No duplicate entries created

### Multi-Device Sync
- [ ] Create habit on device A - appears on device B
- [ ] Log on device A - syncs to device B
- [ ] Edit on device B - syncs to device A

### Edge Cases
- [ ] Empty state shows when no habits
- [ ] Max habit name (50 chars) displays correctly
- [ ] Many habits (10+) scrolls smoothly
- [ ] Rapid tapping doesn't cause issues
- [ ] 2am day boundary respects logs correctly

---

## Device Testing Matrix

### Primary Development
- **Device**: Physical Android phone (daily driver)
- **Android version**: Test on current device version
- **Screen size**: Various (use phone as-is)

### Secondary Testing
- **Android Emulator**: Quick iteration during development
- **Pixel emulator**: Standard Android reference

### Known Limitations (v1)
- iOS not tested (Flutter allows later)
- Tablets not optimized (phone-first)
- Dark mode not supported

---

## Bug Reporting

For personal use, track issues in:
- GitHub Issues (if sharing repo)
- Notes app on phone
- CLAUDE.md session notes

Include:
1. Steps to reproduce
2. Expected behavior
3. Actual behavior
4. Screenshot if UI issue

---

## Performance Checks

- [ ] Cold start under 1 second
- [ ] Warm start instant
- [ ] No jank during scroll
- [ ] Animations smooth (60fps)
- [ ] No memory leaks on repeated use

---

## Security Verification

- [ ] Cannot access other users' data
- [ ] Auth token not exposed in logs
- [ ] Firestore rules block unauthorized access
