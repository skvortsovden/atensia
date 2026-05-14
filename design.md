# Атенція — UI/UX Design Document

**Version:** 1.7.5  
**Language:** Ukrainian only (`uk_UA`)  
**Orientation:** Portrait only

---

## 1. Design System

### Colour palette

| Role | Value |
|---|---|
| Background | `#FFFFFF` white |
| Primary text | `#000000` black |
| Secondary text | `Colors.black54` (~55% black) |
| Hint / placeholder text | `Colors.black38` (~38% black) |
| Disabled / subdued | `Colors.black26`, `Colors.black12` |
| Active control fill | black |
| Active control label | white |
| Inactive control fill | white |
| Inactive control label | black |

No colour is used for meaning or decoration — the entire UI is monochrome.

### Typography (Fixel font family by MacPaw)

| Token | Font | Weight | Size | Usage |
|---|---|---|---|---|
| `headlineLarge` | Fixel Display | 700 | 24 sp | Screen titles, section headers |
| `headlineMedium` | Fixel Display | 600 | 20 sp | Sub-titles, selected date in calendar toolbar |
| `titleMedium` | Fixel Text | 600 | 16 sp | Dialog titles, card headers, calendar month title |
| `bodyLarge` | Fixel Text | 400 | 16 sp | Primary body copy, list items, switch labels |
| `bodyMedium` | Fixel Text | 400 | 14 sp | Secondary body, date subline in Today view |
| Section labels | Fixel Text | 700 | 10–11 sp | ALL-CAPS with 1.2–1.4 letter-spacing |
| Note / stat micro | Fixel Text | 400/700 | 9–13 sp | Chart labels, version string, stat counts |

### Spacing & shape

| Token | Value |
|---|---|
| Standard border | 2 px solid black |
| Corner radius (controls, cards) | 8 dp |
| Corner radius (primary buttons) | 12–14 dp |
| Card padding | 16 dp |
| Screen horizontal margin | 20 dp |
| No shadows | All depth is implied by 2 px borders |

### Interactive feedback

- **Haptic:** `HapticFeedback.mediumImpact()` fired on every toggle, circumplex button tap, and the save button.
- **Animation duration:** 140 ms for fill/colour transitions on segmented controls and health toggles.
- **Fade durations:** 200 ms for opacity changes (e.g. circumplex label); 250 ms for period dot indicators; 350 ms for page transitions inside Onboarding.

---

## 2. App Shell

### Bottom Navigation Bar

A persistent bar at the bottom of `MainScreen`, separated from the screen content by a 2 px black top border (no shadow, no elevation).

| Index | Icon (inactive → active) | Label |
|---|---|---|
| 0 | `calendar_month_outlined` → `calendar_month` | Календар |
| 1 | `wb_sunny_outlined` → `wb_sunny` | Сьогодні |
| 2 | `bar_chart_outlined` → `bar_chart` | Звіт |
| 3 | `tune_outlined` → `tune` | Налаштування |

- **Default tab on launch:** Сьогодні (index 1).
- Selected icon and label: black. Unselected: `#999999`.
- Label font: Fixel Text, 11 sp, bold when selected.
- `IndexedStack` keeps all four screens alive; switching tabs does not rebuild them.
- Navigating to **Календар** while already on it re-creates the view with a fresh `ValueKey` (resets the selected day).

### Loading screen

A plain `#FFFFFF` `Scaffold` shown while `SharedPreferences` initialises asynchronously. Visually continues the native launch screen — no spinner.

---

## 3. Splash Screen

Displayed before the main shell on cold start (only when using the `SplashScreen` route variant — in 1.7.5 the Consumer in `main.dart` takes over this role directly).

| Element | Detail |
|---|---|
| Background | White |
| Logo | `assets/atensia-logo.png`, 72×72 |
| App name | headlineLarge, 42 sp, centred |
| Tagline | headlineMedium, centred |
| Animation | Fade-in (900 ms, `Curves.easeIn`) |

After 1 400 ms → **MainScreen** fade-transition (400 ms).  
After 1 800 ms on first launch → **Onboarding** fade-transition (400 ms).

---

## 4. Onboarding (4 pages)

