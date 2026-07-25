import 'package:flutter/foundation.dart';

import '../l10n/app_strings.dart';
import '../l10n/system_language.dart';
import '../models/widget_settings.dart';
import '../services/storage_service.dart';

/// Detém as [WidgetSettings] atuais e as persiste a cada alteração.
///
/// É a fonte única de verdade para preferências de temporização, som e
/// aparência. Tanto a UI (cores, tamanho, escurecimento) quanto o
/// [TimerProvider] (durações, som, notificações) leem deste provider.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider({required StorageService storage})
    : _storage = storage,
      _settings = storage.loadSettings();

  final StorageService _storage;
  WidgetSettings _settings;

  WidgetSettings get value => _settings;

  /// Textos do idioma ativo.
  AppStrings get strings => AppStrings.of(_settings.languageCode);

  /// Substitui todas as configurações e persiste.
  Future<void> update(WidgetSettings next) async {
    final normalized = next.normalized();
    if (mapEquals(_settings.toMap(), normalized.toMap())) return;
    _settings = normalized;
    notifyListeners();
    await _storage.saveSettings(normalized);
  }

  /// Na primeira execução, alinha o idioma do app ao do sistema operacional.
  ///
  /// Só age enquanto não existem preferências gravadas — depois disso a escolha
  /// do usuário em Configurações manda. [localeTags] permite injetar os locales
  /// do SO nos testes; em produção vêm de [systemLocaleTags].
  ///
  /// Quando o idioma detectado já é o padrão, [update] não regrava nada: a
  /// detecção simplesmente se repete no próximo início com o mesmo resultado.
  Future<void> applySystemLanguageOnFirstRun({
    Iterable<String?>? localeTags,
  }) async {
    if (_storage.hasStoredSettings) return;
    final detected = resolveLanguageCode(localeTags ?? systemLocaleTags());
    await update(_settings.copyWith(languageCode: detected));
  }

  /// Restaura os valores de fábrica.
  Future<void> reset() => update(WidgetSettings.defaults());
}
