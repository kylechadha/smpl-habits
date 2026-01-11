# Future Considerations

Features and enhancements deferred from v1 MVP.

---

## v2 Features

### Enhanced Logging
- **Count-based habits** - Track quantities (e.g., 8 glasses of water)
- **Per-habit reminders** - Notifications at custom times per habit

### Visualization & Insights
- **Statistics view** - Historical trends, averages, patterns
- **Streak visualization** - Calendar heatmap or streak counters
- **History view** - See past weeks/months of logs

### Customization
- **Dark mode** - Follow system preference
- **Categories/colors** - Group habits visually
- **Notes on habits** - Why this habit matters, tips

### Platform Expansion
- **iOS build** - Flutter makes this straightforward
- **Home screen widget** - Quick glance at habit health
- **Web UI** - Read from same Firestore (view-only or full CRUD)

### Data & Portability
- **Data export** - JSON/CSV export for backup or analysis
- **Import** - Migrate from other habit trackers

---

## Technical Improvements

### Performance
- **Widget for Android** - Glance at habits without opening app
- **Background sync** - Silent sync when app is closed

### Reliability
- **Conflict resolution UI** - Handle rare sync conflicts gracefully
- **Offline indicator** - Show sync status when relevant

### Testing
- **Automated tests** - Unit tests for decay algorithm, widget tests
- **CI/CD pipeline** - Automated builds on push

---

