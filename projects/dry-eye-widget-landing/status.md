# Status

Updated: 2026-07-29

Release 1.26.0 validada localmente:

- Versão sincronizada em app, MSIX, landing, READMEs e changelog.
- Copy médica revisada para escopo educativo sem promessa de prevenção,
  tratamento, causalidade ou prescrição.
- Alternativas localizadas cobrem imagens informativas; o carrossel respeita
  `prefers-reduced-motion` e reconstrói os `aria-labels` dos dots após PT/EN.
- Smoke da landing e gate de metadados passaram.
- O pipeline local rejeita arquivos extras e hashes divergentes; o fan-in usa
  código da default branch, valida ancestralidade, aguarda macOS/Windows/MSIX e
  produz somente o bundle reconciliado. Actions não possui `contents: write`
  nem publica GitHub Release; a etapa manual exige aprovação explícita da tag,
  commit e digest canônico dos sete arquivos do snapshot revisado.
- A v1.25.2 está publicada com quatro artefatos, conforme o run isolado.
- O publicador manual rejeita substituição integral do bundle após aprovação e
  reconcilia `latest` para a maior SemVer estável em ordens concorrentes.
- O DVRS não persiste texto de alerta legado e tem questionário e alertas
  integralmente localizados em PT/EN.
- O novo build macOS e DMG passaram; 77 testes focados e 356 testes totais
  foram aprovados.
- A quarta revisão independente terminou com `P0=0 / P1=0 / P2=0`, sem
  achados e sem mutação local ou remota.
- O freeze revisado registrou HEAD
  `71296726616d5c67d47204c8474ca519bcbd2de7`, 49 rastreados modificados,
  13 não rastreados, staging vazio, diff
  `814ac7d3339a3c039b0c712c15ddc5ba297f4265b301945cdf4e1f3846006c2e`
  e inventário do patch
  `8e7974a3e7567ab3b86c0e289a92e27bac4afc40c7a6ec93df535f5e03f4ec0b`.
- Próximo passo: solicitar autorização explícita separada para commit/push/tag;
  depois dos runners e fan-in, solicitar nova aprovação
  `tag+commit+digest` para publicação manual.
- A integração HealthKit mencionada abaixo é histórica de outra branch; não há
  código ou entitlement HealthKit na `main` atual.

Release reliability superseding the 2026-07-27 provisional state:

- PDF reports now use packaged Inter fonts plus DejaVu Sans fallback for every
  document, preventing missing-glyph warnings for accents, curly quotes and
  dashes. The font cache is committed only after all required assets load.
- Startup window restoration moved out of `main.dart` into the injectable
  `BallPositionRestorer`; five new tests cover visible, off-screen,
  multi-origin and native-query failure paths.
- Release gates now cover metadata, tag-at-HEAD, strict manifests, a
  three-platform read-only fan-in and the exact four-file bundle.
- `flutter analyze` passed with no issues and all 356 Flutter tests passed.
- Release metadata is synchronized at 1.26.0+76. No commit, push, tag or release
  publication was performed.
- A fresh 1.26.0 universal macOS build completed; deep/strict signature and DMG
  integrity passed. The previous Xcode SDK-probe stall remains historical.

Menu origin and close interaction fix (2026-07-16):

- The expanded menu now compensates its native screen clamp by repositioning
  the orb inside the menu window, preserving the orb's original visual point.
- Near the bottom edge, the action panel automatically opens above the orb;
  elsewhere it remains below, without forcing the orb into the menu corner.
- Clicking the orb while the menu is open now calls the close path directly,
  and the non-draggable menu orb no longer registers pan gestures.
- Static analysis passed, 23 focused layout/orb tests passed and all 264 Flutter
  tests passed.
- The macOS release build succeeded at 59.4 MB, was locally resealed, passed
  strict signature verification and is running for manual inspection.

App reliability audit (2026-07-16):

- Fixed multi-monitor positioning so drag, docking, undocking and screen clamps
  use the display containing the widget instead of always using the primary display.
- Protected the canonical compact coordinate when an automatic break starts
  while a centered panel is open; transient panel coordinates are no longer cached.
- Made app quit flush pending activity and screen-time data before closing the
  native window, including samples collected before activity monitoring stopped.
- Restored the missing macOS launch-at-login channel with ServiceManagement;
  the saved preference now reaches the operating system instead of throwing a
  MissingPluginException.
- Static analysis, 32 focused regression tests and all 261 Flutter tests passed.
- The macOS release build succeeded at 59.4 MB, passed strict signature
  verification and launched locally with an on-screen native window.

Widget motion and menu anchor (2026-07-16):

- Removed velocity-driven tilt, stretch, iris displacement and release rebound
  from the floating orb while preserving the faster lateral magnetism.
- Added an immutable compact-window anchor for transient menu/reminder layouts.
- Serialized native layout transitions and disabled drag callbacks while the
  menu is open, preventing menu-sized windows from overwriting ball position.
- Static analysis and all 256 Flutter tests passed.
- macOS release build succeeded at 59.4 MB and its local ad-hoc signature was
  resealed and verified before launch.

DVRS claims gate (2026-07-16):

