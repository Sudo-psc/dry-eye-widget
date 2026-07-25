import 'package:dry_eye_widget/l10n/system_language.dart';
import 'package:dry_eye_widget/models/widget_settings.dart';
import 'package:dry_eye_widget/providers/settings_provider.dart';
import 'package:dry_eye_widget/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('languageSubtagOf', () {
    test('extrai idioma dos formatos de macOS e Windows', () {
      expect(languageSubtagOf('pt_BR.UTF-8'), 'pt'); // macOS
      expect(languageSubtagOf('pt-BR'), 'pt'); // Windows
      expect(languageSubtagOf('en_US.UTF-8'), 'en');
      expect(languageSubtagOf('EN-GB'), 'en');
      expect(languageSubtagOf('es'), 'es');
      expect(languageSubtagOf('de_DE@euro'), 'de');
    });

    test('devolve null sem idioma identificável', () {
      expect(languageSubtagOf(null), isNull);
      expect(languageSubtagOf(''), isNull);
      expect(languageSubtagOf('   '), isNull);
      expect(languageSubtagOf('C'), isNull);
      expect(languageSubtagOf('POSIX'), isNull);
    });
  });

  group('resolveLanguageCode', () {
    test('adota português quando o SO está em português', () {
      expect(resolveLanguageCode(['pt_BR.UTF-8']), 'pt');
      expect(resolveLanguageCode(['pt-PT']), 'pt');
    });

    test('adota inglês quando o SO está em inglês', () {
      expect(resolveLanguageCode(['en-US']), 'en');
    });

    test('respeita a ordem de preferência do sistema', () {
      expect(resolveLanguageCode(['es-ES', 'pt-BR', 'en-US']), 'pt');
      expect(resolveLanguageCode(['fr-FR', 'en-US', 'pt-BR']), 'en');
    });

    test('cai em inglês quando nenhum idioma é suportado', () {
      expect(resolveLanguageCode(['de-DE', 'ja-JP']), 'en');
      expect(resolveLanguageCode(const <String?>[]), 'en');
      expect(resolveLanguageCode([null, '', 'C']), 'en');
    });
  });

  group('systemLocaleTags', () {
    test('devolve ao menos um locale no host de teste', () {
      final tags = systemLocaleTags();
      expect(tags, isNotEmpty);
      expect(resolveLanguageCode(tags), isIn(kSupportedLanguageCodes));
    });
  });

  group('applySystemLanguageOnFirstRun', () {
    test('configura o idioma do SO na primeira execução', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      final provider = SettingsProvider(storage: storage);
      expect(storage.hasStoredSettings, isFalse);

      await provider.applySystemLanguageOnFirstRun(localeTags: ['en-US']);

      expect(provider.value.languageCode, 'en');
      expect(storage.hasStoredSettings, isTrue);
    });

    test('não sobrescreve preferências já gravadas', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      final first = SettingsProvider(storage: storage);
      // Usuário já usou o app e gravou preferências com o idioma em português.
      await first.update(
        first.value.copyWith(languageCode: 'pt', cycleMinutes: 30),
      );
      expect(storage.hasStoredSettings, isTrue);

      final relaunch = SettingsProvider(storage: storage);
      await relaunch.applySystemLanguageOnFirstRun(localeTags: ['en-US']);

      expect(relaunch.value.languageCode, 'pt');
    });

    test('idioma não suportado no SO cai em inglês', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      final provider = SettingsProvider(storage: storage);

      await provider.applySystemLanguageOnFirstRun(localeTags: ['ja-JP']);

      expect(provider.value.languageCode, 'en');
    });

    test('mantém o restante das configurações padrão', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await StorageService.init();
      final provider = SettingsProvider(storage: storage);

      await provider.applySystemLanguageOnFirstRun(localeTags: ['en-US']);

      final defaults = WidgetSettings.defaults();
      expect(provider.value.cycleMinutes, defaults.cycleMinutes);
      expect(provider.value.onboardingComplete, isFalse);
    });
  });
}
