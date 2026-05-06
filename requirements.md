# Атенція — Product Requirements

**Version:** 1.7.5  
**Platform:** Flutter (iOS primary, Android secondary)  
**Language:** Ukrainian only (`uk_UA`)  
**Storage:** Local-only, no cloud, no authentication

---

## 1. Architecture

| Concern | Solution |
|---|---|
| State management | `provider` (`ChangeNotifier`) |
| Local persistence | `shared_preferences` (JSON-encoded entries) |
| Notifications | `flutter_local_notifications` + native timezone `MethodChannel` |
| Localisation | Single YAML file (`assets/l10n/uk.yaml`), loaded synchronously at startup |
| Navigation | `BottomNavigationBar` with 4 tabs |
| Startup | `runApp()` is called immediately; `SharedPreferences.init()` runs asynchronously afterward to avoid blocking the UI on a fresh install |

---

## 2. Data Model — `DailyEntry`

Each day is stored as a keyed JSON object under `SharedPreferences` key `atensia_entries`. The map key is an ISO date string (`YYYY-MM-DD`).

| Field | Type | Description |
|---|---|---|
| `date` | `DateTime` | Calendar day |
| `valence` | `double?` | Mood pleasantness: −1.0 / 0.0 / +1.0, `null` = not set |
| `arousal` | `double?` | Energy level: −1.0 / 0.0 / +1.0, `null` = not set |
| `isSick` | `bool` | Health toggle — illness |
| `hasPain` | `bool` | Health toggle — pain |
| `habits` | `Map<String, bool>` | Named habit checkboxes |
| `comment` | `String?` | Optional free-text note (max 140 chars) |

An entry is considered "empty" (and is deleted from storage) when all fields are at their default/null values.

### Migration
On first launch after renaming from "Proso" to "Атенція", keys prefixed `proso_*` are migrated to `atensia_*` and then removed.

---

## 3. Russell's Circumplex Model

Emotional state is represented as a point in valence × arousal space. The UI uses two 3-button segmented controls (Погано / Нормально / Чудово for valence; Виснажено / Нормально / Бадьоро for arousal). Tapping the already-selected button clears that axis.

Nine named quadrant labels are shown to the user:

| | Arousal high (+1) | Arousal mid (0) | Arousal low (−1) |
|---|---|---|---|
| **Valence high (+1)** | На підйомі | Спокійно | Приємна втома |
| **Valence mid (0)** | В тонусі | В рівновазі | Мляво |
| **Valence low (−1)** | Стресово | Пригнічено | Виснажено |

---

## 4. Default Habits

Five habits are defined as the default set (localised via `uk.yaml`):

1. Прогулянка
2. Руханка
3. Читання
4. Творчість
5. Байдикування

---

## 5. Navigation Tabs

| Tab | Label | Screen |
|---|---|---|
| 0 | Сьогодні | `TodayView` |
| 1 | Календар | `HistoryView` |
| 2 | Звіт | `StatsView` |
| 3 | Налаштування | `SettingsView` |

---

## 6. Screens

### 6.1 Splash Screen
- Displays app logo, name, and tagline with a fade-in animation.
- After a short delay: navigates to **Onboarding** on first launch, otherwise to **MainScreen**.

### 6.2 Onboarding (4 pages, shown only on first launch)
1. **Name input** — asks for the user's name (optional, max 30 chars).
2. **Greeting** — personalised welcome message.
3. **Notifications** — enable/disable daily reminder and choose the time.
4. **Guide** — how to use the app; finishing marks the app as launched.

### 6.3 Today View (`TodayView`)
- Personalised greeting: "Вітаю, {name}!" or "Вітаю, друже!"
- Current date in Ukrainian format (e.g. "понеділок, 6 травня").
- Streak line: "Твій N-й день записів" (optionally "поспіль" when streak ≥ 2).
- **Circumplex selector** (`CircumplexButtons`) for today's state.
  - Animated quadrant label shown below section title.
- **Health toggles** (animated segmented control): Хвороба / Біль.
- **Habit checkboxes** for all 5 default habits.
- **Note field** — multiline text input, max 140 chars.
- All changes are persisted immediately on every interaction.
- Tapping the logo in the header opens the **Guide** bottom sheet.

