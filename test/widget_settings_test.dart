import 'package:flutter_test/flutter_test.dart';
import 'package:dry_eye_widget/models/app_state.dart';
import 'package:dry_eye_widget/models/widget_settings.dart';

void main() {
  group('WidgetSettings', () {
    test('roundtrip JSON preserva todos os campos', () {
      final original = WidgetSettings.defaults().copyWith(
        cycleMinutes: 30,
        visualBlinkRemindersEnabled: false,
        blinkReminderSoundEnabled: true,
        blinkReminderSound: BlinkReminderSound.warmBell,
        blinkReminderVolume: 0.64,
        ballSize: 64,
        idleColor: 0xFF50C878,
        alertColor: 0xFFE91E63,
        idleOpacity: 0.7,
        blinkMs: 800,
        dynamicOrbEffect: true,
        hoverReactiveBall: false,
        orbIntensity: 0.42,
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
        lockScreenOnBreak: true,
        screenTimeTracking: false,
        cameraPresence: true,
      );

      final restored = WidgetSettings.fromJson(original.toJson());

      expect(restored.cycleMinutes, 30);
      expect(restored.visualBlinkRemindersEnabled, isFalse);
      expect(restored.blinkReminderSoundEnabled, isTrue);
      expect(restored.blinkReminderSound, BlinkReminderSound.warmBell);
      expect(restored.blinkReminderVolume, 0.64);
      expect(restored.ballSize, 64);
      expect(restored.idleColor, 0xFF50C878);
      expect(restored.alertColor, 0xFFE91E63);
      expect(restored.idleOpacity, 0.7);
      expect(restored.blinkMs, 800);
      expect(restored.dynamicOrbEffect, isTrue);
      expect(restored.hoverReactiveBall, isFalse);
      expect(restored.orbIntensity, 0.42);
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
      expect(restored.lockScreenOnBreak, isTrue);
      expect(restored.screenTimeTracking, isFalse);
      expect(restored.cameraPresence, isTrue);
    });

    test('usesFullScreenBreak respeita o modo suave e o bloqueio', () {
      final base = WidgetSettings.defaults();
      // Sem modo suave: sempre tela cheia.
      expect(base.copyWith(gentleMode: false).usesFullScreenBreak, isTrue);
      // Modo suave sem bloqueio: cartão discreto.
      expect(
        base
            .copyWith(gentleMode: true, lockScreenOnBreak: false)
            .usesFullScreenBreak,
        isFalse,
      );
      // Modo suave com bloqueio: tela cheia tem precedência.
      expect(
        base
            .copyWith(gentleMode: true, lockScreenOnBreak: true)
            .usesFullScreenBreak,
        isTrue,
      );
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
      expect(
        s.visualBlinkRemindersEnabled,
        WidgetSettings.defaults().visualBlinkRemindersEnabled,
      );
      expect(
        s.blinkReminderSoundEnabled,
        WidgetSettings.defaults().blinkReminderSoundEnabled,
      );
      expect(
        s.blinkReminderSound,
        WidgetSettings.defaults().blinkReminderSound,
      );
      expect(
        s.blinkReminderVolume,
        WidgetSettings.defaults().blinkReminderVolume,
      );
      expect(s.idleColor, WidgetSettings.defaults().idleColor);
      expect(s.dynamicOrbEffect, WidgetSettings.defaults().dynamicOrbEffect);
      expect(s.hoverReactiveBall, WidgetSettings.defaults().hoverReactiveBall);
    });

    test('efeito dinamico fica ligado por padrao', () {
      expect(WidgetSettings.defaults().dynamicOrbEffect, isTrue);
    });

    test('lembretes visuais de piscada ficam ligados por padrao', () {
      expect(WidgetSettings.defaults().visualBlinkRemindersEnabled, isTrue);
    });

    test('densidade de UI padrão é confortável e persiste', () {
      expect(WidgetSettings.defaults().uiDensity, UiDensity.comfortable);
      final compact = WidgetSettings.defaults().copyWith(
        uiDensity: UiDensity.compact,
      );
      final restored = WidgetSettings.fromMap(compact.toMap());
      expect(restored.uiDensity, UiDensity.compact);
      final missing = WidgetSettings.fromMap(const <String, dynamic>{});
      expect(missing.uiDensity, UiDensity.comfortable);
    });

    test('lembrete sonoro de piscada exige opt-in por padrao', () {
      final defaults = WidgetSettings.defaults();
      expect(defaults.blinkReminderSoundEnabled, isFalse);
      expect(defaults.blinkReminderSound, BlinkReminderSound.softPulse);
      expect(defaults.blinkReminderVolume, 0.3);
      expect(BlinkReminderSound.values, hasLength(4));
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
        'orbIntensity': 9.0,
        'dimOpacity': 2.0,
        'overlayOpacity': -0.2,
        'overlayBlur': 200,
        'languageCode': 'es',
        'eyeDropsIntervalHours': 9,
        'blinkReminderSound': 999,
        'blinkReminderVolume': 4.2,
      });

      expect(restored.cycleMinutes, 1);
      expect(restored.phaseSeconds, 120);
      expect(restored.ballSize, 96);
      expect(restored.idleOpacity, 0.2);
      expect(restored.blinkMs, 200);
      expect(restored.orbIntensity, 1.0);
      expect(restored.dimOpacity, 0.6);
      expect(restored.overlayOpacity, 0.05);
      expect(restored.overlayBlur, 40);
      expect(restored.languageCode, WidgetSettings.defaults().languageCode);
      expect(
        restored.eyeDropsIntervalHours,
        WidgetSettings.defaults().eyeDropsIntervalHours,
      );
      expect(
        restored.blinkReminderSound,
        WidgetSettings.defaults().blinkReminderSound,
      );
      expect(restored.blinkReminderVolume, 1.0);
    });

    test('permite widget compacto com tamanho minimo de 18 px', () {
      final restored = WidgetSettings.fromMap(const <String, dynamic>{
        'ballSize': 1,
      });

      expect(restored.ballSize, 18);
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
