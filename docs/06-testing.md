# Testing Strategy

Manual testing approach for v1 MVP.

---

## Pre-Ship Checklist

### Authentication
- [ ] Fresh install opens to sign-in screen
- [ ] Google Sign-In completes successfully
- [ ] After sign-in, navigates to home screen
- [ ] Sign out redirects to sign-in screen
- [ ] Re-sign in restores all data

### Habit CRUD
- [ ] Create daily habit - appears in list
- [ ] Create weekly habit (3x/week) - shows pips
- [ ] Edit habit name - updates immediately
- [ ] Edit habit frequency - updates display
- [ ] Delete habit - removed from list
- [ ] Delete confirmation dialog appears
- [ ] Reorder habits via drag - persists

### Logging
- [ ] Tap habit - toggles today's log
- [ ] Checkmark appears/disappears with animation
- [ ] Health percentage updates on log
- [ ] Swipe left - reveals 7-day drawer
- [ ] Tap day in drawer - toggles that day's log
- [ ] Close drawer - returns to normal view
- [ ] Backfill past day - health updates

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
