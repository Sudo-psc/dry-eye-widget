import 'package:flutter_test/flutter_test.dart';
import 'package:dry_eye_widget/models/app_state.dart';
import 'package:dry_eye_widget/models/widget_settings.dart';

void main() {
  group('WidgetSettings', () {
    test('roundtrip JSON preserva todos os campos', () {
      final original = WidgetSettings.defaults().copyWith(
        cycleMinutes: 30,
        ballSize: 64,
        idleColor: 0xFF50C878,
        alertColor: 0xFFE91E63,
        idleOpacity: 0.7,
        blinkMs: 800,
        dimBackground: false,
        dimOpacity: 0.45,
        defaultCorner: BallCorner.bottomLeft,
        launchAtLogin: true,
        overlayOpacity: 0.3,
        overlayBlur: 12,
        showProgressRing: true,
        hideDockIcon: true,
        hideMenuBarItem: true,
        hideFloatingWidget: false,
        gentleMode: true,
        cameraPresence: true,
      );

      final restored = WidgetSettings.fromJson(original.toJson());

      expect(restored.cycleMinutes, 30);
      expect(restored.ballSize, 64);
      expect(restored.idleColor, 0xFF50C878);
      expect(restored.alertColor, 0xFFE91E63);
      expect(restored.idleOpacity, 0.7);
      expect(restored.blinkMs, 800);
      expect(restored.dimBackground, isFalse);
      expect(restored.dimOpacity, 0.45);
      expect(restored.defaultCorner, BallCorner.bottomLeft);
      expect(restored.launchAtLogin, isTrue);
      expect(restored.overlayOpacity, 0.3);
      expect(restored.overlayBlur, 12);
      expect(restored.showProgressRing, isTrue);
      expect(restored.hideDockIcon, isTrue);
      expect(restored.hideMenuBarItem, isTrue);
      expect(restored.hideFloatingWidget, isFalse);
      expect(restored.gentleMode, isTrue);
      expect(restored.cameraPresence, isTrue);
    });

    test('JSON inválido cai para os padrões', () {
      final s = WidgetSettings.fromJson('isso não é json');
      expect(s.cycleMinutes, WidgetSettings.defaults().cycleMinutes);
    });

    test('campos ausentes usam os padrões (compat. retroativa)', () {
      final s = WidgetSettings.fromMap(const <String, dynamic>{'cycleMinutes': 15});
      expect(s.cycleMinutes, 15);
      expect(s.ballSize, WidgetSettings.defaults().ballSize);
      expect(s.idleColor, WidgetSettings.defaults().idleColor);
    });

    test('conveniências derivadas', () {
      final s = WidgetSettings.defaults().copyWith(cycleMinutes: 5, blinkMs: 300);
      expect(s.cycleSeconds, 300);
      expect(s.blinkDuration, const Duration(milliseconds: 300));
    });
  });
}
