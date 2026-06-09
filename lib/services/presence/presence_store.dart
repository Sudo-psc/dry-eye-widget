/// Persiste o estado agregado do modelo de presença (apenas contagens
/// agregadas; nunca eventos brutos, timestamps ou imagens).
abstract class PresenceStore {
  Future<Map<String, dynamic>?> load();
  Future<void> save(Map<String, dynamic> state);
  Future<void> clear();
}

/// Implementação volátil para testes e fase 1 (reaprende a cada sessão até a
/// fase 2 trocar pelo store cifrado).
class InMemoryPresenceStore implements PresenceStore {
  Map<String, dynamic>? _state;

  @override
  Future<Map<String, dynamic>?> load() async => _state;

  @override
  Future<void> save(Map<String, dynamic> state) async => _state = state;

  @override
  Future<void> clear() async => _state = null;
}
