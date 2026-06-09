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
      final s = WidgetSettings.fromMap(const <String, dynamic>{
        'cycleMinutes': 15,
      });
      expect(s.cycleMinutes, 15);
      expect(s.ballSize, WidgetSettings.defaults().ballSize);
      expect(s.idleColor, WidgetSettings.defaults().idleColor);
    });

    test(
      'mantém ao menos um controle visível quando configurações entram em conflito',
      () {
        final restored = WidgetSettings.fromMap(const <String, dynamic>{
          'hideMenuBarItem': true,
          'hideFloatingWidget': true,
        });
        expect(restored.hideMenuBarItem, isFalse);
        expect(restored.hideFloatingWidget, isTrue);

        final copied = WidgetSettings.defaults().copyWith(
          hideMenuBarItem: true,
          hideFloatingWidget: true,
        );
        expect(copied.hideMenuBarItem, isFalse);
        expect(copied.hideFloatingWidget, isTrue);
      },
    );

    test('normaliza valores persistidos fora das faixas da tela', () {
      final restored = WidgetSettings.fromMap(const <String, dynamic>{
        'cycleMinutes': -3,
        'phaseSeconds': 999,
        'ballSize': 500,
        'idleOpacity': -1.0,
        'blinkMs': 50,
        'dimOpacity': 2.0,
        'overlayOpacity': -0.2,
        'overlayBlur': 200,
        'languageCode': 'es',
        'eyeDropsIntervalHours': 9,
      });

      expect(restored.cycleMinutes, 1);
      expect(restored.phaseSeconds, 120);
      expect(restored.ballSize, 80);
      expect(restored.idleOpacity, 0.3);
      expect(restored.blinkMs, 200);
      expect(restored.dimOpacity, 0.6);
      expect(restored.overlayOpacity, 0.05);
      expect(restored.overlayBlur, 40);
      expect(restored.languageCode, WidgetSettings.defaults().languageCode);
      expect(
        restored.eyeDropsIntervalHours,
        WidgetSettings.defaults().eyeDropsIntervalHours,
      );
    });

    test('conveniências derivadas', () {
      final s = WidgetSettings.defaults().copyWith(
        cycleMinutes: 5,
        blinkMs: 300,
      );
      expect(s.cycleSeconds, 300);
      expect(s.blinkDuration, const Duration(milliseconds: 300));
    });
  });
}
