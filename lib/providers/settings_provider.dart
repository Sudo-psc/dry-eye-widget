import 'package:flutter/foundation.dart';

import '../l10n/app_strings.dart';
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
    _settings = normalized;
    notifyListeners();
    await _storage.saveSettings(normalized);
  }

  /// Restaura os valores de fábrica.
  Future<void> reset() => update(WidgetSettings.defaults());
}
