# Handoff

## Current State

The floating widget now limits background liquid-effect redraws to perceptually useful phase changes: about 20 fps while idle and 25 fps while active. The progress ring no longer spends continuous frames below 90%; it becomes animated only near the break deadline. Hover, press, drag and release remain immediate. Regression tests cover the phase budget and threshold transition.

The official landing output lives in `site/`. The main product page remains `/app/`; the new scientific foundation is published at `/app/science/` and is linked from the main header and footer.

The macOS carousel now uses current v1.24-era UI captures: the liquid floating orb with its refined progress ring and compact menu, plus the daily summary with pauses, streak, adherence and DVRS actions. The new assets are WebP files on transparent 16:10 canvases, which prevents vertical app screens from being cropped in the landing's landscape frames. Reusable capture entrypoints live in `tool/landing_menu_preview.dart` and `tool/capture_landing_section.mjs`.

Science source lives in `web/science/` and uses React, TypeScript, Tailwind CSS, Framer Motion and Lucide. `npm run build --prefix web/science` type-checks, builds and prerenders the page into `site/science/`. The Pages and CI workflows run that build before the site smoke test.

The Science page covers dry-eye relevance, tear-film physiology, longitudinal monitoring, app principles, OVPP, selected scientific references, the related book and the research roadmap. It distinguishes available capabilities from future research directions and does not claim diagnosis, prevention or treatment.

The current branch is `main`. The macOS-only HealthKit foundation remains implemented: dashboard data model, Dart service, native Swift method channel, permission request, daily sleep import, daily average heart-rate import, Info.plist privacy text and HealthKit entitlement.

The Health dashboard UI is connected to `HealthKitDashboardService`. It is available from the floating menu and the system tray/menu bar, requests optional HealthKit permission, and renders the last 7 days of sleep and average heart-rate values with explicit missing-data states.

A widget positioning bug was fixed: the floating widget no longer jumps to random locations when switching layouts (menu, blink reminder, ball). The root causes were `_ballPosition` not syncing with saved storage on startup, `_nudgeIntoScreen` not updating the cached position after clamping, and `blinkReminder` layout not refreshing position before applying.

## Next Actions

1. Deploy and verify `/app/science/` on the custom domain.
2. Re-run production Lighthouse and confirm canonical/OG rendering.
3. Add a recurring scientific-reference freshness review.
4. Validate a signed macOS build with HealthKit entitlement enabled.
5. Capture runtime QA for HealthKit states: unavailable, denied, authorized, no samples and samples available.
6. Refresh the Windows carousel from a real v1.24+ Windows run.

## Blockers

- VPS credentials and DNS access are needed only if deployment moves away from GitHub Pages.
- Separate landing GitHub repo name is needed if this should not stay in the existing app repository.
- Signed HealthKit runtime validation requires a valid Apple signing identity/provisioning setup.

## Verification

- `flutter test test/floating_ball_test.dart`: 10 tests passed on 2026-07-12, including animation-performance regressions.
- `flutter analyze`: passed with no issues on 2026-07-12.
- `flutter test`: all 238 tests passed on 2026-07-12.
- `flutter build macos --release -t lib/main.dart`: passed on 2026-07-12; app bundle 59.3 MB.

- `flutter analyze`: passed on 2026-06-19.
- `flutter test test/dry_eye_health_dashboard_test.dart test/healthkit_dashboard_service_test.dart`: passed on 2026-06-19.
- `xcodebuild -workspace macos/Runner.xcworkspace -scheme Runner -configuration Release CODE_SIGNING_ALLOWED=NO`: passed on 2026-06-19.
- `flutter build macos --release`: blocked locally by signing requirement after enabling HealthKit entitlement.
- `flutter analyze`: passed on 2026-06-21.
- `flutter test`: passed on 2026-06-21.
- `npm run build --prefix web/science`: passed on 2026-07-10.
- `node site/scripts/smoke-check.mjs`: passed on 2026-07-10.
- Local Lighthouse Science mobile: 100 performance / 100 accessibility / 100 best practices / 100 SEO.
- Local Lighthouse Science desktop: 100 performance / 100 accessibility / 100 best practices / 100 SEO.
- Browser QA: responsive desktop/mobile, dark-mode toggle, 12 DOI links and lazy book-cover loading passed.
- 2026-07-12 screenshot refresh: site smoke passed; isolated Flutter preview analysis passed; desktop and mobile carousel captures reviewed at 1440×1000 and 430×932.