Shown only on first launch. Horizontal `PageView` with `NeverScrollableScrollPhysics` — user can only advance via buttons.

### Progress indicator
A row of 4 dots centred at the top. Active dot: 20×8 dp black pill with radius 4. Inactive dot: 8×8 dp grey pill. Animated with 250 ms duration.

---

### Page 1 — Name

| Element | Detail |
|---|---|
| Title | "Як до тебе звертатись?" — 28 sp, bold |
| Text field | Underline style; hint "Введи своє ім'я…"; `textCapitalization.words`; max 30 chars; auto-focused |
| Primary button | "Далі" |

---

### Page 2 — Greeting

| Element | Detail |
|---|---|
| Title | "Вітаю, {name}!" (or "Вітаю, друже!" if blank) — 36 sp, 800 weight |
| Body text | Short welcome copy — 18 sp, `Colors.black87` |
| Primary button | "Далі" |

---

### Page 3 — Notifications

| Element | Detail |
|---|---|
| Title | "Нагадування" — 28 sp, bold |
| Description | 16 sp, `Colors.black54` |
| Reminders toggle row | Bordered container (2 px, radius 8); label left, `Switch` right; same style as Settings reminders |
| Time selector | Appears below the toggle when enabled; 2 px bordered container; label + bold time value |
| Primary button | "Пропустити" → "Готово" (changes when toggle is on) |

---

### Page 4 — Guide

| Element | Detail |
|---|---|
| Title | "Як користуватись додатком?" — 24 sp, bold |
| Body | 7-step numbered guide; 16 sp, 1.6 line-height, `Colors.black87`; inside `SingleChildScrollView` |
| Primary button | "Зрозуміло" → calls `markLaunched()` and pushes **MainScreen** |

---

### Shared: Primary Button (`_PrimaryButton`)
Full-width, 52 dp tall, radius 14, black fill, white label, no elevation. Used on all 4 onboarding pages and in dialogs.

---

## 5. Today View (Сьогодні)

Scrollable `SingleChildScrollView` with 20 dp horizontal padding.

Tapping anywhere outside a text field dismisses the keyboard.

### Header row

| Element | Detail |
|---|---|
| Greeting | "Вітаю, {name}!" headlineLarge |
| Date line | "Сьогодні {день тижня, d MMMM}" — bodyMedium, `Colors.black54` |
| Day count line | "Твій N-й день записів [поспіль]." — bodyMedium, `Colors.black54`; day count in bold |
| Logo button | `assets/atensia-logo.png` 32 dp tall, top-right; opens **Guide** bottom sheet |

### Circumplex selector

Two labelled segmented controls (see §8 for shared component spec).

| Axis | Options |
|---|---|
| Настрій (valence) | Погано / Нормально / Чудово |
| Енергія (arousal) | Виснажено / Нормально / Бадьоро |

Below the section title an animated quadrant label fades in at 18 sp, Fixel Display regular, `Colors.black45` once both axes are set (e.g. "на підйомі"). Opacity animates in 200 ms.

Tapping the already-selected button clears that axis.

### Health toggles

Section label "ЩО ТУРБУЄ?" (10 sp, 700 weight, 1.2 letter-spacing, `Colors.black54`).

A single 2 px bordered container (radius 8) with two side-by-side cells divided by a 2 px black vertical divider:

| Cell | Label |
|---|---|
| Left | Хвороба |
| Right | Біль |

Active cell: black fill, white text. Animated 140 ms. Tap triggers `HapticFeedback.mediumImpact()`.

### Habit list (Дозвілля)

Section label "ДОЗВІЛЛЯ" at headlineLarge size.

Each habit is a full-width row with:
- Habit name (bodyLarge)
- Checkbox on the right — custom 22×22 dp square, 2 px black border, radius 4; filled black with white tick when checked
- Tapping the row (anywhere) toggles the habit

### Note field

Section label "НОТАТКА".

Multiline `TextField`:
- Filled style, fill colour `Colors.black` at 4% opacity
- No visible border, radius 10
- Hint: "Що сталося важливого сьогодні?"
- Max 140 chars; counter shown at bottom-right in 11 sp `Colors.black38`
- `textCapitalization.sentences`

