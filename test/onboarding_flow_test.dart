import 'package:dry_eye_widget/l10n/app_strings.dart';
import 'package:dry_eye_widget/models/widget_settings.dart';
import 'package:dry_eye_widget/widgets/onboarding/onboarding_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host({
  required Future<void> Function(WidgetSettings settings) onFinish,
  TextScaler textScaler = TextScaler.noScaling,
}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(size: const Size(480, 560), textScaler: textScaler),
    child: SizedBox(
      width: 480,
      height: 560,
      child: OnboardingFlow(
        strings: ptStrings,
        initial: WidgetSettings.defaults(),
        onFinish: onFinish,
      ),
    ),
  ),
);

void main() {
  testWidgets('personaliza ciclo, aparência e notificações antes de concluir', (
    tester,
  ) async {
    final finishes = <WidgetSettings>[];

    await tester.pumpWidget(
      _host(onFinish: (settings) async => finishes.add(settings)),
    );

    expect(
      find.byKey(const ValueKey('onboarding-cycle-slider')),
      findsOneWidget,
    );
    await tester.drag(
      find.byKey(const ValueKey('onboarding-cycle-slider')),
      const Offset(80, 0),
    );
    await tester.pump();

    await tester.tap(find.text('Próximo'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('onboarding-ball-preview')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('onboarding-size-slider')),
      findsOneWidget,
    );

    await tester.tap(find.text('Próximo'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('onboarding-notifications-switch')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('onboarding-notifications-switch')),
    );
    await tester.pump();

    await tester.tap(find.text('Começar'));
    await tester.pumpAndSettle();
    expect(finishes, hasLength(1));
    expect(finishes.single.notificationsEnabled, isFalse);
  });

  testWidgets('permanece utilizável com texto a 200%', (tester) async {
    await tester.pumpWidget(
      _host(onFinish: (_) async {}, textScaler: const TextScaler.linear(2)),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Próximo'), findsOneWidget);
    await tester.tap(find.text('Próximo'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey('onboarding-ball-preview')),
      findsOneWidget,
    );
  });

  testWidgets('persiste o rascunho uma única vez ao concluir', (tester) async {
    final finishes = <WidgetSettings>[];

    await tester.pumpWidget(
      _host(onFinish: (settings) async => finishes.add(settings)),
    );

    await tester.drag(
      find.byKey(const ValueKey('onboarding-cycle-slider')),
      const Offset(80, 0),
    );
    await tester.pump();
    expect(finishes, isEmpty);

    await tester.tap(find.text('Próximo'));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('onboarding-size-slider')),
      const Offset(60, 0),
    );
    await tester.pump();
    expect(finishes, isEmpty);

    await tester.tap(find.text('Próximo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Começar'));
    await tester.pumpAndSettle();

    expect(finishes, hasLength(1));
  });
}
