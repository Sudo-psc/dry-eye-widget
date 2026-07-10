# Status

Updated: 2026-07-09

Current phase: P0 + quick wins 1.22.1 (tray hub, i18n polish, post-onboarding discovery).

Completed:

- Quick wins: Day Summary in tray/menu bar; tray labels localized; Progress/Dashboard close tooltips and dashboard title localized; open Day Summary after onboarding.
- Added Day Summary hub (today’s breaks, streak, last DVRS, insight, CTAs).
- Unified local insight engine shared by Day Summary and My Progress.
- Soft DVRS re-evaluation nudge every 14 days (or after first breaks if never taken), with snooze and opt-out.
- Menu health section now leads with Day Summary; analyzer and focused/full tests verified on 2026-07-09.

Previously completed:

- Increased the default floating widget size from 24 px to 32 px and widened the allowed size range to 18-96 px.
- Lowered the default idle opacity to 82% and allowed user opacity down to 20%.
- Enabled the dynamic orb effect by default with lower intensity for a more modern but restrained idle animation.
- Reworked lateral docking so the compact window anchors partially outside the screen edge instead of only clipping the ball inside a fully visible window.
- Added stronger magnetic snap threshold, redock-on-startup behavior, stable redock after size changes, and clean undock when edge snapping is disabled.
- Replaced instant hover scale with a smooth hover animation controller, subtle live breathing, stronger glow on hover, and suppressed text pill while docked.
- Added focused tests for partial edge docking, docked clickability, docked reminder suppression, and updated settings normalization.
- Verified with focused tests, full test suite, static analysis, macOS debug build, and macOS release build.
- Reworked the DVRS questionnaire so all 16 questions appear in one scrollable page, with progress by answered count and a single calculation action after all responses are marked.
- Updated DVRS widget tests for the single-page flow, disabled calculation before completion, result calculation, and history persistence.
- Verified the DVRS change with focused widget tests, full Flutter tests, and static analysis.

Risks:

- The new partial off-screen docking should still be manually inspected on Windows because window managers can clamp off-screen positions differently.
- The dynamic orb effect is now enabled by default; monitor CPU/battery feedback during real use.
- Local Xcode reports CoreSimulator as out of date, but the macOS debug and release builds still completed successfully.
- The new DVRS page should still be manually checked in the real desktop window at narrow sizes to confirm the full-question scroll experience feels comfortable.
