# 2026-07-06 Widget Visual Refresh Evidence

## Change Summary

- Updated compact widget defaults: size 32 px, idle opacity 82%, dynamic orb on by default, intensity 72%, size range 18-96 px.
- Added smoother hover amplification via a dedicated animation controller.
- Added subtle idle breathing when the dynamic orb effect is active.
- Reworked lateral docking to position the compact window partially off-screen with 62% visible.
- Added redock handling on startup and size changes, plus automatic undock when edge snap is disabled.
- Suppressed blink reminder pill text while docked.

## Verification

- `flutter test test/widget_settings_test.dart test/edge_snap_test.dart test/floating_ball_test.dart test/settings_dialog_test.dart`: passed.
- `flutter analyze`: passed.
- `flutter test`: passed.
- `flutter build macos --debug -t lib/main.dart`: passed and produced `build/macos/Build/Products/Debug/Dry Eye Widget.app`.
- `flutter build macos --release -t lib/main.dart`: passed and produced `build/macos/Build/Products/Release/Dry Eye Widget.app` (59.0 MB).

## Environment Notes

- `xcodebuild -workspace macos/Runner.xcworkspace -scheme Runner -configuration Debug CODE_SIGNING_ALLOWED=NO build` initially failed because generated Flutter ephemeral files pointed to missing `tool/dock_shot.dart`.
- `flutter build macos --debug -t lib/main.dart` regenerated the target and completed successfully.
- Xcode reported CoreSimulator version mismatch, but macOS debug and release builds still succeeded.

## Follow-up

- Manual visual QA on macOS for left/right dock, hover, click-to-undock, settings size changes, and opacity.
- Manual visual QA on Windows because off-screen docking can be platform-specific.
