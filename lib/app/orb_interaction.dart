import 'package:flutter/foundation.dart';

/// Política explícita para limitar as interações oferecidas pelo orbe.
///
/// [automatic] preserva a integração existente ao inferir as capacidades a
/// partir dos callbacks fornecidos. Os demais modos permitem que a superfície
/// hospede o mesmo widget em contextos mais restritos sem callbacks-fantasma.
enum OrbInteractionMode {
  automatic,
  activateOnly,
  dragOnly,
  activateAndDrag,
  visualOnly;

  bool get allowsActivation => switch (this) {
    OrbInteractionMode.automatic ||
    OrbInteractionMode.activateOnly ||
    OrbInteractionMode.activateAndDrag => true,
    OrbInteractionMode.dragOnly || OrbInteractionMode.visualOnly => false,
  };

  bool get allowsDrag => switch (this) {
    OrbInteractionMode.automatic ||
    OrbInteractionMode.dragOnly ||
    OrbInteractionMode.activateAndDrag => true,
    OrbInteractionMode.activateOnly || OrbInteractionMode.visualOnly => false,
  };
}

@immutable
class OrbInteractionCapabilities {
  const OrbInteractionCapabilities({
    required this.canActivate,
    required this.canDrag,
  });

  final bool canActivate;
  final bool canDrag;

  bool get isInteractive => canActivate || canDrag;
}

/// Resolve o modo desejado sem anunciar ações que não possuem callback real.
OrbInteractionCapabilities resolveOrbInteraction({
  required OrbInteractionMode mode,
  required bool hasActivationCallback,
  required bool hasDragCallback,
}) {
  return OrbInteractionCapabilities(
    canActivate: mode.allowsActivation && hasActivationCallback,
    canDrag: mode.allowsDrag && hasDragCallback,
  );
}
