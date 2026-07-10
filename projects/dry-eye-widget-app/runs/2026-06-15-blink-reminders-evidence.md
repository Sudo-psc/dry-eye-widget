# Blink Reminders Evidence

Date: 2026-06-15

## Change

Implemented widget-level blink micronotifications:

- Persisted setting: `visualBlinkRemindersEnabled`.
- Persisted sound settings: `blinkReminderSoundEnabled`, `blinkReminderSound`, and `blinkReminderVolume`.
- Visual default: enabled.
- Sound default: disabled, opt-in.
- Cadence: every 7.5 seconds, equivalent to 8 cues per minute.
- Visual behavior: compact widget temporarily expands into a small animated pill with localized text.
- Sound behavior: optional gentle tone on each blink reminder, 4 tone choices, volume slider.
- Disable paths: Settings -> Temporizacao -> Lembretes visuais de piscada; Settings -> Temporizacao -> Aviso sonoro de piscada.

## Verification

Targeted tests:

- Command: `flutter test test/widget_settings_test.dart test/floating_ball_test.dart`
- Result: passed, 13 tests.
- Command: `flutter test test/widget_settings_test.dart test/settings_dialog_test.dart test/floating_ball_test.dart`
- Result: passed, 18 tests.

Static analysis:

- Command: `flutter analyze`
- Result: passed, no issues found.

Full tests:

- Command: `flutter test`
- Result: passed, 68 tests.

Platform build:

- Command: `flutter build macos`
- Result: passed, built `build/macos/Build/Products/Release/Dry Eye Widget.app`.

## Notes

- Flutter emitted existing warnings about macOS plugins not supporting Swift Package Manager.
- macOS build emitted an existing package warning about `objective_c.dylib` framework naming across architectures.
