import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'superfícies públicas não reintroduzem claims clínicos antigos do DVRS',
    () {
      const paths = <String>[
        'lib/l10n/app_strings.dart',
        'lib/widgets/dashboard/dashboard_screen.dart',
        'lib/widgets/dvrs/dvrs_history_view.dart',
        'lib/widgets/dvrs/dvrs_result_view.dart',
        'lib/widgets/dvrs/dvrs_screen.dart',
        'site/index.html',
        'site/scripts/i18n.js',
      ];
      const forbidden = <String>[
        'índice de risco visual digital',
        'risco visual digital',
        'digital visual risk',
        'risco moderado',
        'risco elevado',
        'risco muito elevado',
        'baixo risco visual',
        'moderate risk',
        'high risk',
        'very high risk',
      ];

      for (final path in paths) {
        final contents = File(path).readAsStringSync().toLowerCase();
        for (final phrase in forbidden) {
          expect(
            contents,
            isNot(contains(phrase)),
            reason: 'Claim obsoleto "$phrase" encontrado em $path',
          );
        }
      }
    },
  );

  test('superfícies DVRS mantêm enquadramento educativo explícito', () {
    final resultView = File(
      'lib/widgets/dvrs/dvrs_result_view.dart',
    ).readAsStringSync();
    final landing = File('site/index.html').readAsStringSync();

    expect(resultView, contains('Não é instrumento clínico validado'));
    expect(landing, contains('autorregistro educativo'));
    expect(landing, contains('não é um instrumento clínico validado'));
  });
}
