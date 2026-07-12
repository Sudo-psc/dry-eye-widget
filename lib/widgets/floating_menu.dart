import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_strings.dart';
import '../l10n/feature_strings.dart';
import '../ui/app_theme.dart';
import '../utils/constants.dart';
import 'liquid_glass.dart';

/// Item do menu flutuante.
class _MenuItem {
  const _MenuItem(
    this.icon,
    this.label,
    this.onTap, {
    this.compactLabel,
    this.emphasized = false,
    this.destructive = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? compactLabel;
  final bool emphasized;
  final bool destructive;
}

/// Menu flutuante exibido ao clicar na bolinha (apenas no estado IDLE).
///
/// O primeiro nível concentra ações frequentes. Manutenção e saída ficam numa
/// segunda página para reduzir carga cognitiva sem esconder funcionalidades.
class FloatingMenu extends StatefulWidget {
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
  final VoidCallback onMyData;
  final VoidCallback onCheckUpdates;
  final VoidCallback onAbout;
  final VoidCallback onSettings;
  final VoidCallback onQuit;
  final VoidCallback onDismiss;

  @override
  State<FloatingMenu> createState() => _FloatingMenuState();
}

class _FloatingMenuState extends State<FloatingMenu> {
  bool _showSystem = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final feature = FeatureStrings.of(s.languageCode);
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations == true;

    // Pausas: ações frequentes e de baixa carga textual → linha única de ícones
    // (com tooltip/Semantics para acessibilidade), economizando bastante altura.
    final pauseItems = <_MenuItem>[
      _MenuItem(
        Icons.play_circle_outline,
        s.menuStartBreak,
        widget.onStartNow,
        compactLabel: feature.menuQuickStart,
      ),
      _MenuItem(
        Icons.refresh,
        s.menuReset,
        widget.onReset,
        compactLabel: feature.menuQuickReset,
      ),
      _MenuItem(
        widget.isPaused ? Icons.play_arrow : Icons.pause,
        widget.isPaused ? s.menuResume : s.menuPause,
        widget.onTogglePause,
        compactLabel: widget.isPaused
            ? feature.menuQuickResume
            : feature.menuQuickPause,
      ),
      _MenuItem(
        Icons.schedule,
        s.menuExtendCycle,
        widget.onExtendCycle,
        compactLabel: feature.menuQuickExtend,
      ),
    ];

    // Saúde visual: o Hub concentra DVRS, relatórios e tendências. Orientações
    // permanece direta por ser conteúdo de consulta rápida.
    final healthItems = <_MenuItem>[
      _MenuItem(
        Icons.favorite_outline,
        widget.healthHubLabel,
        widget.onHealthHub,
        emphasized: true,
      ),
      _MenuItem(Icons.menu_book_outlined, s.menuGuidance, widget.onGuidance),
    ];

    // Sistema: manutenção do app. "Sobre" (com link do GitHub dentro) fica logo
    // acima de "Sair".
    final systemItems = <_MenuItem>[
      _MenuItem(Icons.shield_outlined, widget.myDataLabel, widget.onMyData),
      _MenuItem(
        Icons.system_update_alt,
        s.menuCheckUpdates,
        widget.onCheckUpdates,
      ),
      _MenuItem(Icons.settings_outlined, s.menuSettings, widget.onSettings),
      _MenuItem(Icons.info_outline, s.menuAbout, widget.onAbout),
      _MenuItem(Icons.close, s.menuQuit, widget.onQuit, destructive: true),
    ];

    _MenuRow rowFor(_MenuItem item) => _MenuRow(
      icon: item.icon,
      label: item.label,
      emphasized: item.emphasized,
      destructive: item.destructive,
      onTap: () {
        item.onTap();
        widget.onDismiss();
      },
    );

    final children = _showSystem
        ? <Widget>[
            _MenuRow(
              icon: Icons.arrow_back_rounded,
              label: s.back,
              onTap: () => setState(() => _showSystem = false),
            ),
            const _MenuDivider(),
            _SectionHeader(s.menuGroupSystem),
            ...systemItems.map(rowFor),
          ]
        : <Widget>[
            _SectionHeader(s.menuGroupActions),
            _CompactActionRow(items: pauseItems, onDismiss: widget.onDismiss),
            const _MenuDivider(),
            _SectionHeader(feature.menuTrackingSection),
            ...healthItems.map(rowFor),
            const _MenuDivider(),
            _MenuRow(
              icon: Icons.tune_rounded,
              label: s.menuGroupSystem,
              showChevron: true,
              onTap: () => setState(() => _showSystem = true),
            ),
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
        child: AnimatedSwitcher(
          duration: reduceMotion ? Duration.zero : AppMotion.normal,
          switchInCurve: AppMotion.standard,
          switchOutCurve: AppMotion.standard,
          child: Column(
            key: ValueKey(_showSystem),
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
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
                label: item.compactLabel ?? item.label,
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
    required this.label,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_CompactActionButton> createState() => _CompactActionButtonState();
}

class _CompactActionButtonState extends State<_CompactActionButton> {
  bool _hover = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations == true;
    final highlighted = _hover || _focused;
    return Semantics(
      button: true,
      label: widget.tooltip,
      child: Tooltip(
        message: widget.tooltip,
        child: FocusableActionDetector(
          onShowFocusHighlight: (value) => setState(() => _focused = value),
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          },
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                widget.onTap();
                return null;
              },
            ),
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hover = true),
            onExit: (_) => setState(() => _hover = false),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onTap,
              child: AnimatedContainer(
                key: ValueKey('quick-action-${widget.label}'),
                duration: reduceMotion ? Duration.zero : AppMotion.fast,
                curve: AppMotion.standard,
                height: 58,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  gradient: highlighted
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
                    color: _focused
                        ? AppColors.idleBall
                        : (highlighted
                              ? AppColors.hoverBorder
                              : Colors.transparent),
                    width: _focused ? 1.25 : 0.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedScale(
                      scale: highlighted ? AppMotion.hoverScale : 1.0,
                      duration: reduceMotion ? Duration.zero : AppMotion.fast,
                      curve: AppMotion.standard,
                      child: Icon(
                        widget.icon,
                        size: 20,
                        color: highlighted
                            ? AppColors.idleBall
                            : AppColors.textPrimary,
                        shadows: const [
                          Shadow(color: Colors.black54, blurRadius: 4),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.5,
                        height: 1.1,
                        fontWeight: highlighted
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: highlighted
                            ? AppColors.idleBall
                            : AppColors.textSecondary,
                      ),
                    ),
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
            shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
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
    this.showChevron = false,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool emphasized;
  final bool showChevron;
  final bool destructive;

  @override
  State<_MenuRow> createState() => _MenuRowState();
}

class _MenuRowState extends State<_MenuRow> {
  bool _hover = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations == true;
    final highlighted = _hover || _focused;
    final accent = widget.emphasized || highlighted;
    final accentColor = widget.destructive
        ? Theme.of(context).colorScheme.error
        : AppColors.idleBall;
    return Semantics(
      button: true,
      label: widget.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: FocusableActionDetector(
          onShowFocusHighlight: (value) => setState(() => _focused = value),
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          },
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
              duration: reduceMotion ? Duration.zero : AppMotion.fast,
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
                gradient: highlighted && !widget.destructive
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.hoverFillTop,
                          AppColors.hoverFillBottom,
                        ],
                      )
                    : null,
                color: highlighted && widget.destructive
                    ? accentColor.withValues(alpha: 0.12)
                    : null,
                border: Border.all(
                  color: _focused
                      ? accentColor
                      : (widget.emphasized && !highlighted
                            ? AppColors.idleBall.withValues(alpha: 0.35)
                            : (highlighted
                                  ? (widget.destructive
                                        ? accentColor.withValues(alpha: 0.55)
                                        : AppColors.hoverBorder)
                                  : Colors.transparent)),
                  width: _focused ? 1.25 : 0.5,
                ),
              ),
              child: Row(
                children: [
                  AnimatedScale(
                    scale: highlighted ? AppMotion.hoverScale : 1.0,
                    duration: reduceMotion ? Duration.zero : AppMotion.fast,
                    curve: AppMotion.standard,
                    child: Icon(
                      widget.icon,
                      size: 18,
                      color: widget.destructive
                          ? accentColor.withValues(alpha: accent ? 1 : 0.82)
                          : (accent
                                ? AppColors.idleBall
                                : AppColors.textPrimary),
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
                        color: widget.destructive && highlighted
                            ? accentColor
                            : AppColors.textPrimary,
                        fontWeight: widget.emphasized || highlighted
                            ? FontWeight.w600
                            : FontWeight.w400,
                        shadows: const [
                          Shadow(color: Colors.black54, blurRadius: 4),
                        ],
                      ),
                    ),
                  ),
                  if (widget.emphasized || widget.showChevron)
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: accentColor.withValues(alpha: 0.75),
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
