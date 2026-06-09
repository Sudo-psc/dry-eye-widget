import 'package:flutter_test/flutter_test.dart';
import 'package:dry_eye_widget/services/secure_storage_service.dart';
import 'package:dry_eye_widget/services/presence/secure_presence_store.dart';
import 'package:dry_eye_widget/services/presence/adaptive_threshold_model.dart';

/// Armazenamento seguro fake (em memória) para os testes.
class _FakeSecure implements SecureKeyValueStore {
  final Map<String, String> _data = {};
  String? forced; // valor cru a forçar em read (ex.: corrompido)

  @override
  Future<String?> read(String key) async => forced ?? _data[key];

  @override
  Future<void> write(String key, String value) async => _data[key] = value;

  @override
  Future<void> delete(String key) async => _data.remove(key);
}

void main() {
  const key = 'presence_model_enc';

  group('SecurePresenceStore', () {
    test('round-trip save/load preserva o mapa', () async {
      final secure = _FakeSecure();
      final store = SecurePresenceStore(secure, storageKey: key);
      final model = AdaptiveThresholdModel(minObservations: 1);
      model.observePresentGap(14, 200);

      await store.save(model.toMap());
      final loaded = await store.load();

      expect(loaded, isNotNull);
      final restored = AdaptiveThresholdModel.fromMap(loaded!);
      expect(restored.thresholdForHour(14), model.thresholdForHour(14));
    });

    test('load sem estado prévio retorna null', () async {
      final store = SecurePresenceStore(_FakeSecure(), storageKey: key);
      expect(await store.load(), isNull);
    });

    test('clear remove o estado', () async {
      final secure = _FakeSecure();
      final store = SecurePresenceStore(secure, storageKey: key);
      await store.save({'v': 1});
      await store.clear();
      expect(await store.load(), isNull);
    });

    test('estado corrompido cai para null (cold start)', () async {
      final secure = _FakeSecure()..forced = 'isso não é json {{{';
      final store = SecurePresenceStore(secure, storageKey: key);
      expect(await store.load(), isNull);
    });
  });
}
