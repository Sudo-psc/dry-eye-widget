import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_strings.dart';
import '../ui/app_theme.dart';
import '../utils/constants.dart';
import 'liquid_glass.dart';

/// Item do menu flutuante.
class _MenuItem {
  const _MenuItem(this.icon, this.label, this.onTap,
      {this.emphasized = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool emphasized;
}

/// Menu flutuante exibido ao clicar na bolinha (apenas no estado IDLE).
class FloatingMenu extends StatelessWidget {
  const FloatingMenu({
    super.key,
    required this.strings,
    required this.healthHubLabel,
    required this.myDataLabel,
    required this.isPaused,
    required this.onStartNow,
    required this.onReset,
    required this.onTogglePause,
    required this.onExtendCycle,
    required this.onGuidance,
    required this.onHealthHub,
    required this.onDvrs,
    required this.onReports,
    required this.onMyData,
    required this.onCheckUpdates,
    required this.onAbout,
    required this.onSettings,
    required this.onQuit,
    required this.onDismiss,
  });

  final AppStrings strings;
  final String healthHubLabel;
  final String myDataLabel;
  final bool isPaused;
  final VoidCallback onStartNow;
  final VoidCallback onReset;
  final VoidCallback onTogglePause;
  final VoidCallback onExtendCycle;
  final VoidCallback onGuidance;
  final VoidCallback onHealthHub;
  final VoidCallback onDvrs;
  final VoidCallback onReports;
  final VoidCallback onMyData;
  final VoidCallback onCheckUpdates;
  final VoidCallback onAbout;
  final VoidCallback onSettings;
  final VoidCallback onQuit;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final s = strings;

    // Pausas: ações frequentes e de baixa carga textual → linha única de ícones
    // (com tooltip/Semantics para acessibilidade), economizando bastante altura.
    final pauseItems = <_MenuItem>[
      _MenuItem(Icons.play_circle_outline, s.menuStartBreak, onStartNow),
      _MenuItem(Icons.refresh, s.menuReset, onReset),
      _MenuItem(
        isPaused ? Icons.play_arrow : Icons.pause,
        isPaused ? s.menuResume : s.menuPause,
        onTogglePause,
      ),
      _MenuItem(Icons.schedule, s.menuExtendCycle, onExtendCycle),
    ];

    // Saúde visual: hub unificado + DVRS + relatório.
    final healthItems = <_MenuItem>[
      _MenuItem(
        Icons.favorite_outline,
        healthHubLabel,
        onHealthHub,
        emphasized: true,
      ),
      _MenuItem(Icons.menu_book_outlined, s.menuGuidance, onGuidance),
      _MenuItem(Icons.assignment, s.menuDvrs, onDvrs),
      _MenuItem(Icons.picture_as_pdf_outlined, s.menuReports, onReports),
    ];

    // Sistema: manutenção do app. "Sobre" (com link do GitHub dentro) fica logo
    // acima de "Sair".
    final systemItems = <_MenuItem>[
      _MenuItem(Icons.shield_outlined, myDataLabel, onMyData),
      _MenuItem(Icons.system_update_alt, s.menuCheckUpdates, onCheckUpdates),
      _MenuItem(Icons.settings_outlined, s.menuSettings, onSettings),
      _MenuItem(Icons.info_outline, s.menuAbout, onAbout),
      _MenuItem(Icons.close, s.menuQuit, onQuit),
    ];

    _MenuRow rowFor(_MenuItem item) => _MenuRow(
      icon: item.icon,
      label: item.label,
      emphasized: item.emphasized,
      onTap: () {
        item.onTap();
        onDismiss();
      },
    );

    final children = <Widget>[
      _SectionHeader(s.menuGroupActions),
      _CompactActionRow(items: pauseItems, onDismiss: onDismiss),
      const _MenuDivider(),
      _SectionHeader(s.menuGroupHealth),
      ...healthItems.map(rowFor),
      const _MenuDivider(),
      _SectionHeader(s.menuGroupSystem),
      ...systemItems.map(rowFor),
    ];

    return Semantics(
      container: true,
      label: s.menuSemanticLabel,
      child: LiquidGlass(
        width: 280,
        borderRadius: AppRadii.lg,
        // Mais translúcido que o padrão (vidro de verdade), compensado com blur e
        // saturação maiores para manter a vibrância e a profundidade.
        fillOpacity: 0.58,
        blur: 32,
        saturation: 1.6,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }
}

/// Linha única de ações compactas (apenas ícones), distribuídas igualmente.
class _CompactActionRow extends StatelessWidget {
  const _CompactActionRow({required this.items, required this.onDismiss});

  final List<_MenuItem> items;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 2),
      child: Row(
        children: [
          for (final item in items)
            Expanded(
              child: _CompactActionButton(
                icon: item.icon,
                tooltip: item.label,
                onTap: () {
                  item.onTap();
                  onDismiss();
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Botão de ação compacto: ícone centralizado, com tooltip e rótulo semântico
/// (acessibilidade) já que o texto fica oculto.
class _CompactActionButton extends StatefulWidget {
  const _CompactActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_CompactActionButton> createState() => _CompactActionButtonState();
}

class _CompactActionButtonState extends State<_CompactActionButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.tooltip,
      child: Tooltip(
        message: widget.tooltip,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.standard,
              height: 44,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.sm),
                gradient: _hover
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.hoverFillTop,
                          AppColors.hoverFillBottom,
                        ],
                      )
                    : null,
                border: Border.all(
                  color: _hover ? AppColors.hoverBorder : Colors.transparent,
                  width: 0.5,
                ),
              ),
              child: AnimatedScale(
                scale: _hover ? AppMotion.hoverScale : 1.0,
                duration: AppMotion.fast,
                curve: AppMotion.standard,
                child: Icon(
                  widget.icon,
                  size: 22,
                  color: _hover
                      ? AppColors.idleBall
                      : AppColors.textPrimary,
                  shadows: const [
                    Shadow(color: Colors.black54, blurRadius: 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cabeçalho de grupo (rótulo em maiúsculas, discreto).
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: AppColors.textMuted,
            shadows: [
              Shadow(color: Colors.black54, blurRadius: 4),
            ],
          ),
        ),
      ),
    );
  }
}

/// Linha divisória sutil entre grupos.
class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 2),
      color: AppColors.divider,
    );
  }
}

