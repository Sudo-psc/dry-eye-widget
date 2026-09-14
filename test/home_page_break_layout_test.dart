import 'package:dry_eye_widget/app/window_layout.dart';
import 'package:dry_eye_widget/main.dart';
import 'package:dry_eye_widget/models/app_state.dart';
import 'package:dry_eye_widget/providers/settings_provider.dart';
import 'package:dry_eye_widget/providers/timer_provider.dart';
import 'package:dry_eye_widget/services/audio_service.dart';
import 'package:dry_eye_widget/services/dock_icon_service.dart';
import 'package:dry_eye_widget/services/dvrs_storage_service.dart';
import 'package:dry_eye_widget/services/notification_service.dart';
import 'package:dry_eye_widget/services/presence/adaptive_threshold_model.dart';
import 'package:dry_eye_widget/services/presence/presence_controller.dart';
import 'package:dry_eye_widget/services/storage_service.dart';
import 'package:dry_eye_widget/services/tray_service.dart';
import 'package:dry_eye_widget/utils/constants.dart';
import 'package:dry_eye_widget/widgets/dvrs/dvrs_screen.dart';
import 'package:dry_eye_widget/widgets/gentle_break_card.dart';
import 'package:dry_eye_widget/widgets/glass_overlay.dart';
import 'package:dry_eye_widget/widgets/onboarding/onboarding_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tray_manager/tray_manager.dart';

class _SilentAudio implements AudioService {
  @override
  bool enabled = false;

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class _SilentNotifications implements NotificationService {
  @override
  bool enabled = false;

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class _HomeHarness {
  _HomeHarness(this.tester, this.timer, this.settings, this.windowCalls);

  final WidgetTester tester;
  final TimerProvider timer;
  final SettingsProvider settings;
  final List<MethodCall> windowCalls;

  Future<void> dispose() async {
    await tester.pumpWidget(const SizedBox.shrink());
    timer.dispose();
    settings.dispose();
    await tester.pump();
  }

  void openDvrs() {
    final home = tester.state(find.byType(HomePage)) as TrayListener;
    home.onTrayMenuItemClick(MenuItem(key: TrayService.keyDvrs));
  }

  List<Size> get requestedSizes => [
    for (final call in windowCalls)
      if ((call.method == 'setBounds' || call.method == 'setSize') &&
          call.arguments is Map &&
          (call.arguments as Map).containsKey('width'))
        Size(
          ((call.arguments as Map)['width'] as num).toDouble(),
          ((call.arguments as Map)['height'] as num).toDouble(),
        ),
  ];

  void expectOnlySize(Size size) {
    expect(requestedSizes, isNotEmpty);
    expect(requestedSizes, everyElement(size));
  }
}

const _displaySize = Size(1280, 960);

Future<_HomeHarness> _pumpHome(
  WidgetTester tester, {
  bool gentleMode = false,
  bool onboardingComplete = true,
}) async {
  tester.view.physicalSize = const Size(1280, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final calls = <MethodCall>[];
  var bounds = const Rect.fromLTWH(100, 100, 88, 88);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const windowChannel = MethodChannel('window_manager');
  const screenChannel = MethodChannel(
    'dev.leanflutter.plugins/screen_retriever',
  );
  const displayChannel = MethodChannel('dry_eye_widget/display');
  messenger.setMockMethodCallHandler(windowChannel, (call) async {
    calls.add(call);
    if (call.method == 'isMinimized') return false;
    if (call.method == 'getPosition') {
      return {'x': bounds.left, 'y': bounds.top};
    }
    if (call.method == 'getBounds') {
      return {
        'x': bounds.left,
        'y': bounds.top,
        'width': bounds.width,
        'height': bounds.height,
      };
    }
    if (call.method == 'setBounds') {
      final values = call.arguments as Map;
      bounds = Rect.fromLTWH(
        (values['x'] as num?)?.toDouble() ?? bounds.left,
        (values['y'] as num?)?.toDouble() ?? bounds.top,
        (values['width'] as num?)?.toDouble() ?? bounds.width,
        (values['height'] as num?)?.toDouble() ?? bounds.height,
      );
    }
    return null;
  });
  messenger.setMockMethodCallHandler(screenChannel, (call) async {
    final display = {
      'id': '1',
      'name': 'Test display',
      'size': {'width': 1280.0, 'height': 1000.0},
      'visibleSize': {
        'width': _displaySize.width,
        'height': _displaySize.height,
      },
      'visiblePosition': {'dx': 0.0, 'dy': 0.0},
      'scaleFactor': 1.0,
    };
    return switch (call.method) {
      'getPrimaryDisplay' => display,
      'getAllDisplays' => {
        'displays': [display],
      },
      'getCursorScreenPoint' => {'dx': 100.0, 'dy': 100.0},
      _ => null,
    };
  });
  messenger.setMockMethodCallHandler(displayChannel, (_) async => false);
  addTearDown(() {
    messenger.setMockMethodCallHandler(windowChannel, null);
    messenger.setMockMethodCallHandler(screenChannel, null);
    messenger.setMockMethodCallHandler(displayChannel, null);
  });

  SharedPreferences.setMockInitialValues({});
  final storage = await StorageService.init();
  final dvrs = await DvrsStorageService.init();
  final settings = SettingsProvider(storage: storage);
  await settings.update(
    settings.value.copyWith(
      languageCode: 'pt',
      onboardingComplete: onboardingComplete,
      soundEnabled: false,
      notificationsEnabled: false,
      gentleMode: gentleMode,
      lockScreenOnBreak: false,
      phaseSeconds: 5,
    ),
  );
  final audio = _SilentAudio();
  final notifications = _SilentNotifications();
  final timer = TimerProvider(
    settings: settings,
    storage: storage,
    audio: audio,
    notifications: notifications,
    presence: PresenceController(
      model: AdaptiveThresholdModel(),
      idleSource: () async => 0,
    ),
  );
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storage),
        Provider<DvrsStorageService>.value(value: dvrs),
        Provider<AudioService>.value(value: audio),
        Provider<NotificationService>.value(value: notifications),
        Provider<TrayService>.value(value: TrayService()),
        Provider<DockIconService>.value(value: const DockIconService()),
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ChangeNotifierProvider<TimerProvider>.value(value: timer),
      ],
      child: const DryEyeApp(),
    ),
  );
  await tester.pump();
  return _HomeHarness(tester, timer, settings, calls);
}

