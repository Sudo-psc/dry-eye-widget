import 'dart:io' show Platform;
import 'dart:ui' show PlatformDispatcher;

/// Idiomas efetivamente traduzidos no app.
const Set<String> kSupportedLanguageCodes = {'pt', 'en'};

/// Idioma usado quando o SO não está em nenhum idioma suportado.
///
/// Inglês é a escolha internacional mais segura: um SO em alemão ou japonês
/// fica mais próximo do inglês do que do português.
const String kFallbackLanguageCode = 'en';

/// Extrai o subtag de idioma de um identificador de locale do sistema.
///
/// Aceita os formatos que macOS e Windows devolvem: `pt_BR.UTF-8`, `pt-BR`,
/// `pt`. Devolve `null` para entradas vazias ou sem idioma (`C`, `POSIX`).
String? languageSubtagOf(String? locale) {
  if (locale == null) return null;
  final raw = locale.trim();
  if (raw.isEmpty) return null;

  // Corta encoding (`.UTF-8`), modificador (`@euro`) e região (`_BR` / `-BR`).
  final head = raw.split('.').first.split('@').first;
  final subtag = head.split(RegExp(r'[_-]')).first.toLowerCase();

  if (subtag.isEmpty) return null;
  // `C` e `POSIX` não identificam idioma algum.
  if (subtag == 'c' || subtag == 'posix') return null;
  return subtag;
}

/// Primeiro idioma suportado entre [candidates], em ordem de preferência.
///
/// Cai em [kFallbackLanguageCode] quando nenhum candidato é suportado.
String resolveLanguageCode(Iterable<String?> candidates) {
  for (final candidate in candidates) {
    final subtag = languageSubtagOf(candidate);
    if (subtag != null && kSupportedLanguageCodes.contains(subtag)) {
      return subtag;
    }
  }
  return kFallbackLanguageCode;
}

/// Locales preferidos do SO (macOS/Windows), do mais para o menos preferido.
///
/// Usa a lista do `PlatformDispatcher` — que reflete a ordem configurada pelo
/// usuário no sistema — e completa com `Platform.localeName` como rede de
/// segurança para ambientes em que a lista chega vazia.
List<String> systemLocaleTags() {
  final tags = <String>[];

  try {
    for (final locale in PlatformDispatcher.instance.locales) {
      tags.add(locale.toLanguageTag());
    }
  } catch (_) {
    // Sem binding disponível: segue apenas com o locale do processo.
  }

  try {
    tags.add(Platform.localeName);
  } catch (_) {
    // `localeName` pode falhar se o SO não expõe locale; ignorar.
  }

  return tags;
}

/// Idioma do app alinhado ao idioma do sistema operacional.
String systemLanguageCode() => resolveLanguageCode(systemLocaleTags());
