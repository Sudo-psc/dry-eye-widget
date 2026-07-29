# Handoff

## Current State

Em 2026-07-29, a landing foi sincronizada em 1.26.0 e revisada contra claims de
prevenção, tratamento, causalidade e prescrição. As imagens informativas têm
texto alternativo PT/EN, os controles do carrossel anunciam o título da captura
e seus dots são reconstruídos quando o idioma muda. A rolagem deixa de ser
suave quando o sistema pede reduzir movimento. O smoke estático e o gate de
metadados passam.

Os registros HealthKit abaixo descrevem uma branch histórica. A `main` atual não
contém serviço, ponte nativa ou entitlement HealthKit; portanto essa integração
não faz parte da 1.26.0.

On 2026-07-27, three local reliability improvements were completed. PDF
generation now requires packaged Inter Regular/Bold fonts and a DejaVu Sans
fallback, with a regression test that rejects missing-glyph warnings for
accented and typographic text. Startup window restoration is isolated in
`lib/app/window_restoration.dart`, reducing `main.dart` and making native screen
failures and multi-origin displays deterministic under test.

Release readiness is now explicit rather than inferred from one version string.
`scripts/check_release_readiness.sh --metadata` validates every local version
surface; `--tag` also requires the matching tag at HEAD; `--published` requires
the public release and all four expected artifacts. CI and all tag-producing
workflows use the appropriate local gate.

The tag-triggered platform workflows now receive no secrets and only produce
internal artifacts and manifests. A default-branch fan-in validates tag,
source SHA and main ancestry in one read-only job and uploads only the validated
bundle. No Actions workflow has `contents: write` or runs the GitHub Release
publisher. Publishing is a separate manual operation that requires an explicit
approval marker bound to the reviewed tag, commit and canonical digest of the
four artifacts plus three manifests. Draft retries remove only unexpected
assets; published retries preserve assets, and post-publication reconciliation
converges latest to the greatest published stable SemVer.

Static analysis is clean and all 356 Flutter tests pass. Local metadata is ready
for 1.26.0+76. A fresh universal macOS build completed; deep/strict ad-hoc
signature verification and DMG integrity passed. The DMG is 29,177,791 bytes
with SHA-256
`b6b69044374316c6cd7632bfb4266e190f23e424c3deeaa0f2c9f794baf5854f`.
No commit, tag, push, upload, release publication or installed-app replacement
was performed.

The fourth independent read-only review completed with
`P0=0 / P1=0 / P2=0` and no confirmed finding. The reviewed freeze remained at
HEAD `71296726616d5c67d47204c8474ca519bcbd2de7`, with 49 tracked changes,
13 untracked files, an empty staging area, tracked-diff fingerprint
`814ac7d3339a3c039b0c712c15ddc5ba297f4265b301945cdf4e1f3846006c2e`
and patch-inventory fingerprint
`8e7974a3e7567ab3b86c0e289a92e27bac4afc40c7a6ec93df535f5e03f4ec0b`.
The reviewer confirmed no local or remote mutation.

The unrelated untracked file
`/Users/philipecruz/app_dry_eye_widget/gemini_generated_video_B3916D35.mp4`
remains preserved and excluded. Its SHA-256 is
`72f74a1f3ded76933117b3fbc8c8694235853633936f4e54e879278a82c4f385`.

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

Historical branch only: a macOS HealthKit foundation and dashboard were
prototyped, but they are absent from the current `main`.

A widget positioning bug was fixed: the floating widget no longer adopts the
temporary position of a larger menu/reminder window. The compact coordinate is
loaded from storage, isolated in `CompactWindowAnchor`, restored after transient
layouts and changed only by a real compact-widget drag or explicit undocking.

## Next Actions

1. Request separate explicit authorization to commit and push, then create tag
   `v1.26.0`.
2. Let the runners and fan-in reconcile the four platform artifacts and three
   manifests into a read-only bundle.
3. Review that exact bundle and obtain a new explicit approval for
   `<tag>@<commit>#<bundle-digest>`.
4. Run the manual publisher with the approval marker, then verify publication.
5. Verify GitHub Pages and `/app/science/` on the production domain.

## Blockers

- Separate authorization for commit/push/tag is required before integration.
- Windows, MSIX and live fan-in evidence require a future authorized tag on
  GitHub Actions.
- The final manifest source SHA does not exist until a commit is authorized.
- VPS credentials and DNS access are needed only if deployment moves away from GitHub Pages.
- Separate landing GitHub repo name is needed if this should not stay in the existing app repository.

## Verification

- `flutter analyze`: passed with no issues on 2026-07-29.
- Focused DVRS/PDF/storage/claims group: all 77 tests passed on 2026-07-29.
- Complete `flutter test`: all 356 tests passed on 2026-07-29.
- Science build, landing smoke and 1.26.0 metadata gate: passed.
- `scripts/test_release_pipeline.sh`: passed valid, extra-file, tamper and
  idempotent-published cases.
- actionlint 1.7.12, workflow YAML parsing and `git diff --check`: passed.
- Fresh `flutter build macos --release`: passed at 59.4 MB.
- Bundle: 1.26.0+76, universal x86_64/arm64, ad-hoc signature deep/strict valid.
- DMG: 29,177,791 bytes; `hdiutil verify` passed; SHA-256
  `b6b69044374316c6cd7632bfb4266e190f23e424c3deeaa0f2c9f794baf5854f`.

- `flutter analyze`: passed with no issues on 2026-07-27.
- Focused PDF/DVRS/window-restoration group: all 26 tests passed on 2026-07-27.
- Complete `flutter test`: all 340 tests passed on 2026-07-27.
- `check_release_readiness.sh --metadata`: passed for 1.25.2.
- `check_release_readiness.sh --tag v1.25.2`: expected failure; tag absent.
- `check_release_readiness.sh --published`: expected failure; public release absent.
- Workflow YAML parsing and `git diff --check`: passed.
- Fresh `flutter build macos --release`: blocked after three bounded attempts
  by the same zero-progress parallel Xcode clang SDK probes; the isolated arm64
  probe passes and no fresh-build claim is made.

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
