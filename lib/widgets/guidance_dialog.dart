import 'dart:ui';

import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// Janela de "Orientações": material educativo sobre saúde ocular digital,
/// com dados estatísticos e referências científicas. Conteúdo informativo,
/// em linguagem leiga, sem diagnóstico.
class GuidanceDialog extends StatelessWidget {
  const GuidanceDialog({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: 460,
          constraints: const BoxConstraints(maxHeight: 660),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xF2323238), Color(0xF21E1E22)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.18), width: 1),
            boxShadow: const [
              BoxShadow(
                color: AppColors.glassShadow,
                blurRadius: 26,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Orientações — Saúde Ocular Digital',
                      style: TextStyle(
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
              const Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Section(
                        icon: Icons.desktop_windows_outlined,
                        title: 'Síndrome da Visão de Computador',
                        body:
                            'O uso prolongado de telas pode causar a Síndrome '
                            'da Visão de Computador (fadiga visual digital): '
                            'cansaço nos olhos, ardência, visão embaçada, dor '
                            'de cabeça e sensação de olhos secos. É frequente '
                            'em quem passa muitas horas no computador, tablet '
                            'ou celular.',
                      ),
                      _Section(
                        icon: Icons.water_drop_outlined,
                        title: 'Olho seco',
                        body:
                            'Diante das telas tendemos a piscar bem menos. '
                            'Piscar espalha o filme lacrimal que lubrifica e '
                            'protege os olhos; piscando menos, a lágrima evapora '
                            'mais rápido e surge o desconforto do olho seco. '
                            'Não é à toa que ele é tão comum entre quem trabalha '
                            'no digital.',
                      ),
                      _Section(
                        icon: Icons.timer_outlined,
                        title: 'Regra 20-20-20',
                        body:
                            'A cada 20 minutos, olhe para algo a cerca de 6 '
                            'metros (20 pés) por 20 segundos — e pisque algumas '
                            'vezes, devagar e completo. Esses 20 segundos '
                            'relaxam o foco e ajudam a renovar a lágrima. É '
                            'exatamente o que este app lembra você de fazer.',
                      ),
                      _Stats(),
                      _References(),
                    ],
                  ),
                ),
              ),
              const Divider(color: AppColors.glassBorder),
              const Text(
                'Conteúdo educativo — não substitui a avaliação de um '
                'oftalmologista. Sintomas persistentes merecem consulta.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
        ),
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
  const _Stats();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_outlined, size: 18, color: AppColors.idleBall),
              SizedBox(width: 8),
              Text(
                'O que dizem os estudos',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          _Stat(
            value: '~50%',
            text: 'dos trabalhadores que usam telas têm olho seco — em alguns '
                'estudos, perto de 60% [1].',
          ),
          _Stat(
            value: '~30%',
            text: 'de queda no desempenho no trabalho (presenteísmo) em quem '
                'tem olho seco sintomático [2].',
          ),
          _Stat(
            value: 'até 14%',
            text: 'mais lenta fica a leitura prolongada por causa do olho '
                'seco [3, 4].',
          ),
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
            width: 64,
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

/// Referências científicas citadas acima.
class _References extends StatelessWidget {
  const _References();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 6, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Referências',
            style: TextStyle(
              color: AppColors.idleBall,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 6),
          _Ref(
            n: '1',
            text: 'Courtin R, et al. BMJ Open. 2016;6(1):e009675. '
                'doi:10.1136/bmjopen-2015-009675',
          ),
          _Ref(
            n: '2',
            text: 'Nichols KK, et al. Invest Ophthalmol Vis Sci. '
                '2016;57(7):2975-82. doi:10.1167/iovs.16-19419',
          ),
          _Ref(
            n: '3',
            text: 'Mathews PM, et al. Br J Ophthalmol. 2016;101(4):481-6. '
                'doi:10.1136/bjophthalmol-2015-308237',
          ),
          _Ref(
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
