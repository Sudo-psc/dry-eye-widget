import 'dart:ui';

import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// Janela de "Orientações": breve material educativo sobre saúde ocular
/// digital. Conteúdo informativo, em linguagem leiga, sem diagnóstico.
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
          width: 440,
          constraints: const BoxConstraints(maxHeight: 640),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          decoration: BoxDecoration(
            color: const Color(0xE61E1E1E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.glassBorder, width: 1),
            boxShadow: const [
              BoxShadow(color: AppColors.glassShadow, blurRadius: 20),
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
                            'Diante das telas tendemos a piscar bem menos — '
                            'estudos sugerem uma redução de até cerca de dois '
                            'terços na frequência de piscadas. Piscar espalha '
                            'o filme lacrimal que lubrifica e protege os olhos; '
                            'piscando menos, a lágrima evapora mais rápido e '
                            'surge o desconforto do olho seco.',
                      ),
                      _Section(
                        icon: Icons.timer_outlined,
                        title: 'Regra 20-20-20',
                        body:
                            'Uma estratégia simples e recomendada: a cada 20 '
                            'minutos, olhe para algo a cerca de 6 metros (20 '
                            'pés) de distância por 20 segundos. Isso relaxa o '
                            'músculo de foco dos olhos. Aproveite para piscar '
                            'algumas vezes de forma completa, ajudando a '
                            'renovar a lágrima. É exatamente o que este app '
                            'lembra você de fazer.',
                      ),
                      _Section(
                        icon: Icons.trending_down,
                        title: 'Produtividade no trabalho digital',
                        body:
                            'Fadiga visual e olho seco não afetam só o '
                            'conforto: o desconforto ocular está associado à '
                            'queda de concentração e de produtividade entre '
                            'trabalhadores digitais. Pausas regulares ajudam a '
                            'manter os olhos confortáveis e o desempenho ao '
                            'longo do dia.',
                      ),
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
