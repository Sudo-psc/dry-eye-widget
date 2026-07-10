# Status

Updated: 2026-07-10

Current phase: ROADMAP Now items 4–5 done — Windows screenshots on landing + Lighthouse production baseline.

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

Previous phase note: HealthKit dashboard branch in progress for macOS-only native integration.

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

In progress:

- Signed runtime validation with real HealthKit permissions and samples is still pending.
- Verification passed on 2026-06-21: `flutter analyze` and full `flutter test`.

Risks:

- Windows-specific screenshots are still useful for final launch polish.
- Production deployment and DNS require external credentials if moving away from GitHub Pages.
- Signed macOS release build now requires a development/distribution certificate with HealthKit entitlement.
- Runtime HealthKit availability still needs validation on a signed Mac build with user permission granted.
