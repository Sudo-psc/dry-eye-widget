# Handoff

## Current State

The official landing page lives in `site/` and is deployed as the single `/app/` route. Priority review fixes were applied and verified on 2026-06-19.

The active branch is `codex/healthkit-dashboard`. The macOS-only HealthKit foundation is now implemented: dashboard data model, Dart service, native Swift method channel, permission request, daily sleep import, daily average heart-rate import, Info.plist privacy text and HealthKit entitlement.

## Next Actions

1. Connect the dashboard UI to `HealthKitDashboardService`.
2. Add a visible optional HealthKit permission flow in the app.
3. Validate a signed macOS build with HealthKit entitlement enabled.
4. Add Windows-specific installer/tray screenshots when available.
5. Decide whether the landing stays in this repo or moves to a separate GitHub repository.
6. Run production PageSpeed and fix any production-only issues.

## Blockers

- VPS credentials and DNS access are needed only if deployment moves away from GitHub Pages.
- Separate landing GitHub repo name is needed if this should not stay in the existing app repository.
- Signed HealthKit runtime validation requires a valid Apple signing identity/provisioning setup.

## Verification

- `flutter analyze`: passed on 2026-06-19.
- `flutter test test/dry_eye_health_dashboard_test.dart test/healthkit_dashboard_service_test.dart`: passed on 2026-06-19.
- `xcodebuild -workspace macos/Runner.xcworkspace -scheme Runner -configuration Release CODE_SIGNING_ALLOWED=NO`: passed on 2026-06-19.
- `flutter build macos --release`: blocked locally by signing requirement after enabling HealthKit entitlement.
