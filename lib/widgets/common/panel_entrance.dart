import 'package:flutter/material.dart';

import '../../ui/app_theme.dart';

/// Entrada suave de painéis: fade + slide de 8px (200ms).
///
/// Respeita [MediaQuery.disableAnimations] / reduce motion do SO.
class PanelEntrance extends StatefulWidget {
  const PanelEntrance({
    super.key,
    required this.child,
    this.duration = AppMotion.normal,
  });

  final Widget child;
  final Duration duration;

  @override
  State<PanelEntrance> createState() => _PanelEntranceState();
}

class _PanelEntranceState extends State<PanelEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration);
    _fade = CurvedAnimation(parent: _c, curve: AppMotion.standard);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _c, curve: AppMotion.standard));
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.maybeOf(context)?.disableAnimations == true;
    if (reduce) return widget.child;
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}
