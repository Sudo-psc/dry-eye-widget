# Handoff

## Current State

The branch `codex/healthkit-dashboard` defines the first data contract for an integrative Dry Eye Health Dashboard.

## Key Files

- `docs/healthkit-dashboard.md`
- `lib/models/dry_eye_health_dashboard.dart`
- `test/dry_eye_health_dashboard_test.dart`
- `projects/dry-eye-health-dashboard/`

## Next Actions

1. Decide target platform path for HealthKit support.
2. Add a HealthKit permission and import adapter for sleep and heart rate.
3. Persist local app events needed by the dashboard: pauses, colirio confirmations, blink suggestions, and future symptom entries.
4. Build the dashboard UI from `DryEyeDashboardPeriod`.

## Blockers

- HealthKit native work needs entitlement and platform-target confirmation.
- Screen Time import is separate from HealthKit.
