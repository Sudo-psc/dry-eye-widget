# Status

Updated: 2026-07-06

Current phase: compact floating widget visual refresh implemented and verified locally.

Completed:

- Increased the default floating widget size from 24 px to 32 px and widened the allowed size range to 18-96 px.
- Lowered the default idle opacity to 82% and allowed user opacity down to 20%.
- Enabled the dynamic orb effect by default with lower intensity for a more modern but restrained idle animation.
- Reworked lateral docking so the compact window anchors partially outside the screen edge instead of only clipping the ball inside a fully visible window.
- Added stronger magnetic snap threshold, redock-on-startup behavior, stable redock after size changes, and clean undock when edge snapping is disabled.
- Replaced instant hover scale with a smooth hover animation controller, subtle live breathing, stronger glow on hover, and suppressed text pill while docked.
- Added focused tests for partial edge docking, docked clickability, docked reminder suppression, and updated settings normalization.
- Verified with focused tests, full test suite, static analysis, macOS debug build, and macOS release build.

Risks:

- The new partial off-screen docking should still be manually inspected on Windows because window managers can clamp off-screen positions differently.
- The dynamic orb effect is now enabled by default; monitor CPU/battery feedback during real use.
- Local Xcode reports CoreSimulator as out of date, but the macOS debug and release builds still completed successfully.
