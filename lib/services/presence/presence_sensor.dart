/// Resultado de uma amostragem de presença por um sensor.
enum Presence {
  /// Há evidência de que o usuário está presente.
  present,

  /// Há evidência de que o usuário está ausente.
  absent,

  /// O sensor não consegue decidir (deixa a decisão para o controller).
  unknown,
}

/// Fonte de sinal de presença plugável (input do SO, câmera, etc.).
///
/// Manter sensores atrás desta interface permite testar o controller com
/// fakes e adicionar novas modalidades sem reescrever a orquestração.
abstract class PresenceSensor {
  /// Amostra o sinal agora. Deve ser barata e não lançar — sensores
  /// indisponíveis retornam [Presence.unknown].
  Future<Presence> sample();
}
