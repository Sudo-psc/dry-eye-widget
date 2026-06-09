import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../secure_storage_service.dart';
import 'presence_store.dart';

/// [PresenceStore] que persiste o estado agregado cifrado em repouso pelo SO
/// (Keychain/DPAPI) via [SecureKeyValueStore].
///
/// Guarda apenas o mapa serializado do modelo (contagens agregadas); nunca
/// eventos brutos, timestamps ou imagens. Falhas de leitura/parse caem para
/// `null`, fazendo o modelo recomeçar do cold start.
class SecurePresenceStore implements PresenceStore {
  SecurePresenceStore(this._secure, {required this.storageKey});

  final SecureKeyValueStore _secure;
  final String storageKey;

  @override
  Future<Map<String, dynamic>?> load() async {
    final raw = await _secure.read(storageKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (e) {
      debugPrint('SecurePresenceStore: estado inválido, ignorando ($e).');
      return null;
    }
  }

  @override
  Future<void> save(Map<String, dynamic> state) =>
      _secure.write(storageKey, jsonEncode(state));

  @override
  Future<void> clear() => _secure.delete(storageKey);
}