---

## 6. Calendar / History View (Календар)

Two-part layout: calendar (fixed height 345 dp) + detail panel (flexible).

### Calendar widget (`TableCalendar`)

| Setting | Value |
|---|---|
| Locale | `uk_UA` |
| First day of week | Monday |
| Row height | 44 dp |
| Days-of-week row height | 22 dp |

**Header:** Month name centred, Fixel Text 600 15 sp. Chevron arrows (`chevron_left` / `chevron_right`, 20 dp). No format toggle button.

**Day cells:**
- Default: black 16 sp text
- Weekend: `Colors.black54`
- Outside month: `Colors.black26`
- Today: outlined black circle (2 px border, no fill)
- Selected: filled black circle, white text

**Day markers** (positioned 3 dp above the bottom edge of the cell):

| Condition | Marker |
|---|---|
| `isSick == true` | Solid black circle 6×6 dp |
| All habits completed | Solid black circle 7×7 dp |
| Partial activity (some habits done OR state set) | Outlined black circle 6×6 dp, 1.5 px border |
| No data | No marker |

### Day detail panel

Separated from the calendar by a 2 px full-width black `Divider`. Scrollable.

**No data state:**
- Centred date label (titleMedium, bold)
- "Дані за цей день відсутні" (bodyMedium, `Colors.black38`)
- **"Додати"** outlined button (2 px border, radius 10) → opens `EditDayScreen`

**Future day:**
- Centred date label
- "Цей день ще не настав" (`Colors.black38`)

**Has data:**
- Centred date label (bold)
- Info rows (label + value) for: Почуваюсь / Турбує / Дозвілля
- Note text in italic if present (`Colors.black54`, 14 sp)
- **"Змінити"** outlined button → opens `EditDayScreen`

---

## 7. Edit Day Screen

Full-screen sheet pushed via `MaterialPageRoute`.

### Header
- `IconButton` `arrow_back` (left-aligned) → `Navigator.pop()`
- Date label centred (headlineMedium)
- Row uses a `Stack` so the back button doesn't disturb the centred title

### Content (scrollable)

Same layout as Today View:
1. Circumplex selector  
2. Health toggles  
3. Дозвілля habits  
4. Нотатка text field (max 140 chars)

Changes are held in local state — **not** persisted until save.

### Save button

Pinned to the bottom outside the scroll area. Full-width, height 52 dp, padding `fromLTRB(20, 8, 20, 20)`. Black fill, radius 12, label "Зберегти", white 700 16 sp. Triggers `HapticFeedback.mediumImpact()` on tap.

---

## 8. Shared UI Component — Circumplex Buttons (`CircumplexButtons`)

Two stacked `_TripleSelector` components.

### `_TripleSelector`

Label rendered as ALL-CAPS 10 sp 700 weight 1.2 letter-spacing text above the control.

A single 2 px bordered container (radius 8) containing 3 equal cells separated by 2 px black dividers. Each cell:
- `AnimatedContainer` 140 ms, black fill when selected, white when unselected
- Text 14 sp 600 weight, colour inverts with fill
- Full-height (uses `IntrinsicHeight` + `CrossAxisAlignment.stretch`)
- Vertical padding 13 dp

---

## 9. Stats / Report View (Звіт)

Scrollable column with 20 dp horizontal padding.

### Period selector

A single-row button group:

| Button | Label | Icon |
|---|---|---|
| Тиждень | text | — |
| Місяць | text | — |
| Рік | text | — |
| Custom | — | `date_range_outlined` 18 dp |

Active: black fill, white text/icon; inactive: 2 px border, black text. Radius 8. All buttons equal-width except the icon button (square, padding 10 dp).

Selecting **Custom** immediately opens the **Material date range picker** (custom B&W `ColorScheme`: primary = black, container = `Colors.black12`).

### Period navigator

Shown for Тиждень / Місяць / Рік. A row with:
- `chevron_left` icon button (always enabled, taps increase `_offset`) 
- Centred period label (14 sp, 600 weight)
- `chevron_right` icon button (disabled at `_offset == 0`, shown as `Colors.black26`)

### Custom range row

