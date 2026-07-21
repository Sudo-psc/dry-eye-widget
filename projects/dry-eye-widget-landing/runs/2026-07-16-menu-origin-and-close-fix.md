# Menu Origin and Close Fix Evidence — 2026-07-16

Reported behavior:

- clicking the orb while the menu was open did not close it reliably;
- the orb stayed fixed in the expanded window's top-left corner instead of
  remaining near its compact visual origin.

Root causes:

- the native menu window was clamped to the visible screen, but the orb always
  used a fixed local top-left layout inside that moved window;
- the open-menu orb reused the generic toggle callback and retained pan gesture
  recognizers even though dragging was disabled.

Implemented correction:

- `placeMenuWindow` calculates both the clamped native window position and the
  compensating local orb offset;
- the resulting screen coordinate of the orb matches its compact-mode visual
  coordinate, including near the right edge;
- the panel switches above the orb near the bottom edge and remains below it
  when space permits;
- the menu orb invokes the explicit close callback and has no pan recognizers.

Verification:

- `flutter analyze`: passed with no issues;
- focused window-layout and floating-orb tests: 23 passed;
- complete Flutter suite: 264 passed;
- macOS release build: passed, 59.4 MB;
- local ad-hoc signature reseal and strict deep verification: passed;
- release process 87550 launched with an on-screen native widget window.

Non-blocking observations:

- automated physical clicking remains dependent on macOS Accessibility and
  Retina coordinate permissions; the deterministic gesture and geometry paths
  are covered by regression tests;
- Flutter continues to warn that local_notifier lacks Swift Package Manager
  support.
