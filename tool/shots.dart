// Harness de captura de screenshots REAIS do app para a landing page.
// Renderiza cada tela com os widgets verdadeiros (tema v1.20.0) e exporta
// PNGs via RepaintBoundary.toImage. Dados de demonstração ficam SÓ em memória
// (SharedPreferences mock) — nada é gravado no storage real do usuário.
// Uso: flutter run -d macos -t tool/shots.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'package:dry_eye_widget/l10n/app_strings.dart';
import 'package:dry_eye_widget/models/app_state.dart';
import 'package:dry_eye_widget/models/dvrs_assessment.dart';
import 'package:dry_eye_widget/services/dvrs_engine.dart';
import 'package:dry_eye_widget/services/dvrs_storage_service.dart';
import 'package:dry_eye_widget/services/screen_time_service.dart';
import 'package:dry_eye_widget/services/storage_service.dart';
import 'package:dry_eye_widget/ui/app_theme.dart';
import 'package:dry_eye_widget/widgets/dashboard/dashboard_screen.dart';
import 'package:dry_eye_widget/widgets/dvrs/dvrs_result_view.dart';
import 'package:dry_eye_widget/widgets/floating_menu.dart';
import 'package:dry_eye_widget/widgets/gentle_break_card.dart';

final GlobalKey _shotKey = GlobalKey();

DvrsResult _dvrs(List<int> vals, DateTime when, String id) {
  DvrsDomain dom(int i) => i < 6
      ? DvrsDomain.symptoms
      : i < 9
      ? DvrsDomain.functional
      : i < 12
      ? DvrsDomain.exposure
      : i < 15
      ? DvrsDomain.environment
      : DvrsDomain.warning;
  final answers = [
    for (var i = 0; i < 16; i++)
      DvrsAnswer(
        questionId: 'q${i + 1}',
        domain: dom(i),
        value: vals[i],
        label: '',
      ),
  ];
  return evaluateDvrs(answers: answers, id: id, now: when);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Storage em memória: NÃO toca nos dados reais do app.
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({});
  await windowManager.ensureInitialized();

  final storage = await StorageService.init();
  final dvrsStorage = await DvrsStorageService.init();
  final now = DateTime(2026, 7, 5, 10);

  // Semeia demonstração: 4 DVRS (tendência de melhora), tela 7d, pausas 7d.
  await dvrsStorage.saveDvrsResult(
    _dvrs(
      const [3, 3, 3, 3, 2, 3, 3, 3, 2, 3, 3, 3, 2, 2, 2, 2],
      now.subtract(const Duration(days: 21)),
      'a',
    ),
  );
  await dvrsStorage.saveDvrsResult(
    _dvrs(
      const [3, 2, 3, 2, 2, 3, 2, 3, 2, 3, 3, 2, 2, 2, 1, 2],
      now.subtract(const Duration(days: 14)),
      'b',
    ),
  );
  await dvrsStorage.saveDvrsResult(
    _dvrs(
      const [3, 2, 2, 3, 1, 2, 2, 2, 2, 3, 3, 2, 2, 2, 1, 2],
      now.subtract(const Duration(days: 7)),
      'c',
    ),
  );
  await dvrsStorage.saveDvrsResult(
    _dvrs(const [2, 2, 2, 2, 1, 2, 2, 1, 1, 3, 2, 1, 2, 1, 1, 1], now, 'd'),
  );

  var screen = storage.loadScreenTime();
  const secs = [21600, 19800, 25200, 16200, 23400, 12600, 15000];
  for (var i = 0; i < 7; i++) {
    final day = now.subtract(Duration(days: 6 - i));
    screen = screen.addSeconds(day, secs[i]);
  }
  await storage.saveScreenTime(screen);

  var breaks = storage.loadBreakStats();
  const rem = [12, 12, 14, 10, 12, 8, 9];
  const done = [10, 11, 12, 8, 10, 7, 8];
  for (var i = 0; i < 7; i++) {
    final day = now.subtract(Duration(days: 6 - i));
    breaks = breaks.incremented(day, reminders: rem[i], completed: done[i]);
  }
  await storage.saveBreakStats(breaks);

  await windowManager.waitUntilReadyToShow(
    const WindowOptions(size: Size(780, 940)),
    () async {
      await windowManager.setSize(const Size(780, 940));
      await windowManager.show();
    },
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storage),
        Provider<DvrsStorageService>.value(value: dvrsStorage),
        ChangeNotifierProvider<ScreenTimeService>(
          create: (_) => ScreenTimeService(storage: storage),
        ),
      ],
      child: const _ShotApp(),
    ),
  );
}