Shown instead of the navigator when Custom is active. Centred row: `date_range_outlined` icon + tappable label → re-opens date picker.

### Empty state

A single centred card with "Недостатньо даних за цей період" when no entries exist for the period.

---

### Stat cards (shown when data exists)

All cards share a `_cardShell` container: 2 px border, radius 12, padding 16, section title in ALL-CAPS 11 sp 700 weight `Colors.black54`.

#### Fill card

Shows the fill rate for the selected period as a number and percentage.

#### Trend chart card (TrendChartCard)

A `LineChart` from `fl_chart`, height 160 dp inside the card.

| Series | Style |
|---|---|
| Valence | Dashed black line (6 on / 4 off), 2 px, dots shown when ≤ 30 days |
| Health events | Solid black line, 1.5 px, no dots; drops to −1 on sick/pain days, stays 0 otherwise |

- Y-axis: −1.4 to +1.4; labelled at −1 (Погано), 0 (Нормально), +1 (Чудово); no right axis.
- X-axis: day abbreviations (≤ 7 days), day numbers every 5 (8–30 days), month abbreviations (year view with weekly aggregation).
- Horizontal grid lines at 0 (1.5 px, `Colors.black26`) and ±1 (1 px, `Colors.black12`); no vertical grid.
- No border around chart.
- **Touch tooltip** (black 87% background): date, quadrant label, health tags, habit names, note — all in white, 11 sp.
- Legend below chart: dashed sample line → Самопочуття; solid sample line → Здоров'я.

#### Circumplex distribution card

Quadrant labels sorted by frequency, each rendered as a `_StatRow`:
- Label (14 sp 500 weight, fixed 150 dp wide)
- `LinearProgressIndicator` (black fill, `Colors.black12` background, height 8 dp, radius 4)
- Count "N дн." (13 sp 700 weight, `Colors.black54`)

#### Health card

Two `_StatRow` entries: Хвороба, Біль.

#### Habit streak card (HabitStreakCard)

One section per habit. Each section:
- Habit name (14 sp 600 weight) + streak badge on the right:
  - If current streak ≥ 2: `arrow_upward` icon (12 dp) + "N дн. поспіль" bold black
  - Else if max streak ≥ 2: same badge in lighter style
- Dot grid: one dot per day in the period
  - Filled (black): habit done
  - Outline / light grey (`Colors.black12`): habit not done
  - Very faint (`Colors.black` at 6% opacity): future day
  - Dot size: 12 dp (≤ 30 days) or 7 dp (> 30 days); gap: 4 dp or 2 dp
- **Поділитись** link at the bottom of the card (text + `share_outlined` icon, `Colors.black54`) → opens **Share bottom sheet**

---

### Share bottom sheet

A `ModalBottomSheet` (white, radius 16 top) previewing the shareable story image.

| Element | Detail |
|---|---|
| Image preview | 520 dp tall, `AspectRatio` matching 360×640 logical canvas; `FittedBox.fill`; light drop shadow |
| Caption | "згенерована картинка, якою можна поділитись…" — 13 sp `Colors.black54`, centred |
| "Прибрати пусті дані?" | Row with `filter_list_outlined` / `filter_list` icon; becomes bold-black when a filter is active; tap opens a confirmation `AlertDialog` |
| **Поділитись** button | Full-width, 52 dp, black fill, radius 14; shows `CircularProgressIndicator` (white, 2 px stroke) while capturing |

The story image (`_HabitStoryWidget`) is a 360×640 logical canvas rendered off-screen at 3× pixel ratio (→ 1080×1920 px PNG). It contains the Атенція logo, period label, habit name, and dot grid for each habit.

---

## 10. Settings View (Налаштування)

Scrollable column, `SafeArea`, padding `fromLTRB(20, 20, 20, 32)`.

### Username field

Section label "ЯК ДО ТЕБЕ ЗВЕРТАТИСЯ?" (ALL-CAPS).  
`TextField` with `OutlineInputBorder` (2 px black, radius 8). Hint: "Введи ім'я тут…". `textCapitalization.words`, max 30 chars. Changes persisted immediately via `provider.setUsername()`.

### Reminders toggle row

