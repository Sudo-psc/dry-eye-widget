# Handoff

## Current State

Version target: **1.22.0** — P0 product loop for discovery and retention.

### Day Summary hub
New screen (`lib/widgets/summary/day_summary_screen.dart`) opened from the floating menu as the first Health item. Shows today’s completed/prompted breaks, streak, 7-day adherence, last DVRS, a proactive insight, optional DVRS recheck banner, and CTAs for start break / DVRS / progress / dashboard.

### Insight engine
`lib/services/daily_insight.dart` builds a single local narrative prioritized as: DVRS due/never → streak → 7-day adherence → today → total consistency → start. Shared by Day Summary and My Progress.

### DVRS recheck nudge
- Interval: 14 days (`AppDefaults.dvrsReminderDays`).
- If never taken: after ≥3 completed breaks.
- Surfaces: banner in Day Summary + system notification at most once per day (requires notifications + `dvrsReminderEnabled`).
- Snooze: 7 days via “Lembrar depois”.
- Opt-out: Settings → Geral → “Lembrar reavaliação do DVRS”.

Previous work (still current): DVRS single-page questionnaire, compact widget visual refresh, partial edge docking (meia-lua), hover animation, HealthKit branch notes elsewhere.

## Verification

- `flutter analyze lib test`: passed on 2026-07-09.
- Focused tests: `daily_insight_test`, `day_summary_screen_test`, `floating_menu_test`, `widget_settings_test`: passed on 2026-07-09.
- Full `flutter test`: 197 tests passed on 2026-07-09.

## Next Actions

1. Manually open Day Summary on macOS: insight text, DVRS banner, snooze, CTAs.
2. With notifications on and a stale/missing DVRS, confirm at most one nudge notification per day.
3. Manually inspect DVRS single-page scroll at narrow widths.
4. Inspect edge docking + blink micronotification on Windows before next Windows package.
5. Signing / Gatekeeper / SmartScreen remains the main distribution P0 outside product code.
