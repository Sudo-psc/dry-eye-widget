import 'dart:io';

import 'package:dry_eye_widget/l10n/app_strings.dart';
import 'package:dry_eye_widget/services/tray_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('init captura falha de renderização do ícone no macOS', () async {
    if (!Platform.isMacOS) return;

    final service = TrayService();
    final realTemp = Directory.systemTemp.path;
    final missingTemp = Directory(
      '$realTemp/dry_eye_widget_missing_tray_test/nested',
    );
    final messages = <String>[];
    final originalDebugPrint = debugPrint;

    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) messages.add(message);
    };
    addTearDown(() {
      debugPrint = originalDebugPrint;
    });

    await expectLater(
      IOOverrides.runZoned<Future<void>>(
        () => service.init(widgetEnabled: true, strings: ptStrings),
        getSystemTempDirectory: () => missingTemp,
      ),
      completes,
    );

    expect(
      messages.any(
        (message) => message.contains('TrayService: render/setIcon falhou'),
      ),
      isTrue,
    );

    // A falha na inicialização deixa o serviço indisponível para updates
    // subsequentes, sem propagar exceções para o chamador.
    await expectLater(service.updateProgress(0.5), completes);
  });
}
