import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../utils/constants.dart';
import '../liquid_glass.dart';

/// Passo único do onboarding (ícone + título + corpo).
class _OnboardingStep {
  const _OnboardingStep(this.icon, this.color, this.title, this.body);
  final IconData icon;
  final Color color;
  final String title;
  final String body;
}

/// Fluxo de boas-vindas exibido na primeira execução do app.
///
/// Apresenta o propósito (saúde ocular digital), a regra 20-20-20, como a
/// bolinha flutuante funciona e a postura de privacidade. Ao concluir (ou
/// pular), chama [onFinish], que persiste `onboardingComplete = true`.
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({
    super.key,
    required this.strings,
    required this.onFinish,
  });

  final AppStrings strings;
  final VoidCallback onFinish;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_OnboardingStep> _steps(AppStrings s) => [
    _OnboardingStep(
      Icons.remove_red_eye_outlined,
      AppColors.idleBall,
      s.onboardingStep1Title,
      s.onboardingStep1Body,
    ),
    _OnboardingStep(
      Icons.timer_outlined,
      const Color(0xFF50C878),
      s.onboardingStep2Title,
      s.onboardingStep2Body,
    ),
    _OnboardingStep(
      Icons.touch_app_outlined,
      const Color(0xFFFF8C00),
      s.onboardingStep3Title,
      s.onboardingStep3Body,
    ),
    _OnboardingStep(
      Icons.lock_outline,
      const Color(0xFF9B59B6),
      s.onboardingStep4Title,
      s.onboardingStep4Body,
    ),
  ];

  void _next(int lastIndex) {
    if (_index >= lastIndex) {
      widget.onFinish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final steps = _steps(s);
    final lastIndex = steps.length - 1;
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
                  itemCount: steps.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) => _stepView(steps[i]),
                ),
              ),
              _footer(s, steps.length, lastIndex, isLast),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepView(_OnboardingStep step) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 40, 36, 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: step.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(step.icon, color: step.color, size: 48),
          ),
          const SizedBox(height: 28),
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          Text(
            step.body,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer(AppStrings s, int count, int lastIndex, bool isLast) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        children: [
          TextButton(
            onPressed: widget.onFinish,
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
            onPressed: () => _next(lastIndex),
            child: Text(isLast ? s.onboardingStart : s.onboardingNext),
          ),
        ],
      ),
    );
  }
}