### 6.4 History / Calendar View (`HistoryView`)
- Monthly calendar (`table_calendar`, Ukrainian locale, week starts Monday).
- **Day markers** (shown below the date number):
  - Filled black dot → Хвороба logged.
  - Filled larger black circle → all habits completed.
  - Outlined black circle → partial activity (some habits or state set).
- Selected day **detail panel** below the calendar:
  - Date, circumplex quadrant label, health items, leisure habits done, note.
  - "Додати" / "Змінити" button → opens `EditDayScreen`.
  - Future day → "Цей день ще не настав".
  - No data → "Дані за цей день відсутні" + "Додати" button.

### 6.5 Edit Day Screen (`EditDayScreen`)
- Full editing form for any past (or today) date.
- Same fields as Today View: circumplex, health, habits, note.
- Changes are saved only when the user taps **Зберегти** (batch save).

### 6.6 Stats / Report View (`StatsView`)
- **Period selector**: Тиждень / Місяць / Рік / Custom range.
- **Period navigator**: ← → arrows to go back/forward; disabled at current period.
- **Custom range**: date range picker (Material, B&W themed).
- **Stat cards** (shown when data exists for the selected period):
  - **Fill card** — percentage and count of days with entries.
  - **Trend chart** (`TrendChartCard`) — line chart of valence over time; health events shown as separate line. Weekly aggregation applied for year view.
  - **Circumplex distribution** (`_CircumplexCard`) — bar chart of quadrant label frequencies.
  - **Health card** — sick days and pain days with progress bars.
  - **Habit streak card** (`HabitStreakCard`) — per-habit completion counts, current streak, max streak.
- **Share button** — renders the stats cards as an image and shares via `share_plus`.
- Empty state shown when no data exists for the period.

### 6.7 Settings View (`SettingsView`)
- **Username field** — editable, max 30 chars, saved immediately.
- **Reminders toggle** — requests OS permission when enabled; snaps back if denied.
  - **Time picker** — 24-hour format, shown when reminders are enabled.
- **Export data** — exports all entries as CSV via share sheet.
- **Import data** — picks a CSV file; merges with existing data (imported rows win for matching dates).
  - Template download available.
  - UTF-8 encoding enforced; mojibake repair applied to imported comments.
- **Clear all data** — confirm dialog with option to export first.
- **Guide** — bottom sheet with usage instructions.
- **App info** — app name, tagline, version (from `package_info_plus`), privacy note, copyright.

---

## 7. Notifications

- Daily scheduled reminder at a user-configured time.
- Timezone resolved via a native `MethodChannel` (`com.texapp.atensia/timezone`); falls back to UTC on failure.
- Android: requests `POST_NOTIFICATIONS` permission at runtime (API 33+); uses exact alarms with fallback to inexact.
- iOS: permission requested via `flutter_local_notifications` when the user enables reminders.
- Notification is rescheduled on every app start if reminders are enabled.

---

## 8. Data Import / Export (CSV)

### Export format
```
date,valence,arousal,sick,pain,Прогулянка,Руханка,Читання,Творчість,Байдикування,comment
2026-05-01,1.000,0.000,false,false,true,false,true,false,false,"Great day"
```

### Import
- Accepts the current format above and a legacy format (`date,mood,sick,pain,...`).
- Merges with existing entries; imported rows overwrite existing rows for the same date.
- Returns a user-readable error string on parse failure.
- Template CSV (header + 3 blank example rows) available for download.

---

## 9. UI Design System

| Token | Value |
|---|---|
| Background | `#FFFFFF` |
| Primary text | `#000000` |
| Border | 2px solid black |
| Corner radius | 8–12 dp |
| Shadows | None |
| Active state | Black fill, white text |
| Inactive state | White fill, black text |
| Header font | Fixel Display |
| Body font | Fixel Text |
| Haptic feedback | `HapticFeedback.mediumImpact()` on toggles |
| Orientation | Portrait only |
| Status bar | Light icons on white background |

---

## 10. Metrics Tracked in the App

| Metric | Where shown |
|---|---|
| Total filled days | Today view subtitle |
| Current consecutive streak | Today view subtitle |
| Period fill rate (%) | Stats — Fill card |
| Valence trend over time | Stats — Trend chart |
| Health days (sick / pain) | Stats — Health card |
| Circumplex quadrant frequency | Stats — Mood card |
| Per-habit completion count | Stats — Habits card |
| Current & max habit streak | Stats — Habits card |