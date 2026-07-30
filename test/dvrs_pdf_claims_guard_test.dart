import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PDF público do DVRS não expõe score ou classificação de risco', () {
    final source = File(
      'lib/services/pdf_report_service.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('Carga relatada (0–100)')));
    expect(source, isNot(contains('latest.domainScores.valueFor')));
    expect(source, isNot(contains('classificationLabel')));
    expect(source, isNot(contains('Índice de Risco Visual Digital')));
    expect(source, isNot(contains('/100')));

    expect(source, contains('DVRS — autorregistro educativo'));
    expect(source, contains('Respostas autorreferidas'));
    expect(source, contains('kDvrsPdfLegalNotice'));
  });
}
