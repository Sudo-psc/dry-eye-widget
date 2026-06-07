import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../utils/constants.dart';
import 'liquid_glass.dart';

/// Janela de "Orientações": material educativo sobre saúde ocular digital,
/// com dados estatísticos e referências científicas. Conteúdo informativo,
/// em linguagem leiga, sem diagnóstico. Localizado via [AppStrings].
class GuidanceDialog extends StatelessWidget {
  const GuidanceDialog({super.key, required this.strings, required this.onClose});

  final AppStrings strings;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final s = strings;
    return LiquidGlass(
      width: 460,
      constraints: const BoxConstraints(maxHeight: 660),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  s.guidanceTitle,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textPrimary),
                onPressed: onClose,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Section(
                    icon: Icons.desktop_windows_outlined,
                    title: s.cvsTitle,
                    body: s.cvsBody,
                  ),
                  _Section(
                    icon: Icons.water_drop_outlined,
                    title: s.dryEyeTitle,
                    body: s.dryEyeBody,
                  ),
                  _Section(
                    icon: Icons.timer_outlined,
                    title: s.ruleTitle,
                    body: s.ruleBody,
                  ),
                  _Stats(s),
                  _References(s.refsTitle),
                ],
              ),
            ),
          ),
          const Divider(color: AppColors.glassBorder),
          Text(
            s.disclaimer,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 6),
          const Text(
            'Dr. Philipe Saraiva Cruz — Oftalmologista · RQE 71.903',
            style: TextStyle(
              color: AppColors.idleBall,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.idleBall),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Estatísticas com base na literatura científica (ver Referências).
class _Stats extends StatelessWidget {
  const _Stats(this.s);

  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_outlined,
                  size: 18, color: AppColors.idleBall),
              const SizedBox(width: 8),
              Text(
                s.statsTitle,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _Stat(value: s.stat1Value, text: s.stat1Text),
          _Stat(value: s.stat2Value, text: s.stat2Text),
          _Stat(value: s.stat3Value, text: s.stat3Text),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.text});

  final String value;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.alertBall,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Referências científicas citadas acima (não traduzidas — formato padrão).
class _References extends StatelessWidget {
  const _References(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.idleBall,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          const _Ref(
            n: '1',
            text: 'Courtin R, et al. BMJ Open. 2016;6(1):e009675. '
                'doi:10.1136/bmjopen-2015-009675',
          ),
          const _Ref(
            n: '2',
            text: 'Nichols KK, et al. Invest Ophthalmol Vis Sci. '
                '2016;57(7):2975-82. doi:10.1167/iovs.16-19419',
          ),
          const _Ref(
            n: '3',
            text: 'Mathews PM, et al. Br J Ophthalmol. 2016;101(4):481-6. '
                'doi:10.1136/bjophthalmol-2015-308237',
          ),
          const _Ref(
            n: '4',
            text: 'Karakus S, et al. Optom Vis Sci. 2018;95(12):1105-13. '
                'doi:10.1097/OPX.0000000000001303',
          ),
        ],
      ),
    );
  }
}

class _Ref extends StatelessWidget {
  const _Ref({required this.n, required this.text});

  final String n;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '[$n] $text',
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          height: 1.3,
        ),
      ),
    );
  }
}
