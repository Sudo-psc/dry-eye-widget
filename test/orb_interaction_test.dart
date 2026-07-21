import 'package:dry_eye_widget/app/orb_interaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('modo automático deriva capacidades dos callbacks disponíveis', () {
    final capabilities = resolveOrbInteraction(
      mode: OrbInteractionMode.automatic,
      hasActivationCallback: true,
      hasDragCallback: true,
    );

    expect(capabilities.canActivate, isTrue);
    expect(capabilities.canDrag, isTrue);
    expect(capabilities.isInteractive, isTrue);
  });

  test('modos explícitos restringem clique e arraste separadamente', () {
    final activation = resolveOrbInteraction(
      mode: OrbInteractionMode.activateOnly,
      hasActivationCallback: true,
      hasDragCallback: true,
    );
    final drag = resolveOrbInteraction(
      mode: OrbInteractionMode.dragOnly,
      hasActivationCallback: true,
      hasDragCallback: true,
    );
    final visual = resolveOrbInteraction(
      mode: OrbInteractionMode.visualOnly,
      hasActivationCallback: true,
      hasDragCallback: true,
    );

    expect(activation.canActivate, isTrue);
    expect(activation.canDrag, isFalse);
    expect(drag.canActivate, isFalse);
    expect(drag.canDrag, isTrue);
    expect(visual.isInteractive, isFalse);
  });

  test('modo explícito não anuncia ação sem callback real', () {
    final capabilities = resolveOrbInteraction(
      mode: OrbInteractionMode.activateAndDrag,
      hasActivationCallback: false,
      hasDragCallback: false,
    );

    expect(capabilities.canActivate, isFalse);
    expect(capabilities.canDrag, isFalse);
  });
}
