import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../utils/constants.dart';

enum UpdateStatus { upToDate, available, error }

class UpdateResult {
  const UpdateResult(this.status, {this.latestVersion});
  final UpdateStatus status;
  final String? latestVersion;
}

/// Verifica se há uma versão mais nova do app publicada no GitHub Releases e
/// abre a página de download quando solicitado.
///
/// Rede restrita a HTTPS nos hosts oficiais do GitHub (sem redirects arbitrários
/// para esquemas/hosts não permitidos).
class UpdateService {
  static const _allowedApiHosts = {'api.github.com'};
  static const _allowedBrowseHosts = {'github.com', 'www.github.com'};

  /// Consulta a última release e compara com [AppInfo.version].
  Future<UpdateResult> check() async {
    final uri = Uri.tryParse(AppInfo.latestReleaseApi);
    if (uri == null || !_isAllowedHttps(uri, _allowedApiHosts)) {
      debugPrint('UpdateService: URL de API recusada.');
      return const UpdateResult(UpdateStatus.error);
    }

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.getUrl(uri);
      // Sem redirects: evita pular o allowlist de host após 3xx.
      request.followRedirects = false;
      request.maxRedirects = 0;
      request.headers.set(HttpHeaders.userAgentHeader, 'DryEyeWidget');
      request.headers.set(
        HttpHeaders.acceptHeader,
        'application/vnd.github+json',
      );
      final response = await request.close();
      if (response.statusCode != 200) {
        await response.drain<void>();
        return const UpdateResult(UpdateStatus.error);
      }
      // Limita corpo (releases/latest é pequeno; protege memória).
      final body = await response
          .transform(utf8.decoder)
          .fold<StringBuffer>(StringBuffer(), (b, s) {
            if (b.length + s.length > 256 * 1024) {
              throw const FormatException('Resposta de update grande demais');
            }
            return b..write(s);
          })
          .then((b) => b.toString());
      final json = jsonDecode(body) as Map<String, dynamic>;
      final tag = (json['tag_name'] as String?) ?? '';
      final latest = _normalize(tag);
      if (latest.isEmpty) return const UpdateResult(UpdateStatus.error);

      final isNewer = _compare(latest, AppInfo.version) > 0;
      return UpdateResult(
        isNewer ? UpdateStatus.available : UpdateStatus.upToDate,
        latestVersion: latest,
      );
    } catch (e) {
      debugPrint('UpdateService: falha ($e).');
      return const UpdateResult(UpdateStatus.error);
    } finally {
      client.close(force: true);
    }
  }

  /// Abre a página de releases no navegador padrão.
  Future<void> openReleasesPage() async {
    final url = AppInfo.releasesPage;
    final uri = Uri.tryParse(url);
    if (uri == null || !_isAllowedHttps(uri, _allowedBrowseHosts)) {
      debugPrint('UpdateService: URL de releases recusada.');
      return;
    }
    try {
      if (Platform.isMacOS) {
        await Process.run('open', [url]);
      } else if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', url]);
      } else {
        await Process.run('xdg-open', [url]);
      }
    } catch (e) {
      debugPrint('UpdateService: não foi possível abrir a página ($e).');
    }
  }

  /// HTTPS + host allowlist. Exposto para testes.
  @visibleForTesting
  bool isAllowedHttpsUrl(String raw, {required bool api}) =>
      _isAllowedHttps(
        Uri.tryParse(raw) ?? Uri(),
        api ? _allowedApiHosts : _allowedBrowseHosts,
      );

  bool _isAllowedHttps(Uri uri, Set<String> hosts) {
    if (uri.scheme != 'https') return false;
    if (uri.userInfo.isNotEmpty) return false;
    final host = uri.host.toLowerCase();
    return hosts.contains(host);
  }

  /// Remove o "v" inicial e qualquer sufixo após o número.
  String _normalize(String tag) {
    final m = RegExp(r'(\d+)\.(\d+)\.(\d+)').firstMatch(tag);
    return m == null ? '' : '${m[1]}.${m[2]}.${m[3]}';
  }

  /// Exposto para testes.
  @visibleForTesting
  int compareVersions(String a, String b) => _compare(a, b);

  /// Compara duas versões "x.y.z". Retorna >0 se [a] > [b].
  int _compare(String a, String b) {
    final pa = a.split('.');
    final pb = b.split('.');
    for (var i = 0; i < 3; i++) {
      final valA = int.parse(pa[i]);
      final valB = int.parse(pb[i]);
      if (valA != valB) return valA - valB;
    }
    return 0;
  }
}
