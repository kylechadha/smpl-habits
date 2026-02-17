# Design Guide: smpl-tracker

Reference mockup: `mockups/13-final-with-add-screen.html`

---

## 1. Design Principles

### Minimal Friction
One-tap logging is the core interaction. The app should open and be usable in under one second. No unnecessary screens, confirmations, or steps between the user and their goal.

### Decay Model Psychology
The visual design emphasizes habit health rather than streak counts. Colors shift gradually from healthy (green) to warning (yellow) to critical (red), creating gentle urgency without shame. Overflow (blue glow) rewards consistency without making it feel mandatory.

### Clean, Uncluttered Interface
Every element earns its place. White cards on a subtle gray background. Generous padding. No decorative elements. The health bar and percentage tell the story at a glance.

---

## 2. Color System

### Backgrounds
| Element | Color | Hex |
|---------|-------|-----|
| Screen background | Light gray | `#f7f8fa` |
| Card background | White | `#ffffff` |
| Drawer background | Dark | `#1a1a2e` |
| Modal overlay | Black 50% | `rgba(0, 0, 0, 0.5)` |

### Health Status Colors
| State | Range | Primary | Gradient End | Text |
|-------|-------|---------|--------------|------|
| Overflow | 100%+ | `#3b82f6` | `#60a5fa` | `#3b82f6` |
| Healthy | 70-99% | `#10b981` | `#34d399` | `#10b981` |
| Warning | 40-69% | `#f59e0b` | `#fbbf24` | `#f59e0b` |
| Critical | <40% | `#ef4444` | `#f87171` | `#ef4444` |

### Text Colors
| Use | Hex |
|-----|-----|
| Primary text | `#1a1a2e` |
| Secondary text | `#6b7280` |
| Tertiary/muted | `#9ca3af` |
| On dark backgrounds | `#ffffff` |

### Interactive Elements
| Element | Default | Hover/Active |
|---------|---------|--------------|
| FAB / Primary button | `#1a1a2e` | `#2d2d4a` |
| Disabled button | `#e5e7eb` | - |
| Form input border (focus) | `#3b82f6` | - |

---

## 3. Typography

### Font Stack
```css
font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
```

### Scale
| Element | Size | Weight | Color |
|---------|------|--------|-------|
| App title ("Habits") | 32px | 700 | `#1a1a2e` |
| Modal title | 22px | 700 | `#1a1a2e` |
| Habit name | 16px | 600 | `#1a1a2e` |
| Form input | 17px | 500 | `#1a1a2e` |
| Health percentage | 13px | 700 | (status color) |
| Date subtitle | 14px | 500 | `#9ca3af` |
| Form label | 13px | 600 | `#6b7280` |
| Pip label ("2/3") | 11px | 500 | `#9ca3af` |
| Drawer day label | 10px | 600 | `rgba(255,255,255,0.5)` |

### Line Height
- Body text: 1.5
- Headings: 1.2-1.3

---

## 4. Components

### Habit Row
**Container**
- Height: 80px
- Background: `#ffffff`
- Border radius: 16px
- Margin: 0 12px 8px
- Shadow: `0 1px 3px rgba(0, 0, 0, 0.04)`
- Padding: 14px 16px

**Layout**
```
+--------------------------------------------------+
| [Check] [Habit Name]              [Pips] [2/3]   |
| [========Health Bar========]              [85%]  |
+--------------------------------------------------+
```

**Default state**: Name on left, weekly pips (if applicable) on right, health bar spanning full width below.

**Logged state**: Green checkmark appears to the left of habit name (22px circle, `#10b981` background, white check icon).

**Drawer open state**: Dark drawer slides in from the right, overlaying the habit row content.

### Progress Bar
- Track height: 6px
- Track background: `#f3f4f6`
- Track border radius: 3px
- Fill uses gradient based on health status
- Overflow state: `box-shadow: 0 0 12px rgba(59, 130, 246, 0.5)` with pulse animation

### Weekly Progress Dots
```
[filled] [filled] [empty] [empty]  2/4
```
- Dot size: 8px diameter
- Gap: 4px between dots
- Filled: `#10b981`
- Empty: `#e5e7eb`
- Label: 11px, `#9ca3af`, 6px left margin

### Floating Action Button (FAB)
- Size: 56px x 56px
- Border radius: 16px
- Background: `#1a1a2e`
- Icon: 24px white plus
- Shadow: `0 4px 20px rgba(26, 26, 46, 0.3)`
- Position: 24px from bottom, 20px from right
- Hover: scale(1.05), increased shadow

### Add Habit Modal (Bottom Sheet)
- Background: `#ffffff`
- Top border radius: 24px
- Padding: 24px
- Shadow: `0 -10px 40px rgba(0, 0, 0, 0.15)`
- Drag handle: 40px x 4px, `#e5e7eb`, centered

