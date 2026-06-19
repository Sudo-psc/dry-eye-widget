# Status

Updated: 2026-06-19

Current phase: HealthKit dashboard branch in progress for macOS-only native integration.

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

In progress:

- HealthKit dashboard UI still needs to be connected to `HealthKitDashboardService`.
- Verification passed on 2026-06-19: `flutter analyze`, focused dashboard tests, and unsigned Xcode release compile.

Risks:

- Windows-specific screenshots are still useful for final launch polish.
- Production deployment and DNS require external credentials if moving away from GitHub Pages.
- Signed macOS release build now requires a development/distribution certificate with HealthKit entitlement.
- Runtime HealthKit availability still needs validation on a signed Mac build with user permission granted.
