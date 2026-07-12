# Status

Updated: 2026-07-12

Current phase: Widget animation performance optimized and fully validated.

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

Previous phase note: the macOS-only HealthKit integration is implemented; signed runtime validation remains pending.

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
- Fixed widget positioning bug: `_ballPosition` now syncs with saved storage on startup, `_nudgeIntoScreen` updates the cached position, and `blinkReminder` layout caches position before applying.
- Scientific foundation page completed with responsive light/dark design, accessible flow diagrams and evidence-safe copy.

In progress:

- Signed runtime validation with real HealthKit permissions and samples is still pending.
- Verification passed on 2026-06-21: `flutter analyze` and full `flutter test`.

Risks:

- Production Lighthouse for `/app/science/` should be re-run after deployment to verify hosting headers and compression.
- Production deployment and DNS require external credentials if moving away from GitHub Pages.
- Signed macOS release build now requires a development/distribution certificate with HealthKit entitlement.
- Runtime HealthKit availability still needs validation on a signed Mac build with user permission granted.
