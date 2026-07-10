# Live Task Queues

## now

- [x] P0 product: Day Summary hub + proactive insight + DVRS recheck nudge (v1.22.0).
- [x] Quick wins 1.22.1: tray Day Summary + tray i18n; localize close tooltips/dashboard title; open Day Summary after onboarding.
- [x] Quick wins 1.22.2: completion insight; dashboard tab i18n; reports header i18n.
- [x] Five quick-win cycles 1.22.3–1.22.7 (15 items) released as v1.22.7.
- [x] Implement blink micronotification in the Flutter widget.
- [x] Add settings toggle to disable visual blink reminders.
- [x] Add opt-in blink sound reminder with 4 tone choices and volume control.
- [x] Verify serialization, widget rendering, analyzer, tests, and macOS build.
- [x] Improve compact widget size, idle opacity, hover animation, dynamic orb defaults, and edge docking behavior.
- [x] Add focused tests for the new edge docking and docked widget behavior.
- [x] Verify with focused Flutter tests, full Flutter tests, analyzer, macOS debug build, and macOS release build.
- [x] Convert the DVRS questionnaire from one-question-per-step to a single scrollable page.
- [x] Verify the DVRS single-page flow with focused widget tests and static analysis.

## next

- [ ] Manually inspect Day Summary, DVRS nudge banner/snooze, and optional system notification on macOS.
- [ ] Manually inspect the DVRS single-page questionnaire in the desktop window, especially narrow window widths and long option labels.
- [ ] Manually inspect left and right edge docking on macOS with real dragging, hover, click-to-undock, and size changes.
- [ ] Manually inspect left and right edge docking on Windows before the next Windows package.
- [ ] Manually inspect the micronotification on Windows before packaging a Windows release.
- [ ] Consider a future intensity/frequency control if user testing shows the cue is still too frequent or too subtle.

## blocked

- Windows runtime inspection is blocked until a Windows build/test environment is used.
- Signed macOS release validation remains blocked until signing/provisioning is available for the HealthKit entitlement.

## improve

- Add an integration-level window layout test if a reliable desktop window harness is introduced.
- Add a small desktop visual QA script or harness for edge docking screenshots after window_manager upgrades.
- Add a visual regression or golden-style check for the DVRS question list if the project adopts stable desktop widget snapshots.

## recurring

- Re-run full tests and platform build before each desktop release.
- Re-check macOS and Windows floating-window behavior after window_manager upgrades.
