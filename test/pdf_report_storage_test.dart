import 'dart:io';

import 'package:dry_eye_widget/services/pdf_report_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.flutter.io/path_provider');
  final service = PdfReportService();
  final bytes = Uint8List.fromList([37, 80, 68, 70, 45, 49, 46, 55]);
  late Directory root;
  late String? downloads;
  late String documents;
  late bool failDownloadsLookup;
  late int documentsLookups;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('pdf_report_storage_test_');
    downloads = '${root.path}/Downloads';
    documents = '${root.path}/Documents';
    failDownloadsLookup = false;
    documentsLookups = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getDownloadsDirectory') {
            if (failDownloadsLookup) {
              throw PlatformException(code: 'unavailable');
            }
            return downloads;
          }
          if (call.method == 'getApplicationDocumentsDirectory') {
            documentsLookups++;
            return documents;
          }
          throw MissingPluginException();
        });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await root.delete(recursive: true);
  });

  test('salva todos os bytes em Downloads sem consultar Documentos', () async {
    final file = await service.savePdfToDevice(bytes, 'report');

    expect(file.path, '$downloads/report.pdf');
    expect(await file.readAsBytes(), bytes);
    expect(documentsLookups, 0);
  });

  test(
    'usa Documentos quando o caminho Downloads não permite gravar',
    () async {
      // Um arquivo no lugar da pasta gera falha real de I/O em qualquer SO,
      // sem depender de chmod ou do usuário que executa os testes.
      await File(downloads!).writeAsString('existing file');

      final file = await service.savePdfToDevice(bytes, 'report');

      expect(file.path, '$documents/report.pdf');
      expect(await file.readAsBytes(), bytes);
      expect(await File(downloads!).readAsString(), 'existing file');
    },
  );

  test('usa Documentos quando Downloads não está disponível', () async {
    downloads = null;

    final file = await service.savePdfToDevice(bytes, 'report');

    expect(file.path, '$documents/report.pdf');
    expect(await file.readAsBytes(), bytes);
  });

  test('usa Documentos quando a consulta de Downloads falha', () async {
    failDownloadsLookup = true;

    final file = await service.savePdfToDevice(bytes, 'report');

    expect(file.path, '$documents/report.pdf');
    expect(await file.readAsBytes(), bytes);
  });

  test('propaga falha se nenhum destino aceitar a gravação', () async {
    await File(downloads!).writeAsString('existing downloads');
    await File(documents).writeAsString('existing documents');

    await expectLater(
      service.savePdfToDevice(bytes, 'report'),
      throwsA(isA<FileSystemException>()),
    );
    expect(await File(documents).readAsString(), 'existing documents');
  });
}