A 2 px bordered container (radius 8), horizontal padding 16, vertical 6.

Left: "Нагадування" (bodyLarge, 600 weight).  
Right: `Switch` — active thumb `Colors.black`, track `Colors.black26`; inactive thumb `Colors.black38`, track `Colors.black12`.

Toggling **on** triggers OS permission request. If denied, the switch snaps back.

### Reminder time selector

Visible only when reminders are enabled. A `GestureDetector` wrapping a 2 px bordered container (radius 8):
- Left: "Час нагадування" (bodyLarge)
- Right: bold time value "HH:MM" + `access_time` icon (18 dp)

Tap opens `showTimePicker` (24-hour format, wrapped in `MediaQuery` override).

---

### Action rows (all share the same container style)

2 px bordered container, radius 8, horizontal padding 16, vertical 14. Full-width. Label (bodyLarge, 600 weight) left, icon right.

| Row | Icon | Action |
|---|---|---|
| Експортувати дані | `download_outlined` | Opens **Export dialog** |
| Імпортувати дані | `upload_outlined` | Opens **Import dialog** |
| Видалити дані | `delete_outline` | Opens **Clear data dialog** |
| Guide (Як користуватись?) | `info_outline` | Opens **Guide bottom sheet** |

---

### Dialogs

All dialogs: white background, radius 14, title 18 sp 700, body 14 sp 1.6 line-height `Colors.black87`. Buttons inside a `Column` (full-width, stretched):

**Export dialog**
- Title: "Експорт даних"
- Body: Privacy note + format description
- Buttons: "Зберегти" (black), "Скасувати" (text button, `Colors.black54`)

**Import dialog**
- Title: "Імпорт даних"
- Body: Instructions + merge behaviour note
- Buttons: "Обрати файл" (black, opens file picker), "Завантажити шаблон" (black, generates and shares CSV), "Скасувати" (text)

**Import encoding error**
- Title: "Помилка імпорту"
- Body: "Вибраний файл не є коректним UTF-8…"
- Button: "Зрозуміло"

**Import parse error**
- Title: "Помилка імпорту"
- Body: error message from parser
- Buttons per-error column layout

**Import success**
- Title: "Дані імпортовано"
- Body: "Записи успішно додано."
- Button: "Зрозуміло"

**Clear data dialog**
- Title: "Видалити всі дані?"
- Body: Warning about irreversibility
- Buttons: "Зберегти та видалити" (exports first then clears), "Просто видалити", "Скасувати"

**Clear data done**
- Title: "Дані видалено"
- Body: Confirmation
- Button: "Зрозуміло"

---

### Guide bottom sheet

The same sheet reused from the Today view header logo tap and the Settings Guide row. `ModalBottomSheet` (white, radius 16 top):
- Title: "Як користуватись додатком?" (20 sp, bold)
- Body: 7-step guide (15 sp, 1.6 line-height, `Colors.black87`)
- Button: "Зрозуміло" — full-width, 52 dp, black, radius 14

---

### App info (bottom of Settings)

Centred column:
- App name ("Атенція") — titleMedium bold, line-height 1.0
- Tagline ("це увага до себе") — 13 sp `Colors.black54`
- 16 dp gap
- "Версія X.Y.Z" — 13 sp `Colors.black38` (loaded async from `package_info_plus`)
- Privacy note — 12 sp `Colors.black38`, centred
- Copyright "© 2026 Denys Skvortsov" — 12 sp `Colors.black38`

---

## 11. Transitions & Motion Summary

| Transition | Mechanism | Duration |
|---|---|---|
| Splash → Onboarding / MainScreen | `FadeTransition` via `PageRouteBuilder` | 400 ms |
| Onboarding pages | `PageView.nextPage`, `Curves.easeInOut` | 350 ms |
| Onboarding page indicator dots | `AnimatedContainer` | 250 ms |
| Calendar → EditDayScreen | `MaterialPageRoute` (default slide) | default |
| Toggle / segmented control fill | `AnimatedContainer` | 140 ms |
| Circumplex label opacity | `AnimatedOpacity` | 200 ms |
| Sharing capture loading | `CircularProgressIndicator` (inline) | — |
