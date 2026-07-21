# Handoff

## Current State

The expanded menu no longer pins the orb to its top-left corner. A testable
`MenuWindowPlacement` compensates the native menu-window clamp, so the orb stays
over the same visual origin it occupied in compact mode. The action panel is
placed below the orb when there is room and above it near the bottom edge.
Clicking the orb inside the open menu now invokes `_closeMenu` directly; because
that orb is not draggable, its pan recognizers are also disabled so they cannot
compete with the closing click.

The 2026-07-16 reliability audit corrected four confirmed defects. Widget
layout decisions now follow the display that contains the current window, so a
secondary monitor no longer inherits primary-display bounds. Automatic breaks
cannot replace the compact anchor with a centered panel coordinate. App quit
also drains pending activity and screen-time persistence before closing.

The audit also found that launch-at-login had no macOS channel implementation.
`MainFlutterWindow.swift` now backs the package API with `SMAppService.mainApp`
on macOS 13 or later, validates arguments and reports native failures. The
release runtime no longer logs MissingPluginException and the operating system
confirmed the saved login-item preference.

The floating orb no longer derives visual deformation from drag velocity. Its
iris, highlight, shadow and progress ring keep their calm internal motion while
the lateral edge magnetism remains fast.

Menu expansion now uses an immutable compact-window anchor. The larger menu may
be clamped temporarily to the visible screen, but that transient coordinate is
never persisted as the ball position. Native layout requests are serialized,
drag callbacks are disabled while the menu is expanded, and closing either the
menu or a panel restores the original compact coordinate.

The public DVRS wording is now protected by `test/dvrs_claims_test.dart`, which
checks app and landing surfaces for obsolete clinical-risk language and requires
the explicit educational/non-validated framing. The site smoke test and all 261
Flutter tests pass on 2026-07-16.

The PT-BR and English GitHub READMEs now show the current v1.24 liquid-menu and daily-summary screenshots directly from the canonical landing assets, with a link to the full macOS and Windows gallery.

The floating widget now limits background liquid-effect redraws to perceptually useful phase changes: about 20 fps while idle and 25 fps while active. The progress ring no longer spends continuous frames below 90%; it becomes animated only near the break deadline. Hover, press, drag and release remain immediate. Regression tests cover the phase budget and threshold transition.

The official landing output lives in `site/`. The main product page remains `/app/`; the new scientific foundation is published at `/app/science/` and is linked from the main header and footer.

The macOS carousel now uses current v1.24-era UI captures: the liquid floating orb with its refined progress ring and compact menu, plus the daily summary with pauses, streak, adherence and DVRS actions. The new assets are WebP files on transparent 16:10 canvases, which prevents vertical app screens from being cropped in the landing's landscape frames. Reusable capture entrypoints live in `tool/landing_menu_preview.dart` and `tool/capture_landing_section.mjs`.

Science source lives in `web/science/` and uses React, TypeScript, Tailwind CSS, Framer Motion and Lucide. `npm run build --prefix web/science` type-checks, builds and prerenders the page into `site/science/`. The Pages and CI workflows run that build before the site smoke test.

The Science page covers dry-eye relevance, tear-film physiology, longitudinal monitoring, app principles, OVPP, selected scientific references, the related book and the research roadmap. It distinguishes available capabilities from future research directions and does not claim diagnosis, prevention or treatment.

The current branch is `main`. The macOS-only HealthKit foundation remains implemented: dashboard data model, Dart service, native Swift method channel, permission request, daily sleep import, daily average heart-rate import, Info.plist privacy text and HealthKit entitlement.

The Health dashboard UI is connected to `HealthKitDashboardService`. It is available from the floating menu and the system tray/menu bar, requests optional HealthKit permission, and renders the last 7 days of sleep and average heart-rate values with explicit missing-data states.

A widget positioning bug was fixed: the floating widget no longer adopts the
temporary position of a larger menu/reminder window. The compact coordinate is
loaded from storage, isolated in `CompactWindowAnchor`, restored after transient
layouts and changed only by a real compact-widget drag or explicit undocking.

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

- Menu origin/click regression group: all 23 tests passed on 2026-07-16.
- Final `flutter analyze`: passed with no issues on 2026-07-16.
- Final complete Flutter suite: all 264 tests passed on 2026-07-16.
- Final macOS release build: passed at 59.4 MB; local ad-hoc reseal and strict
  deep signature verification passed. Process 87550 is running for inspection.

- Reliability audit: `flutter analyze` passed with no issues on 2026-07-16.
- Multi-monitor, activity persistence, edge snap, orb motion and macOS startup
  regression group: all 32 tests passed on 2026-07-16.
- Complete Flutter suite: all 261 tests passed on 2026-07-16.
- macOS release build: passed on 2026-07-16; app bundle 59.4 MB.
- Strict deep signature verification passed. The rebuilt local release launched
  as process 67893 without the previous startup-channel exception; CoreGraphics
  confirmed its native window was on screen.

- `flutter analyze` on the affected app/layout/widget files: passed on 2026-07-16.
- Focused motion and window-anchor tests: all 17 passed on 2026-07-16.
- `flutter test`: all 256 tests passed on 2026-07-16.
- `flutter build macos --release`: passed on 2026-07-16; app bundle 59.4 MB.
- Local `codesign --verify --deep --strict`: passed after ad-hoc reseal.
- Native runtime: expanded menu observed at 300×407; menu-to-settings-to-close
  returned to the same starting coordinate. Direct synthetic menu-close click
  is not used as evidence because Retina multi-monitor coordinate conversion
  selected the wrong control; a display-aware integration driver remains queued.

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
- 2026-07-13: gauge total removido do resultado/dashboard; faixas renomeadas como carga relatada; não validação declarada na UI, site, política, termos e `docs/DVRS_SAFETY_AND_VALIDATION.md`. Suite completa: 238 testes aprovados.
