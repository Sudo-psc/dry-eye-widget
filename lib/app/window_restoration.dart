import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import '../models/app_state.dart';
import '../services/storage_service.dart';
import '../utils/edge_snap.dart';
import 'window_layout.dart';

typedef DisplayRectsLoader = Future<List<Rect>> Function();
typedef PrimaryDisplayRectLoader = Future<Rect> Function();
typedef WindowPositionWriter = Future<void> Function(Offset position);
typedef BallPositionWriter = Future<void> Function(double x, double y);

/// Restaura a bolinha em uma tela conectada e persiste qualquer correção.
///
/// A coordenação fica fora do shell principal e recebe suas fronteiras por
/// injeção, para que falhas de monitor, posição e persistência sejam testáveis
/// sem subir uma janela nativa.
class BallPositionRestorer {
  const BallPositionRestorer({
    required this.loadDisplays,
    required this.loadPrimaryDisplay,
    required this.setWindowPosition,
    required this.saveBallPosition,
  });

  factory BallPositionRestorer.desktop(StorageService storage) {
    return BallPositionRestorer(
      loadDisplays: () async {
        final displays = await screenRetriever.getAllDisplays();
        return displays
            .map(
              (display) =>
                  (display.visiblePosition ?? Offset.zero) &
                  (display.visibleSize ?? display.size),
            )
            .toList(growable: false);
      },
      loadPrimaryDisplay: () async {
        final display = await screenRetriever.getPrimaryDisplay();
        return (display.visiblePosition ?? Offset.zero) &
            (display.visibleSize ?? display.size);
      },
      setWindowPosition: windowManager.setPosition,
      saveBallPosition: storage.saveBallPosition,
    );
  }

  final DisplayRectsLoader loadDisplays;
  final PrimaryDisplayRectLoader loadPrimaryDisplay;
  final WindowPositionWriter setWindowPosition;
  final BallPositionWriter saveBallPosition;

  Future<void> restore({
    required double? savedX,
    required double? savedY,
    required BallCorner defaultCorner,
    required Size windowSize,
    required BallDockEdge? dockEdge,
  }) async {
    if (savedX != null && savedY != null) {
      final saved = Offset(savedX, savedY);
      // Encaixada na borda, a bolinha fica parcialmente fora da tela por
      // design (meia-lua). Recortá-la para dentro a desencaixaria, e regravar
      // o resultado apagaria a posição salva — por isso o encaixe é
      // recalculado contra os monitores atuais e nunca persistido.
      if (dockEdge != null) {
        await setWindowPosition(
          await _dockedPosition(saved, windowSize, dockEdge),
        );
        return;
      }
      final visible = await _visiblePosition(saved, windowSize);
      await setWindowPosition(visible);
      if (visible != saved) {
        await saveBallPosition(visible.dx, visible.dy);
      }
      return;
    }

    await setWindowPosition(await _cornerOffset(defaultCorner, windowSize));
  }

  /// Recoloca a bolinha encaixada na tela conectada mais próxima da posição
  /// salva, preservando o Y. Se o monitor de origem sumiu, ela reencaixa em um
  /// monitor existente em vez de reaparecer fora da área visível.
  Future<Offset> _dockedPosition(
    Offset position,
    Size windowSize,
    BallDockEdge edge,
  ) async {
    try {
      final screens = (await loadDisplays())
          .where((screen) => screen.width > 0 && screen.height > 0)
          .toList(growable: false);
      if (screens.isEmpty) return position;
      return dockedWindowPosition(
        edge: edge,
        windowPos: position,
        windowSize: windowSize,
        screen: closestScreenForWindow(
          windowPosition: position,
          windowSize: windowSize,
          screens: screens,
        ),
      );
    } catch (error) {
      debugPrint('Não foi possível validar o encaixe salvo: $error');
      return position;
    }
  }

  Future<Offset> _visiblePosition(Offset position, Size windowSize) async {
    try {
      return resolveRestoredPosition(
            savedPosition: position,
            windowSize: windowSize,
            screens: await loadDisplays(),
          ) ??
          position;
    } catch (error) {
      debugPrint('Não foi possível validar a posição salva: $error');
      return position;
    }
  }

  Future<Offset> _cornerOffset(BallCorner corner, Size windowSize) async {
    const margin = 24.0;
    try {
      final screen = await loadPrimaryDisplay();
      final maxX = screen.right - windowSize.width - margin;
      final maxY = screen.bottom - windowSize.height - margin;
      return switch (corner) {
        BallCorner.topLeft => screen.topLeft + const Offset(margin, margin),
        BallCorner.topRight => Offset(maxX, screen.top + margin),
        BallCorner.bottomLeft => Offset(screen.left + margin, maxY),
        BallCorner.bottomRight => Offset(maxX, maxY),
        BallCorner.center => Offset(
          screen.left + (screen.width - windowSize.width) / 2,
          screen.top + (screen.height - windowSize.height) / 2,
        ),
      };
    } catch (error) {
      debugPrint('Não foi possível consultar a tela primária: $error');
      return const Offset(100, 100);
    }
  }
}