class _ShotSpec {
  const _ShotSpec(
    this.name,
    this.width,
    this.height,
    this.builder,
  );
  final String name;
  final double width;
  final double height;
  final WidgetBuilder builder;
  final int settleMs = 1400;
}

class _ShotApp extends StatefulWidget {
  const _ShotApp();
  @override
  State<_ShotApp> createState() => _ShotAppState();
}

class _ShotAppState extends State<_ShotApp> {
  int _index = 0;
  late final List<_ShotSpec> _specs;

  @override
  void initState() {
    super.initState();
    _specs = [
      _ShotSpec('dvrs', 720, 860, (context) {
        final latest = context
            .read<DvrsStorageService>()
            .getLatestDvrsResult()!;
        return _panel(
          title: 'Índice de Risco Visual Digital — DVRS',
          child: ListView(
            padding: const EdgeInsets.all(22),
            physics: const NeverScrollableScrollPhysics(),
            children: [DvrsResultView(result: latest, showDate: true)],
          ),
        );
      }),
      _ShotSpec('dashboard', 720, 860, (context) {
        return _frame(DashboardScreen(onClose: () {}));
      }),
      _ShotSpec('break-card', 520, 240, (context) {
        return Material(
          type: MaterialType.transparency,
          child: Center(
            child: SizedBox(
              width: 460,
              child: GentleBreakCard(
                state: AppState.fase1,
                strings: ptStrings,
                secondsRemaining: 14,
                totalSeconds: 20,
              ),
            ),
          ),
        );
      }),
      _ShotSpec('ball-menu', 380, 820, (context) {
        return Material(
          type: MaterialType.transparency,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF4A90E2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4A90E2).withValues(alpha: 0.55),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                FloatingMenu(
                  strings: ptStrings,
                  isPaused: false,
                  onStartNow: () {},
                  onReset: () {},
                  onTogglePause: () {},
                  onGuidance: () {},
                  onDvrs: () {},
                  onScreenTime: () {},
                  onDashboard: () {},
                  onProgress: () {},
                  onReports: () {},
                  onCheckUpdates: () {},
                  onAbout: () {},
                  onSettings: () {},
                  onQuit: () {},
                  onDismiss: () {},
                ),
              ],
            ),
          ),
        );
      }),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    final dir = await getTemporaryDirectory();
    await dir.create(recursive: true);
    for (var i = 0; i < _specs.length; i++) {
      setState(() => _index = i);
      await Future<void>.delayed(Duration(milliseconds: _specs[i].settleMs));
      try {
        final boundary =
            _shotKey.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2.0);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final out = '${dir.path}/shot_${_specs[i].name}.png';
        await File(out).writeAsBytes(bytes!.buffer.asUint8List());
        stdout.writeln('SHOT_SAVED:$out');
      } catch (e) {
        stdout.writeln('SHOT_ERROR:${_specs[i].name}:$e');
      }
    }
    stdout.writeln('SHOTS_DONE');
    await Future<void>.delayed(const Duration(milliseconds: 200));
    exit(0);
  }

  /// Painel com header (estilo das telas do app) sobre fundo claro.
  Widget _panel({required String title, required Widget child}) {
    final theme = Theme.of(context);
    return _frame(
      Column(
        children: [
          Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.5),
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.arrow_back),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  /// Moldura arredondada com fundo surface (como as janelas reais).
  Widget _frame(Widget child) => Padding(
    padding: const EdgeInsets.all(26),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Material(color: const Color(0xFF1D2733), child: child),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final spec = _specs[_index];
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: Center(
        child: RepaintBoundary(
          key: _shotKey,
          child: Container(
            width: spec.width,
            height: spec.height,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF143C73), Color(0xFF0B1B30)],
              ),
            ),
            child: Builder(builder: spec.builder),
          ),
        ),
      ),
    );
  }
}