void _testHome(
  String description,
  Future<void> Function(WidgetTester tester, _HomeHarness home) body, {
  bool gentleMode = false,
  bool onboardingComplete = true,
}) {
  testWidgets(description, (tester) async {
    final home = await _pumpHome(
      tester,
      gentleMode: gentleMode,
      onboardingComplete: onboardingComplete,
    );
    try {
      await body(tester, home);
    } finally {
      // Dispose timers before Flutter verifies pending timers at body return.
      await home.dispose();
    }
  });
}

Future<void> _answerFirstQuestion(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 400));
  await tester.tap(find.text('Iniciar DVRS'));
  await tester.pump(const Duration(milliseconds: 400));
  await tester.tap(
    find.descendant(
      of: find.byKey(const ValueKey<String>('dvrs_question_q1')),
      matching: find.text('Nunca'),
    ),
  );
  await tester.pump();
  expect(find.text('1 de 16 respondidas'), findsOneWidget);
}

void _expectBreakSurface({required bool gentleMode}) {
  expect(
    find.byType(GentleBreakCard),
    gentleMode ? findsOneWidget : findsNothing,
  );
  expect(find.byType(GlassOverlay), gentleMode ? findsNothing : findsOneWidget);
  expect(find.byType(DvrsScreen), findsNothing);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final gentleMode in [false, true]) {
    final mode = gentleMode ? 'suave' : 'tela cheia';
    final breakSize = gentleMode ? WindowSizes.gentleBreak : _displaySize;

    _testHome(
      'pausa $mode preserva DVRS e restaura painel ao reiniciar',
      (tester, home) async {
        home.openDvrs();
        await _answerFirstQuestion(tester);
        final questionState = tester.state(find.byType(DvrsScreen));

        home.windowCalls.clear();
        home.timer.startBreakNow();
        await tester.pump();

        expect(home.timer.state, AppState.alerta);
        _expectBreakSurface(gentleMode: gentleMode);
        expect(
          tester.state(find.byType(DvrsScreen, skipOffstage: false)),
          same(questionState),
        );
        home.expectOnlySize(breakSize);

        home.windowCalls.clear();
        home.timer.reset();
        await tester.pump();

        expect(tester.state(find.byType(DvrsScreen)), same(questionState));
        expect(find.text('1 de 16 respondidas'), findsOneWidget);
        expect(find.byType(GentleBreakCard), findsNothing);
        expect(find.byType(GlassOverlay), findsNothing);
        home.expectOnlySize(WindowSizes.panel);
      },
      gentleMode: gentleMode,
    );

    _testHome(
      'fechar DVRS durante pausa $mode mantém tamanho da pausa',
      (tester, home) async {
        home.openDvrs();
        await tester.pump();
        final closeDvrs = tester
            .widget<DvrsScreen>(find.byType(DvrsScreen))
            .onClose;
        home.timer.startBreakNow();
        await tester.pump();

        home.windowCalls.clear();
        closeDvrs();
        await tester.pump();

        expect(home.timer.state, AppState.alerta);
        _expectBreakSurface(gentleMode: gentleMode);
        expect(find.byType(DvrsScreen, skipOffstage: false), findsNothing);
        home.expectOnlySize(breakSize);
      },
      gentleMode: gentleMode,
    );

    _testHome(
      'abrir DVRS pela bandeja durante pausa $mode mantém a pausa',
      (tester, home) async {
        home.timer.startBreakNow();
        await tester.pump();

        home.windowCalls.clear();
        home.openDvrs();
        await tester.pump();

        _expectBreakSurface(gentleMode: gentleMode);
        expect(find.byType(DvrsScreen, skipOffstage: false), findsOneWidget);
        home.expectOnlySize(breakSize);

        home.windowCalls.clear();
        home.timer.reset();
        await tester.pump();
        expect(find.byType(DvrsScreen), findsOneWidget);
        home.expectOnlySize(WindowSizes.panel);
      },
      gentleMode: gentleMode,
    );
  }

  _testHome('concluir a pausa restaura o questionário com a resposta', (
    tester,
    home,
  ) async {
    home.openDvrs();
    await _answerFirstQuestion(tester);
    final questionState = tester.state(find.byType(DvrsScreen));
    home.timer.start();
    home.timer.startBreakNow();
    await tester.pump(const Duration(milliseconds: 1500));
    expect(home.timer.state, AppState.fase1);
    for (var second = 0; second < home.timer.phaseSeconds; second++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(home.timer.state, AppState.conclusao);
    _expectBreakSurface(gentleMode: false);

    home.windowCalls.clear();
    await tester.pump(AppDurations.completion);

    expect(home.timer.state, AppState.idle);
    expect(tester.state(find.byType(DvrsScreen)), same(questionState));
    expect(find.text('1 de 16 respondidas'), findsOneWidget);
    home.expectOnlySize(WindowSizes.panel);
  });

  _testHome(
    'pausa preserva etapa de onboarding e restaura seu tamanho',
    (tester, home) async {
      await tester.tap(find.text('Próximo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final onboardingState = tester.state(find.byType(OnboardingFlow));
      expect(
        find.byKey(const ValueKey('onboarding-size-slider')),
        findsOneWidget,
      );

      home.timer.startBreakNow();
      await tester.pump();
      expect(find.byType(OnboardingFlow), findsNothing);
      expect(find.byType(GlassOverlay), findsOneWidget);
      expect(
        tester.state(find.byType(OnboardingFlow, skipOffstage: false)),
        same(onboardingState),
      );

      home.windowCalls.clear();
      home.timer.reset();
      await tester.pump();
      expect(tester.state(find.byType(OnboardingFlow)), same(onboardingState));
      expect(
        find.byKey(const ValueKey('onboarding-size-slider')),
        findsOneWidget,
      );
      home.expectOnlySize(WindowSizes.onboarding);
    },
    onboardingComplete: false,
  );
}
