import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/widget_settings.dart';
import '../../ui/app_theme.dart';
import '../../utils/constants.dart';
import '../liquid_glass.dart';

/// Fluxo de boas-vindas exibido na primeira execução do app.
///
/// Apresenta o propósito (saúde ocular digital), a regra 20-20-20, como a
/// bolinha flutuante funciona e a postura de privacidade. Ao concluir (ou
/// pular), entrega o rascunho uma única vez a [onFinish].
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({
    super.key,
    required this.strings,
    required this.onFinish,
    this.initial,
  });

  final AppStrings strings;
  final Future<void> Function(WidgetSettings settings) onFinish;
  final WidgetSettings? initial;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final _controller = PageController();
  int _index = 0;
  late WidgetSettings _draft;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _draft = widget.initial ?? WidgetSettings.defaults();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _update(WidgetSettings next) {
    setState(() => _draft = next);
  }

  void _next(int lastIndex) {
    if (_index >= lastIndex) {
      unawaited(_finish());
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    try {
      await widget.onFinish(_draft);
    } finally {
      if (mounted) setState(() => _finishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    const count = 3;
    const lastIndex = count - 1;
    final isLast = _index == lastIndex;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: LiquidGlass(
          fillOpacity: 0.85,
          blur: 24,
          // Preenche a janela: o Stack interno do LiquidGlass afrouxa as
          // constraints, então sem isto o Column (com PageView/footer) colapsa.
          constraints: const BoxConstraints.expand(),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: count,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) => _stepView(i, s),
                ),
              ),
              _footer(s, count, lastIndex, isLast),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepView(int index, AppStrings s) => switch (index) {
    0 => _cycleStep(s),
    1 => _appearanceStep(s),
    _ => _privacyStep(s),
  };

  Widget _stepShell({
    required IconData icon,
    required Color color,
    required String title,
    required String body,
    required Widget controls,
  }) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(36, 28, 36, 8),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 36),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 38),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                body,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 18),
              controls,
            ],
          ),
        ),
      ),
    );
  }

  Widget _cycleStep(AppStrings s) => _stepShell(
    icon: Icons.timer_outlined,
    color: AppColors.idleBall,
    title: s.onboardingStep1Title,
    body: s.onboardingStep2Body,
    controls: Column(
      children: [
        _sliderLabel(s.workCycle, '${_draft.cycleMinutes} ${s.unitMin}'),
        Slider(
          key: const ValueKey('onboarding-cycle-slider'),
          value: _draft.cycleMinutes.toDouble(),
          min: 5,
          max: 60,
          divisions: 11,
          onChanged: (value) =>
              _update(_draft.copyWith(cycleMinutes: value.round())),
        ),
      ],
    ),
  );

  Widget _appearanceStep(AppStrings s) => _stepShell(
    icon: Icons.touch_app_outlined,
    color: const Color(0xFFFF8C00),
    title: s.onboardingStep3Title,
    body: s.onboardingStep3Body,
    controls: Column(
      children: [
        AnimatedContainer(
          key: const ValueKey('onboarding-ball-preview'),
          duration: MediaQuery.maybeOf(context)?.disableAnimations == true
              ? Duration.zero
              : AppMotion.normal,
          width: _draft.ballSize.clamp(32, 88),
          height: _draft.ballSize.clamp(32, 88),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _draft.idleColorValue.withValues(alpha: _draft.idleOpacity),
            border: Border.all(color: _draft.idleColorValue, width: 3),
            boxShadow: [
              BoxShadow(
                color: _draft.idleColorValue.withValues(alpha: 0.3),
                blurRadius: 16,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _sliderLabel(s.ballSize, '${_draft.ballSize.round()} px'),
        Slider(
          key: const ValueKey('onboarding-size-slider'),
          value: _draft.ballSize,
          min: AppDefaults.minBallSize,
          max: AppDefaults.maxBallSize,
          onChanged: (value) => _update(_draft.copyWith(ballSize: value)),
        ),
      ],
    ),
  );

  Widget _privacyStep(AppStrings s) => _stepShell(
    icon: Icons.shield_outlined,
    color: const Color(0xFF1ABC9C),
    title: s.onboardingStep5Title,
    body: s.onboardingStep5Body,
    controls: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1ABC9C).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF1ABC9C).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_none_rounded, size: 21),
          const SizedBox(width: 10),
          Expanded(child: Text(s.enableNotifications)),
          Switch(
            key: const ValueKey('onboarding-notifications-switch'),
            value: _draft.notificationsEnabled,
            onChanged: (value) =>
                _update(_draft.copyWith(notificationsEnabled: value)),
          ),
        ],
      ),
    ),
  );

  Widget _sliderLabel(String label, String value) => Row(
    children: [
      Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
      Text(
        value,
        style: const TextStyle(
          color: AppColors.idleBall,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );

  Widget _footer(AppStrings s, int count, int lastIndex, bool isLast) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        children: [
          TextButton(
            onPressed: _finishing ? null : _finish,
            child: Text(
              s.onboardingSkip,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(count, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 18 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.idleBall
                        : theme.colorScheme.onSurface.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
          FilledButton(
            onPressed: _finishing ? null : () => _next(lastIndex),
            child: Text(isLast ? s.onboardingStart : s.onboardingNext),
          ),
        ],
      ),
    );
  }
}