- App and landing copy are covered by `test/dvrs_claims_test.dart`.
- Obsolete clinical-risk wording is rejected and the educational/non-validated
  positioning is required.
- Static landing smoke and the complete Flutter suite pass.

README screenshots (2026-07-13):

- Replaced the legacy animated carousel in both README languages with the current v1.24 liquid-menu and daily-summary captures.
- Linked the compact README gallery to the complete macOS and Windows capture set on the public landing page.

Current phase: App reliability audit completed and locally validated.

Animation performance (2026-07-12):

- Continuous liquid-orb repaint notifications are quantized to about 20 fps idle and 25 fps active, independent of 60/120 Hz display refresh.
- The progress ring stays static below 90% and animates only when the upcoming break becomes urgent.
- Direct press, hover, drag and release feedback remains full-frequency for responsiveness.
- Focused widget suite passed with new frame-budget and adaptive-ring regression coverage.
- Full analysis and all 238 tests passed; the macOS release app built successfully at 59.3 MB.

Screenshot refresh (2026-07-12):

- Replaced the macOS floating-menu image with a clean runtime capture of the current liquid orb, progress ring, quick actions and two-level menu.
- Replaced the legacy dashboard image with the current daily summary flow.
- Added WebP carousel assets with transparent 16:10 presentation canvases to keep vertical app screens fully visible.
- Added an isolated Flutter preview target and a repeatable Chrome DevTools capture utility.
- Browser evidence captured at 1440×1000 and 430×932; static smoke and preview analysis passed.

Science page (2026-07-10):

- Canonical route: `/app/science/`; navigation added to the main landing header and footer.
- React + TypeScript + Tailwind CSS + Framer Motion + Lucide source in `web/science/`.
- Static prerender output in `site/science/`; CI and Pages rebuild it before smoke/deploy.
- TFOS DEWS III, AAO PPP and ten additional DOI-linked references.
- OVPP and related-book positioning with explicit current-versus-future boundaries.
- MedicalWebPage JSON-LD, Open Graph and 1200×630 science social preview.
- Local Lighthouse mobile and desktop: 100/100/100/100.

Roadmap 4–5 (2026-07-10):

- Platform filter (All / macOS / Windows) on #capturas
- Five Windows slides (UI composites + store poster)
- Lighthouse script + docs/lighthouse/LATEST.md (Pages: mobile 93/90/100/100)

Previous phase: Landing round 2 (manifest, SEO, what's-new, FAQ install, smoke assets) + GitHub automation round 2.

Landing cycles round 2 (2026-07-10):

- site.webmanifest + apple-touch-icon + CSS preload
- og:locale, hreflang, robots meta
- Hero "Novidades 1.22" strip
- FAQ install blocked macOS/Windows + schema
- Nav/footer links + smoke required assets

Landing cycles round 1 (2026-07-10):

- Version badge + JSON-LD softwareVersion 1.22.7
- Skip link and focus-visible styles
- Feature cards: day summary + meeting/blink controls
- FAQ + schema for DVRS and v1.22 news
- Sitemap lastmod + smoke-check version sync with pubspec

Previous phase note: HealthKit was prototyped on a historical branch, but is not
part of the current `main` release.

Completed:

- Repository inspected.
- README, release links, authorship, and existing visual assets identified.
- Local operating summary, implementation contract, capability matrix, queues, and milestones created.
- Static landing maintained in `site/`.
- Single `/app/` landing route, language toggle, blog, SEO metadata, sitemap, robots, downloads, GitHub link, references and footer created.
- Local verification passed: check, build, smoke, production audit and Lighthouse.
- Professional photo of Dr. Philipe added to the medical authority card and article byline.
- Real app screenshots added to the carousel for floating widget, menu, break timer, settings, guidance and OSDI.
- Dry Eye Health Dashboard model and HealthKit source mapping defined.
- Native macOS HealthKit bridge added for permission request, sleep import and average heart-rate import.
- Dart HealthKit dashboard service added to normalize native rows into explicit dashboard periods.
- HealthKit privacy description and entitlements added to the macOS target.
- Health dashboard UI connected to `HealthKitDashboardService`.
- Optional HealthKit permission flow added to the app panel.
- Health dashboard added to the floating menu and system tray/menu bar.
- Fixed widget positioning across transient layouts: saved startup position is
  loaded as the canonical coordinate, menu/reminder clamping never mutates it,
  and closing a menu or a panel restores the immutable compact anchor.
- Scientific foundation page completed with responsive light/dark design, accessible flow diagrams and evidence-safe copy.

In progress:

- Publicação e verificação remota da release 1.26.0 e do GitHub Pages.
- Verification passed on 2026-06-21: `flutter analyze` and full `flutter test`.
- 2026-07-13: DVRS deixou de apresentar o total como risco clínico validado; UI, site e textos legais explicitam escopo educativo e não diagnóstico.
- Verificação: `flutter analyze`, smoke do site e 238 testes Flutter aprovados.

Risks:

- Production Lighthouse for `/app/science/` should be re-run after deployment to verify hosting headers and compression.
- Production deployment and DNS require external credentials if moving away from GitHub Pages.
- Developer ID/notarização continuam dependentes de credenciais Apple externas.
