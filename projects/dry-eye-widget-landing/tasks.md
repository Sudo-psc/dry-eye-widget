# Live Task Queues

## now

- [x] Inspect repository and infer runtime constraints.
- [x] Create local operating summary and implementation contract.
- [x] Confirm `site/` as the official `/app/` landing.
- [x] Verify build and local render.
- [x] Apply priority fixes from repository review.
- [x] Run static smoke check and Flutter checks.
- [x] Create HealthKit dashboard branch.
- [x] Define integrative dashboard data model.
- [x] Add native macOS HealthKit bridge for sleep and average heart rate.
- [x] Add Dart service that maps native HealthKit rows to dashboard periods.
- [x] Verify analysis, focused tests, and unsigned Xcode compile.
- [x] Connect the dashboard UI to `HealthKitDashboardService`.
- [x] Add a visible optional HealthKit permission flow.
- [x] Add menu and tray access to the Health dashboard.
- [x] Add widget tests for Health dashboard permission/data states.
- [x] Fix widget positioning bug: random position jumps when switching layouts (menu, blink reminder, ball).

## next

- [ ] Test a signed macOS build with HealthKit entitlement enabled.
- [ ] Add a manual QA script for signed HealthKit states: unavailable, denied, authorized and no samples.
- [ ] Expand the dashboard with local app metrics beyond HealthKit.
- [x] Capture or replace carousel with real app screenshots when available.
- [ ] Add Windows-specific installer/tray screenshots when available.
- [ ] Run production-like Lighthouse after deployment.
- [ ] Prepare VPS deploy notes.
- [ ] Decide whether landing should live in this repo or a separate GitHub repo.

## blocked

- VPS deployment is blocked until server access and deployment path are provided.
- DNS configuration is blocked until DNS provider access is provided.
- Separate landing repo creation is blocked until the desired GitHub organization/name is confirmed.
- Signed HealthKit runtime validation is blocked until a valid Apple signing identity/provisioning setup is available locally or in CI.

## improve

- [x] Add an automated landing smoke test that checks canonical route, script safety, and i18n coverage.
- [x] Add CI coverage for the static site smoke check.
- [x] 2026-07-10: five landing quick-win cycles (version badge, a11y, features, FAQ, sitemap/smoke version sync).
- [x] 2026-07-10: five workflow/roadmap cycles (ci.yml, dependabot, scheduled smoke, issue template, ROADMAP.md).
- Add signed-runtime QA evidence for HealthKit permission states: unavailable, denied, authorized and no samples.
- Track Flutter macOS Swift Package Manager warnings for `screen_retriever_macos`, `tray_manager`, and `local_notifier`.
- Add real app screenshots from macOS and Windows release runs.
- Add structured article metadata for future blog expansion.

## recurring

- Review release download URLs after each GitHub release.
- Review scientific references when adding clinical claims.
- Re-run performance checks before each public launch.
