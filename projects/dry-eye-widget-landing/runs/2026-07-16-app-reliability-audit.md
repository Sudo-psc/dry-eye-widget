# App Reliability Audit Evidence — 2026-07-16

Objective: inspect the Flutter app and native-window lifecycle for reproducible
bugs, implement focused fixes and verify the resulting macOS release locally.

Scope reviewed:

- app and service lifecycle;
- compact, menu, panel, reminder and break layout transitions;
- widget drag, docking and undocking;
- multi-monitor screen selection;
- local activity and screen-time persistence;
- existing settings, DVRS, report, update and native bridge boundaries.

Confirmed defects and fixes:

1. Multi-monitor operations always used the primary display. A pure display
   selector now chooses the screen containing the window center, or the nearest
   valid screen when the window is between displays. Drag release, docking,
   undocking and screen nudging use that selection.
2. Starting an automatic break while a centered panel was open could cache the
   panel coordinate as the compact widget position. Transient layouts now keep
   the immutable compact anchor and break entry does not recache the window.
3. Tray quit closed the window without guaranteeing persistence of the most
   recent activity and screen-time data. Shutdown now awaits both flush paths,
   and activity stop flushes pending samples even when monitoring already stopped.
4. The launch-at-startup package requires an application-owned platform channel
   on macOS, but the runner did not register it. The runner now implements the
   channel with ServiceManagement on macOS 13 or later and validates its inputs.

Verification evidence:

- flutter analyze: passed with no issues;
- focused regression group: 32 tests passed;
- complete flutter test suite: 261 tests passed;
- flutter build macos --release -t lib/main.dart: passed, 59.4 MB;
- codesign --verify --deep --strict: passed;
- local release launch: process 67893, no MissingPluginException, and an
  on-screen native window confirmed through CoreGraphics;
- macOS confirmed the saved launch-at-login preference with its native login
  item notification.

Non-blocking observations:

- Flutter reports that local_notifier does not yet support Swift Package Manager;
- PDF tests emit pre-existing Helvetica Unicode fallback warnings while passing;
- rapid DVRS/settings writes remain an improvement candidate if runtime evidence
  demonstrates overlapping-write loss.
- launch-at-login on macOS 10.15-12 still requires either a bundled legacy
  helper or a documented macOS 13 minimum for this specific feature.
