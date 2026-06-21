import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../utils/constants.dart';
import 'liquid_glass.dart';

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
    required this.strings,
    required this.isPaused,
    required this.onStartNow,
    required this.onReset,
    required this.onTogglePause,
    required this.onGuidance,
    required this.onOsdi,
    required this.onScreenTime,
    required this.onChecklists,
    required this.onReports,
    required this.onCheckUpdates,
    required this.onGitHub,
    required this.onAbout,
    required this.onSettings,
    required this.onQuit,
    required this.onDismiss,
  });

  final AppStrings strings;
  final bool isPaused;
  final VoidCallback onStartNow;
  final VoidCallback onReset;
  final VoidCallback onTogglePause;
  final VoidCallback onGuidance;
  final VoidCallback onOsdi;
  final VoidCallback onScreenTime;
  final VoidCallback onChecklists;
  final VoidCallback onReports;
  final VoidCallback onCheckUpdates;
  final VoidCallback onGitHub;
  final VoidCallback onAbout;
  final VoidCallback onSettings;
  final VoidCallback onQuit;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final s = strings;
    final items = <_MenuItem>[
      _MenuItem(Icons.play_circle_outline, s.menuStartBreak, onStartNow),
      _MenuItem(Icons.refresh, s.menuReset, onReset),
      _MenuItem(
        isPaused ? Icons.play_arrow : Icons.pause,
        isPaused ? s.menuResume : s.menuPause,
        onTogglePause,
      ),
      _MenuItem(Icons.menu_book_outlined, s.menuGuidance, onGuidance),
      _MenuItem(Icons.assignment_outlined, s.menuOsdi, onOsdi),
      _MenuItem(Icons.bar_chart_outlined, s.menuScreenTime, onScreenTime),
      _MenuItem(Icons.checklist_outlined, 'Checklists', onChecklists),
      _MenuItem(Icons.picture_as_pdf_outlined, 'Relatórios', onReports),
      _MenuItem(Icons.system_update_alt, s.menuCheckUpdates, onCheckUpdates),
      _MenuItem(Icons.code, s.menuGitHub, onGitHub),
      _MenuItem(Icons.info_outline, s.menuAbout, onAbout),
      _MenuItem(Icons.settings_outlined, s.menuSettings, onSettings),
      _MenuItem(Icons.close, s.menuQuit, onQuit),
    ];

    return LiquidGlass(
      width: 280,
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(vertical: 6),
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
    );
  }
}

class _MenuRow extends StatefulWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          // Pequeno "deslize" para a direita ao passar o mouse.
          padding: EdgeInsets.only(
            left: _hover ? 18 : 14,
            right: 14,
            top: 11,
            bottom: 11,
          ),
          decoration: BoxDecoration(
            // Realce em gradiente translúcido no hover.
            gradient: _hover
                ? LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.14),
                      Colors.white.withValues(alpha: 0.04),
                    ],
                  )
                : null,
            // Barra de destaque à esquerda.
            border: Border(
              left: BorderSide(
                color: _hover ? AppColors.idleBall : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              AnimatedScale(
                scale: _hover ? 1.12 : 1.0,
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                child: Icon(
                  widget.icon,
                  size: 18,
                  color: _hover ? AppColors.idleBall : AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: _hover ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
