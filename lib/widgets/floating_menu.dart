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

enum _FloatingMenuPage { main, system, quiet }

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
    this.blinkRemindersQuietUntil,
    this.onQuietBlinkReminders,
    this.onResumeBlinkReminders,
    this.autofocusFirstAction = false,
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
  final DateTime? blinkRemindersQuietUntil;
  final ValueChanged<Duration>? onQuietBlinkReminders;
  final VoidCallback? onResumeBlinkReminders;
  final bool autofocusFirstAction;

  @override
  State<FloatingMenu> createState() => _FloatingMenuState();
}

class _FloatingMenuState extends State<FloatingMenu> {
  _FloatingMenuPage _page = _FloatingMenuPage.main;
  final FocusNode _firstActionFocusNode = FocusNode(
    debugLabel: 'floating-menu-first-action',
  );
  final FocusNode _quietActionFocusNode = FocusNode(
    debugLabel: 'floating-menu-quiet-action',
  );
  final FocusNode _systemActionFocusNode = FocusNode(
    debugLabel: 'floating-menu-system-action',
  );
  final FocusNode _subpageBackFocusNode = FocusNode(
    debugLabel: 'floating-menu-subpage-back',
  );

  @override
  void dispose() {
    _firstActionFocusNode.dispose();
    _quietActionFocusNode.dispose();
    _systemActionFocusNode.dispose();
    _subpageBackFocusNode.dispose();
    super.dispose();
  }

