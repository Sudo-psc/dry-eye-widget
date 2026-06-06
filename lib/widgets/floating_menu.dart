import 'dart:ui';

import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// Item do menu flutuante.
class _MenuItem {
  const _MenuItem(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

/// Menu flutuante exibido ao clicar na bolinha (apenas no estado IDLE).
class FloatingMenu extends StatelessWidget {
  const FloatingMenu({
    super.key,
    required this.isPaused,
    required this.onStartNow,
    required this.onReset,
    required this.onTogglePause,
    required this.onSettings,
    required this.onQuit,
    required this.onDismiss,
  });

  final bool isPaused;
  final VoidCallback onStartNow;
  final VoidCallback onReset;
  final VoidCallback onTogglePause;
  final VoidCallback onSettings;
  final VoidCallback onQuit;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final items = <_MenuItem>[
      _MenuItem(Icons.play_circle_outline, 'Iniciar pausa agora', onStartNow),
      _MenuItem(Icons.refresh, 'Resetar cronômetro', onReset),
      _MenuItem(
        isPaused ? Icons.play_arrow : Icons.pause,
        isPaused ? 'Retomar cronômetro' : 'Pausar cronômetro',
        onTogglePause,
      ),
      _MenuItem(Icons.settings_outlined, 'Configurações', onSettings),
      _MenuItem(Icons.close, 'Sair', onQuit),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: 230,
          decoration: BoxDecoration(
            color: const Color(0xCC1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.glassBorder, width: 1),
            boxShadow: const [
              BoxShadow(color: AppColors.glassShadow, blurRadius: 16),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in items)
                _MenuRow(
                  icon: item.icon,
                  label: item.label,
                  onTap: () {
                    item.onTap();
                    onDismiss();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatefulWidget {
  const _MenuRow({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_MenuRow> createState() => _MenuRowState();
}

class _MenuRowState extends State<_MenuRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color:
              _hover ? Colors.white.withValues(alpha: 0.08) : Colors.transparent,
          child: Row(
            children: [
              Icon(widget.icon, size: 18, color: AppColors.textPrimary),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
