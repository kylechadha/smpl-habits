# Process

How we build smpl-habits.

## Philosophy

1. **Documentation first** — understand what we're building before coding
2. **Iterate on design** — generate multiple mockups, pick direction, then build
3. **Simple MVP** — minimal features, ship fast, iterate later

## Workflow

### Phase 1: Discovery
1. PM interview to capture requirements, pain points, must-haves vs nice-to-haves
2. Write PRD (`docs/02-prd.md`)

### Phase 2: Design
1. Generate 3-5 mockup variations (different styles, typography, layouts)
2. Review, pick direction, iterate on UX details
3. Document in design guide (`docs/03-design-guide.md`)

### Phase 3: Technical Planning
1. Choose framework and storage approach
2. Define data model and architecture
3. Plan implementation phases
4. Document in `docs/04-system-design.md`

### Phase 4: Build
1. Set up development environment
2. Implement in phases, tracking progress in `docs/backlog.md`
3. Test on emulator and physical device
4. Document testing in `docs/06-testing-unit.md` and `docs/07-testing-manual.md`

### Phase 5: Ship
1. Build release APK
2. Sideload to physical device for daily use

## Task Tracking

Use `docs/backlog.md` for kanban-style tracking:
- **Done** — completed work with dates
- **Icebox** — deferred to future versions