class _MenuRow extends StatefulWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  State<_MenuRow> createState() => _MenuRowState();
}

class _MenuRowState extends State<_MenuRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.emphasized || _hover;
    return Semantics(
      button: true,
      label: widget.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: FocusableActionDetector(
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                widget.onTap();
                return null;
              },
            ),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onTap();
            },
            child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.standard,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
              // Pequeno "deslize" para a direita ao passar o mouse.
              padding: EdgeInsets.only(
                left: _hover ? 14 : 10,
                right: 12,
                top: 10,
                bottom: 10,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadii.sm),
                gradient: _hover
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.hoverFillTop,
                          AppColors.hoverFillBottom,
                        ],
                      )
                    : null,
                border: Border.all(
                  color: widget.emphasized && !_hover
                      ? AppColors.idleBall.withValues(alpha: 0.35)
                      : (_hover ? AppColors.hoverBorder : Colors.transparent),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  AnimatedScale(
                    scale: _hover ? AppMotion.hoverScale : 1.0,
                    duration: AppMotion.fast,
                    curve: AppMotion.standard,
                    child: Icon(
                      widget.icon,
                      size: 18,
                      color: accent
                          ? AppColors.idleBall
                          : AppColors.textPrimary,
                      shadows: const [
                        Shadow(color: Colors.black54, blurRadius: 4),
                      ],
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
                        height: 1.2,
                        color: AppColors.textPrimary,
                        fontWeight: widget.emphasized || _hover
                            ? FontWeight.w600
                            : FontWeight.w400,
                        shadows: const [
                          Shadow(color: Colors.black54, blurRadius: 4),
                        ],
                      ),
                    ),
                  ),
                  if (widget.emphasized)
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: AppColors.idleBall.withValues(alpha: 0.75),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