  void _showPage(_FloatingMenuPage page) {
    setState(() => _page = page);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _subpageBackFocusNode.requestFocus();
    });
  }

  void _returnToMain(FocusNode focusNode) {
    setState(() => _page = _FloatingMenuPage.main);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) focusNode.requestFocus();
    });
  }

  void _handleEscape() {
    switch (_page) {
      case _FloatingMenuPage.main:
        widget.onDismiss();
        return;
      case _FloatingMenuPage.system:
        _returnToMain(_systemActionFocusNode);
        return;
      case _FloatingMenuPage.quiet:
        _returnToMain(_quietActionFocusNode);
        return;
    }
  }

  String _clockTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final feature = FeatureStrings.of(s.languageCode);
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations == true;
    final quietUntil = widget.blinkRemindersQuietUntil;
    final quietActive =
        quietUntil != null && quietUntil.isAfter(DateTime.now());
    final quietStatus = quietActive
        ? s.quietBlinkActiveUntil.replaceFirst('{time}', _clockTime(quietUntil))
        : null;

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

    late final List<Widget> children;
    switch (_page) {
      case _FloatingMenuPage.main:
        children = <Widget>[
          _SectionHeader(
            s.menuGroupActions,
            trailing: widget.onQuietBlinkReminders == null
                ? null
                : _HeaderAction(
                    key: const ValueKey('quiet-blink-reminders-action'),
                    icon: quietActive
                        ? Icons.notifications_paused_outlined
                        : Icons.notifications_off_outlined,
                    label: quietActive
                        ? _clockTime(quietUntil)
                        : s.menuQuietBlinkReminders,
                    semanticLabel: quietStatus == null
                        ? s.menuQuietBlinkReminders
                        : '${s.menuQuietBlinkReminders}. $quietStatus',
                    focusNode: _quietActionFocusNode,
                    onTap: () => _showPage(_FloatingMenuPage.quiet),
                  ),
          ),
          _CompactActionRow(
            items: pauseItems,
            onDismiss: widget.onDismiss,
            firstFocusNode: _firstActionFocusNode,
            autofocusFirstAction: widget.autofocusFirstAction,
          ),
          const _MenuDivider(),
          _SectionHeader(feature.menuTrackingSection),
          ...healthItems.map(rowFor),
          const _MenuDivider(),
          _MenuRow(
            icon: Icons.tune_rounded,
            label: s.menuGroupSystem,
            showChevron: true,
            focusNode: _systemActionFocusNode,
            onTap: () => _showPage(_FloatingMenuPage.system),
          ),
        ];
        break;
      case _FloatingMenuPage.system:
        children = <Widget>[
          _MenuRow(
            icon: Icons.arrow_back_rounded,
            label: s.back,
            focusNode: _subpageBackFocusNode,
            onTap: () => _returnToMain(_systemActionFocusNode),
          ),
          const _MenuDivider(),
          _SectionHeader(s.menuGroupSystem),
          ...systemItems.map(rowFor),
        ];
        break;
      case _FloatingMenuPage.quiet:
        children = <Widget>[
          _MenuRow(
            icon: Icons.arrow_back_rounded,
            label: s.back,
            focusNode: _subpageBackFocusNode,
            onTap: () => _returnToMain(_quietActionFocusNode),
          ),
          const _MenuDivider(),
          _SectionHeader(s.quietBlinkRemindersTitle),
          _QuietPageDescription(
            description: s.quietBlinkRemindersDescription,
            status: quietStatus,
          ),
          _CompactActionRow(
            items: <_MenuItem>[
              _MenuItem(
                Icons.timer_outlined,
                s.quietBlinkFor15Minutes,
                () => widget.onQuietBlinkReminders?.call(
                  const Duration(minutes: 15),
                ),
              ),
              _MenuItem(
                Icons.schedule_outlined,
                s.quietBlinkFor1Hour,
                () => widget.onQuietBlinkReminders?.call(
                  const Duration(hours: 1),
                ),
              ),
            ],
            onDismiss: widget.onDismiss,
          ),
          if (quietActive && widget.onResumeBlinkReminders != null) ...[
            const _MenuDivider(),
            _MenuRow(
              icon: Icons.notifications_active_outlined,
              label: s.quietBlinkResumeNow,
              onTap: () {
                widget.onResumeBlinkReminders?.call();
                widget.onDismiss();
              },
            ),
          ],
        ];
        break;
    }

    return Focus(
      autofocus: !widget.autofocusFirstAction,
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          _handleEscape();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Semantics(
        container: true,
        label: s.menuSemanticLabel,
        child: LiquidGlass(
          width: AppComponentSize.floatingMenuWidth,
          borderRadius: AppRadii.lg,
          padding: const EdgeInsets.symmetric(vertical: AppSpace.x2),
          child: AnimatedSwitcher(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 180),
            reverseDuration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 150),
            switchInCurve: Curves.linear,
            switchOutCurve: Curves.linear,
            layoutBuilder: (currentChild, previousChildren) => Stack(
              alignment: Alignment.topCenter,
              children: <Widget>[...previousChildren, ?currentChild],
            ),
            transitionBuilder: (child, animation) {
              final pageName = (child.key! as ValueKey<String>).value;
              final fade = CurvedAnimation(
                parent: animation,
                curve: const Interval(0.55, 1, curve: AppMotion.standard),
                reverseCurve: const Interval(
                  0.55,
                  1,
                  curve: AppMotion.standard,
                ),
              );
              final scale = CurvedAnimation(
                parent: animation,
                curve: AppMotion.standard,
                reverseCurve: AppMotion.standard,
              );
              return FadeTransition(
                key: ValueKey('floating-menu-transition-$pageName'),
                opacity: fade,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.992, end: 1).animate(scale),
                  child: child,
                ),
              );
            },
            child: SingleChildScrollView(
              key: ValueKey(_page.name),
              primary: false,
              child: Column(mainAxisSize: MainAxisSize.min, children: children),
            ),
          ),
        ),
      ),
    );
  }
}

/// Linha única de ações compactas (apenas ícones), distribuídas igualmente.
class _CompactActionRow extends StatelessWidget {
  const _CompactActionRow({
    required this.items,
    required this.onDismiss,
    this.firstFocusNode,
    this.autofocusFirstAction = false,
  });

