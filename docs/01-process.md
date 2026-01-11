# Process

How we build smpl-tracker.

## Philosophy

1. **Documentation first** - Understand what we're building before coding
2. **Delegate to subagents** - Main Claude coordinates, subagents do focused work
3. **Iterate on design** - Generate multiple mockups, pick direction, then build
4. **Simple MVP** - On-device storage, minimal features, ship fast

## Workflow

### Phase 1: Discovery
1. PM subagent interviews user (`/interview`)
2. Capture requirements, pain points, must-haves vs nice-to-haves
3. Write PRD (`docs/02-prd.md`)

### Phase 2: Design
1. Generate 3-5 mockup variations (different styles, typography, layouts)
2. Review with user, pick direction
3. Iterate on UX details
4. Document in design guide (`docs/04-design-guide.md`)

### Phase 3: Technical Planning
1. Decide on framework (native vs cross-platform)
2. Define data model and storage approach
3. Plan implementation phases
4. Document in `docs/03-implementation.md`

### Phase 4: Build
1. Set up Android development environment
2. Implement in phases, tracking progress in backlog
3. Test on emulator and physical device
4. Document testing approach in `docs/05-testing.md`

### Phase 5: Ship
1. Decide deployment: sideload vs Play Store
2. If Play Store: set up developer account, prepare listing
3. Release and document learnings

## Task Tracking

Use `docs/backlog.md` for kanban-style tracking:
- **Raw Ideas** - Unrefined thoughts
- **Up Next** - Queued for work
- **In Progress** - Currently active
- **Done** - Completed with dates

## Documentation Updates

After completing work:
1. Update `backlog.md` status
2. Update relevant phase docs
3. Add session notes to `CLAUDE.md` for context preservation
