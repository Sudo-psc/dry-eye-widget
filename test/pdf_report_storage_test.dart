import 'dart:io';
import 'dart:typed_data';

import 'package:dry_eye_widget/services/pdf_report_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final service = PdfReportService();
  final bytes = Uint8List.fromList([37, 80, 68, 70, 45, 49, 46, 55]);
  late Directory root;
  late PathProviderPlatform originalPaths;
  late _FakePathProvider paths;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('pdf_report_storage_test_');
    originalPaths = PathProviderPlatform.instance;
    paths = _FakePathProvider(
      downloads: '${root.path}/Downloads',
      documents: '${root.path}/Documents',
    );
    // Substitui a interface comum, sem depender das restrições de SO do
    // MethodChannelPathProvider ou dos plugins nativos registrados.
    PathProviderPlatform.instance = paths;
  });

  tearDown(() async {
    PathProviderPlatform.instance = originalPaths;
    await root.delete(recursive: true);
  });

  test('salva todos os bytes em Downloads sem consultar Documentos', () async {
    final file = await service.savePdfToDevice(bytes, 'report');

    expect(file.path, '${paths.downloads}/report.pdf');
    expect(await file.readAsBytes(), bytes);
    expect(paths.downloadsLookups, 1);
    expect(paths.documentsLookups, 0);
  });

  test(
    'usa Documentos quando o caminho Downloads não permite gravar',
    () async {
      // Um arquivo no lugar da pasta gera falha real de I/O em qualquer SO,
      // sem depender de chmod ou do usuário que executa os testes.
      await File(paths.downloads!).writeAsString('existing file');

      final file = await service.savePdfToDevice(bytes, 'report');

      expect(file.path, '${paths.documents}/report.pdf');
      expect(await file.readAsBytes(), bytes);
      expect(await File(paths.downloads!).readAsString(), 'existing file');
    },
  );

  test('usa Documentos quando Downloads não está disponível', () async {
    paths.downloads = null;

    final file = await service.savePdfToDevice(bytes, 'report');

    expect(file.path, '${paths.documents}/report.pdf');
    expect(await file.readAsBytes(), bytes);
  });

  test('usa Documentos quando a consulta de Downloads falha', () async {
    paths.failDownloadsLookup = true;

    final file = await service.savePdfToDevice(bytes, 'report');

    expect(file.path, '${paths.documents}/report.pdf');
    expect(await file.readAsBytes(), bytes);
  });

  test('propaga falha se nenhum destino aceitar a gravação', () async {
    await File(paths.downloads!).writeAsString('existing downloads');
    await File(paths.documents).writeAsString('existing documents');

    await expectLater(
      service.savePdfToDevice(bytes, 'report'),
      throwsA(isA<FileSystemException>()),
    );
    expect(await File(paths.documents).readAsString(), 'existing documents');
  });
}

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider({required this.downloads, required this.documents});

  String? downloads;
  final String documents;
  bool failDownloadsLookup = false;
  int downloadsLookups = 0;
  int documentsLookups = 0;

  @override
  Future<String?> getDownloadsPath() async {
    downloadsLookups++;
    if (failDownloadsLookup) throw UnsupportedError('Downloads unavailable');
    return downloads;
  }

  @override
  Future<String?> getApplicationDocumentsPath() async {
    documentsLookups++;
    return documents;
  }
}