  final List<_MenuItem> items;
  final VoidCallback onDismiss;
  final FocusNode? firstFocusNode;
  final bool autofocusFirstAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.x2,
        vertical: AppSpace.x1,
      ),
      child: Row(
        children: [
          for (var index = 0; index < items.length; index++)
            Expanded(
              child: _CompactActionButton(
                icon: items[index].icon,
                label: items[index].compactLabel ?? items[index].label,
                tooltip: items[index].label,
                focusNode: index == 0 ? firstFocusNode : null,
                autofocus: index == 0 && autofocusFirstAction,
                onTap: () {
                  items[index].onTap();
                  onDismiss();
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Botão de ação compacto: ícone centralizado, rótulo legível e tooltip.
class _CompactActionButton extends StatefulWidget {
  const _CompactActionButton({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onTap,
    this.focusNode,
    this.autofocus = false,
  });

  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback onTap;
  final FocusNode? focusNode;
  final bool autofocus;

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
      onTap: widget.onTap,
      excludeSemantics: true,
      child: Tooltip(
        message: widget.tooltip,
        child: FocusableActionDetector(
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
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
                height: AppComponentSize.compactActionHeight,
                margin: const EdgeInsets.symmetric(horizontal: AppSpace.x1),
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
                        size: AppComponentSize.icon,
                        color: highlighted
                            ? AppColors.idleBall
                            : AppColors.textPrimary,
                        shadows: const [
                          Shadow(color: Colors.black54, blurRadius: 4),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpace.x1),
                    Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppTypography.minimumReadable,
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

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    super.key,
    required this.icon,
    required this.label,
    required this.semanticLabel,
    required this.focusNode,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String semanticLabel;
  final FocusNode focusNode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      onTap: onTap,
      excludeSemantics: true,
      child: Tooltip(
        message: semanticLabel,
        child: TextButton.icon(
          focusNode: focusNode,
          onPressed: onTap,
          style: TextButton.styleFrom(
            minimumSize: const Size(44, 44),
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.x2),
            foregroundColor: AppColors.idleBall,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            textStyle: const TextStyle(
              fontSize: AppTypography.supporting,
              fontWeight: FontWeight.w600,
            ),
          ),
          icon: Icon(icon, size: AppSpace.x4),
          label: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 112),
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
      ),
    );
  }
}

class _QuietPageDescription extends StatelessWidget {
  const _QuietPageDescription({required this.description, this.status});

  final String description;
  final String? status;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 2, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              height: 1.35,
              color: AppColors.textSecondary,
            ),
          ),
          if (status != null) ...[
            const SizedBox(height: 6),
            Text(
              status!,
              style: const TextStyle(
                fontSize: 12,
                height: 1.25,
                fontWeight: FontWeight.w600,
                color: AppColors.idleBall,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Cabeçalho de grupo (rótulo em maiúsculas, discreto).
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, {this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    const titleStyle = TextStyle(
      fontSize: AppTypography.minimumReadable,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
      color: AppColors.textMuted,
      shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
    );
    if (trailing != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(18, 2, 8, 2),
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle,
                ),
              ),
              const SizedBox(width: 4),
              trailing!,
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title.toUpperCase(), style: titleStyle),
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
    this.focusNode,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool emphasized;
  final bool showChevron;
  final bool destructive;
  final FocusNode? focusNode;

  @override
  State<_MenuRow> createState() => _MenuRowState();
}

class _MenuRowState extends State<_MenuRow> {
  bool _hover = false;
  bool _focused = false;

  void _activate() {
    HapticFeedback.selectionClick();
    widget.onTap();
  }

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
      onTap: _activate,
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: FocusableActionDetector(
          focusNode: widget.focusNode,
          onShowFocusHighlight: (value) => setState(() => _focused = value),
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          },
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                _activate();
                return null;
              },
            ),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _activate,
            child: AnimatedContainer(
              key: ValueKey('menu-row-${widget.label}'),
              duration: reduceMotion ? Duration.zero : AppMotion.fast,
              curve: AppMotion.standard,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
              constraints: const BoxConstraints(minHeight: 44),
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
