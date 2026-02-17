# smpl-tracker

Android habit tracker app - simple, on-device, minimal.

## Project Status
- **Phase**: Pre-development (documentation)
- **Next step**: Product manager interview to define requirements

## Process

We follow a documentation-first approach:

1. **Interview** - PM subagent interviews user to understand requirements
2. **PRD** - Document product requirements in `docs/02-prd.md`
3. **Design** - Generate mockups, iterate on UX, confirm direction
4. **Implementation** - Build with clear phases tracked in `docs/05-implementation.md`
5. **Testing** - Document testing approach, verify on device/emulator

### Documentation Structure
```
docs/
├── 01-process.md           # How we work (this workflow)
├── 02-prd.md               # Product requirements
├── 03-design-guide.md      # Visual design decisions
├── 04-system-design.md     # Architecture + implementation phases
├── 05-testing.md           # Testing strategy (TBD)
└── backlog.md              # Kanban-style task tracking
```

## Subagents

Use these for delegated work:
- `product-manager` - PRD work, feature scoping, /interview
- `designer` - Mockups, UX iteration
- `frontend-dev` - UI implementation (Android/Kotlin or cross-platform TBD)
- `architect` - Technical decisions, system design

Always set `run_in_background: true` for subagent Tasks.

## Tech Stack (TBD)

To be decided during interview:
- **Framework**: Native Android (Kotlin) vs cross-platform (Flutter, React Native)
- **Storage**: Room/SQLite on device
- **Backup**: Local exports, Google Drive, or Firebase (to discuss)
- **Testing**: Emulator + physical device sideloading

## Android Development Notes

Since this is our first Android app, document learnings here:

### Setup (TBD)
- Android Studio installation
- Emulator configuration
- Device debugging setup

### Deployment Options
1. **Sideloading** - Direct APK install on device (easiest for personal use)
2. **Play Store** - Full publishing (requires developer account, review process)
3. **Internal testing** - Play Store beta track (simpler review)

## Git Workflow

- Conventional commits: `feat:`, `fix:`, `docs:`, `refactor:`
- Always run checks before committing
- Show files changed before commit, get approval

## Commands

- `/interview` - Start PM interview to gather requirements
- `/review` - Code review working changes
- `/pr` - Commit and create PR

## Session Notes

### 2026-01-10: Project Kickoff
- Reviewed opencamp/web process, adapted for this project
- Completed PM interview, wrote PRD

**Key decisions:**
- **Decay model**: Habits start at 100%, decay on missed targets (accelerating), recover inversely
- **Overflow banking**: Extra logs buffer against decay AND display above 100%
- **Framework**: Flutter for rapid iteration
- **Storage**: Firebase Firestore (cloud-first, offline support built-in)
- **Auth**: Google Sign-In via Firebase Auth
- **Infrastructure**: New Firebase project (same GCP account, separate from opencamp)
- **Day boundary**: 2am local time
- **Week start**: Sunday
- **Frequencies**: Daily or X/week only for v1
- **Binary logging**: Done/not done, no counts

**Next steps:**
1. Generate 3-5 design mockups with different visual styles
2. Pick direction and iterate on UX
3. Set up Flutter dev environment
4. Implement
