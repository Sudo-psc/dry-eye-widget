import 'dart:async';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../utils/edge_snap.dart';
import 'window_layout.dart';

/// Narrow native-window seam used by the floating orb transitions.
///
/// Keeping this contract limited to geometry makes menu open/close behavior
/// deterministic in tests without pulling the whole application shell into a
/// widget test.
abstract interface class OrbWindowPort {
  Future<void> setSize(Size size);

  Future<void> setPosition(Offset position);
}

/// Production adapter backed by the desktop [windowManager] singleton.
final class WindowManagerOrbWindowPort implements OrbWindowPort {
  const WindowManagerOrbWindowPort();

  @override
  Future<void> setSize(Size size) => windowManager.setSize(size);

  @override
  Future<void> setPosition(Offset position) =>
      windowManager.setPosition(position);
}

/// Resolves the usable screen for a window at [windowPosition].
///
/// The application shell can implement this with `screen_retriever` and
/// `closestScreenForWindow`, while tests can provide a fixed [Rect].
typedef OrbScreenResolver =
    Future<Rect> Function(Offset windowPosition, Size windowSize);

/// Immutable context required to restore the compact orb after closing a menu.
///
/// In particular, [dockEdge] is carried through the transient menu layout. The
/// driver never converts a docked orb into an undocked one as a side effect of
/// opening the menu.
@immutable
final class OrbMenuTransition {
  const OrbMenuTransition({
    required this.anchor,
    required this.compactSize,
    required this.dockEdge,
    required this.placement,
  });

  final CompactWindowAnchor anchor;
  final Size compactSize;
  final BallDockEdge? dockEdge;
  final MenuWindowPlacement placement;
}

/// Serializes native geometry changes for the compact orb and its menu.
///
/// Native window managers can apply size and position asynchronously. A small
/// FIFO queue prevents a fast open/close sequence from interleaving calls and
/// leaving the transparent window at a mixed geometry.
final class OrbWindowTransitionDriver {
  factory OrbWindowTransitionDriver({
    required OrbWindowPort window,
    required OrbScreenResolver resolveScreen,
  }) => OrbWindowTransitionDriver._(window, resolveScreen);

  OrbWindowTransitionDriver._(this._window, this._resolveScreen);

  final OrbWindowPort _window;
  final OrbScreenResolver _resolveScreen;
  Future<void> _tail = Future<void>.value();

  Future<OrbMenuTransition> openMenu({
    required CompactWindowAnchor anchor,
    required Size compactSize,
    required double ballSize,
    required Size menuSize,
    required BallDockEdge? dockEdge,
  }) {
    return _enqueue(() async {
      final screen = await _resolveScreen(anchor.position, compactSize);
      final placement = placeMenuWindow(
        anchor: anchor,
        compactSize: compactSize,
        ballSize: ballSize,
        menuSize: menuSize,
        screen: screen,
      );

      await _window.setSize(menuSize);
      await _window.setPosition(placement.windowPosition);

      return OrbMenuTransition(
        anchor: anchor,
        compactSize: compactSize,
        dockEdge: dockEdge,
        placement: placement,
      );
    });
  }

  /// Restores the compact window and returns its final native position.
  Future<Offset> restoreCompact(OrbMenuTransition transition) {
    return _enqueue(() async {
      final screen = await _resolveScreen(
        transition.anchor.position,
        transition.compactSize,
      );
      final target = switch (transition.dockEdge) {
        final edge? => dockedWindowPosition(
          edge: edge,
          windowPos: transition.anchor.position,
          windowSize: transition.compactSize,
          screen: screen,
        ),
        null => transition.anchor.fitWindow(transition.compactSize, screen),
      };

      await _window.setSize(transition.compactSize);
      await _window.setPosition(target);
      return target;
    });
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final result = _tail.then((_) => operation());
    _tail = result.then<void>((_) {}, onError: (_, _) {});
    return result;
  }
}