**Form input**
- Height: 52px
- Border radius: 12px
- Background (default): `#f7f8fa`
- Background (focus): `#ffffff`
- Border (focus): 2px `#3b82f6`

**Frequency toggle**
- Container: `#f7f8fa`, 12px radius, 4px padding
- Option height: 44px
- Active option: white background, subtle shadow

**Weekly picker**
- Number buttons: 44px x 44px
- Default: `#f7f8fa` background, `#6b7280` text
- Active: `#1a1a2e` background, white text

**Save button**
- Height: 56px
- Border radius: 14px
- Disabled: `#e5e7eb` background, `#9ca3af` text

### Checkmark Indicator
- Circle: 22px diameter
- Background: `#10b981`
- Icon: 14px white checkmark, stroke-width 3
- Animation: scale from 0 to 1, 200ms ease

---

## 5. Interactions

### Single Tap (Habit Row)
- Toggles today's log on/off
- Checkmark appears/disappears with scale animation
- Health percentage updates immediately

### Swipe Left (Habit Row)
- Reveals 7-day backfill drawer
- Dark drawer slides in from right, overlaying the row (use `flutter_slidable` package)
- Each day shows checkbox (32px x 32px, 8px radius)
- Today highlighted with blue accent
- Close button (chevron right) on far right

### Long Press (Habit Row)
- Opens edit modal (same as add habit modal, prefilled)
- Initiates drag-to-reorder if held and moved
- Haptic feedback on Android

### Tap FAB
- Opens Add Habit bottom sheet
- Background dims with blur overlay
- Modal slides up from bottom

### Dismiss Modal
- Tap X button in header
- Tap overlay background
- Swipe down on modal (drag handle affordance)

---

## 6. Layout

### Reference Width
375px (iPhone SE / small Android)

### Spacing Scale
```
4px   - tight gaps (between pips)
8px   - small gaps (between elements)
12px  - card margins
16px  - card padding, standard gaps
20px  - FAB from edge
24px  - modal padding, section spacing
32px  - large section breaks
48px  - major separations
```

### Safe Areas
- Status bar: 48px height
- FAB clearance: habit list has 100px bottom padding
- Modal respects bottom safe area

### Card System
- Cards have 12px horizontal margin from screen edge
- 8px vertical gap between cards
- 16px border radius

---

## 7. States

### Empty State (No Habits)
- Show encouraging message centered in list area
- Example: "Tap + to add your first habit"
- Subtle, not overwhelming

### Logged Today
- Green checkmark appears to the left of habit name
- Checkmark animates in with scale
- No other visual changes to row

### Drawer Open (Backfill)
- Dark drawer (`#1a1a2e`) slides in from right, overlaying the habit row
- 7 day columns with labels (Mon-Sun)
- Checked days: green checkbox with white check
- Unchecked days: semi-transparent border
- Today: blue accent color
- Close button on right edge (or swipe right to dismiss)

### Weekly vs Daily Display
**Daily habits**: No pips shown, just name + health bar

**Weekly habits**: Pips shown on right side
- Number of pips matches target (e.g., 3 pips for 3x/week)
- Filled pips = logged this week
- Label shows "2/3" format

---

## 8. Accessibility

### Touch Targets
- Minimum 48dp for all interactive elements
- Drawer checkboxes: 32px (acceptable with spacing)
- FAB: 56px
- Form inputs: 52px height

### Color Independence
- Health status always shown as percentage number alongside color
- Checkmark icon provides logged confirmation beyond green color
- Critical habits use both red color and low percentage

### Screen Readers
Semantic labels for key elements:
- Habit row: "[Name], [health]% health, [logged/not logged] today"
- Weekly pips: "[current] of [target] completed this week"
- FAB: "Add new habit"
- Health bar: decorative (percentage provides info)

### Motion
- Respect reduced motion preferences
- Pulse animation on overflow should be disableable
- Scale animations are subtle (200ms)

---

## 9. Animation Timing

| Animation | Duration | Easing |
|-----------|----------|--------|
| Checkmark scale in | 200ms | ease |
| Drawer slide | 300ms | ease |
| Health bar fill | 300ms | ease |
| FAB hover scale | 150ms | ease |
| Modal appear | 300ms | ease-out |
| Overflow pulse | 2000ms | ease-in-out (infinite) |

---

## 10. Platform Notes

### Android (Primary)
- Follow Material Design touch feedback (ripple on tap)
- Use system navigation gestures
- Support dark mode in v2 (out of scope for v1)

### iOS (Future)
- Design translates well
- Bottom sheet pattern is native
- Safe area handling required
