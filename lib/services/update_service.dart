import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/constants.dart';

enum UpdateStatus { upToDate, available, error }

class UpdateResult {
  const UpdateResult(this.status, {this.latestVersion});
  final UpdateStatus status;
  final String? latestVersion;
}

/// Verifica se há uma versão mais nova do app publicada no GitHub Releases e
/// abre a página de download quando solicitado.
class UpdateService {
  /// Consulta a última release e compara com [AppInfo.version].
  Future<UpdateResult> check() async {
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10);
      final request = await client.getUrl(Uri.parse(AppInfo.latestReleaseApi));
      request.headers.set(HttpHeaders.userAgentHeader, 'DryEyeWidget');
      request.headers.set(
        HttpHeaders.acceptHeader,
        'application/vnd.github+json',
      );
      final response = await request.close();
      if (response.statusCode != 200) {
        client.close();
        return const UpdateResult(UpdateStatus.error);
      }
      final body = await response.transform(utf8.decoder).join();
      client.close();
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
    }
  }

  /// Abre a página de releases no navegador padrão.
  Future<void> openReleasesPage() async {
    final url = AppInfo.releasesPage;
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      debugPrint('UpdateService: não foi possível abrir a página ($e).');
    }
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
