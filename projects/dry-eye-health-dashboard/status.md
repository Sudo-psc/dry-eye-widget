# Status

Updated: 2026-06-19

Current phase: data-contract foundation.

Completed:

- Branch created: `codex/healthkit-dashboard`.
- Dashboard metric model added in `lib/models/dry_eye_health_dashboard.dart`.
- Metric contract documented in `docs/healthkit-dashboard.md`.
- Project state files created under `projects/dry-eye-health-dashboard/`.
- Tests added for metric coverage, HealthKit boundaries, app screen-time source, and missing-data behavior.

In progress:

- None.

Risks:

- HealthKit availability and entitlements must be verified for the final Apple target before native integration.
- Screen Time is not modeled as a HealthKit source in this branch.
- Click and keystroke counts are privacy-sensitive and should remain aggregate-only and opt-in.
