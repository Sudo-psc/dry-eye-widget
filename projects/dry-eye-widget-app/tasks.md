# Live Task Queues

## now

- [x] Implement blink micronotification in the Flutter widget.
- [x] Add settings toggle to disable visual blink reminders.
- [x] Add opt-in blink sound reminder with 4 tone choices and volume control.
- [x] Verify serialization, widget rendering, analyzer, tests, and macOS build.
- [x] Improve compact widget size, idle opacity, hover animation, dynamic orb defaults, and edge docking behavior.
- [x] Add focused tests for the new edge docking and docked widget behavior.
- [x] Verify with focused Flutter tests, full Flutter tests, analyzer, macOS debug build, and macOS release build.

## next

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

## recurring

- Re-run full tests and platform build before each desktop release.
- Re-check macOS and Windows floating-window behavior after window_manager upgrades.
