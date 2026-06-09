import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/app_state.dart';
import '../models/widget_settings.dart';
import '../utils/constants.dart';
import 'flag_icons.dart';
import 'liquid_glass.dart';

/// Painel de configurações. Edita uma cópia local de [WidgetSettings] e
/// devolve o resultado via [onSave]. Os textos são exibidos no idioma do
/// rascunho — então trocar a bandeira atualiza o painel na hora.
class SettingsDialog extends StatefulWidget {
  const SettingsDialog({
    super.key,
    required this.initial,
    required this.onSave,
    required this.onClose,
    required this.onReset,
    required this.onResetLearning,
  });

  final WidgetSettings initial;
  final FutureOr<void> Function(WidgetSettings settings) onSave;
  final VoidCallback onClose;
  final VoidCallback onReset;

  /// Apaga o aprendizado adaptativo de inatividade.
  final FutureOr<void> Function() onResetLearning;

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late WidgetSettings _draft;
  bool _saving = false;
  bool _resettingLearning = false;

  @override
  void initState() {
    super.initState();
    _draft = widget.initial;
  }

  void _set(WidgetSettings next) => setState(() => _draft = next);

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await Future<void>.sync(() => widget.onSave(_draft));
      if (mounted) widget.onClose();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _resetLearning() async {
    if (_resettingLearning) return;
    setState(() => _resettingLearning = true);
    try {
      await Future<void>.sync(widget.onResetLearning);
    } finally {
      if (mounted) setState(() => _resettingLearning = false);
    }
  }

  /// Liga/desliga a câmera de presença. Ao ligar, pede consentimento explícito
  /// antes de o SO solicitar a permissão de câmera na primeira captura.
  Future<void> _onToggleCamera(bool value, AppStrings s) async {
    if (!value) {
      _set(_draft.copyWith(cameraPresence: false));
      return;
    }
    final consented = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Text(s.cameraConsentTitle),
        content: Text(s.cameraConsentBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s.cameraConsentCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(s.cameraConsentAllow),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (consented == true) _set(_draft.copyWith(cameraPresence: true));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(_draft.languageCode);

    return LiquidGlass(
      width: 400,
      constraints: const BoxConstraints(maxHeight: 640),
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
                  s.settingsTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textPrimary),
                onPressed: widget.onClose,
              ),
            ],
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(s.secLanguage),
                  Row(
                    children: [
                      _langButton(
                        label: 'Português',
                        flag: const FlagIcon.brazil(),
                        selected: _draft.languageCode == 'pt',
                        onTap: () => _set(_draft.copyWith(languageCode: 'pt')),
                      ),
                      const SizedBox(width: 10),
                      _langButton(
                        label: 'English',
                        flag: const FlagIcon.usa(),
                        selected: _draft.languageCode == 'en',
                        onTap: () => _set(_draft.copyWith(languageCode: 'en')),
                      ),
                    ],
                  ),

                  _sectionTitle(s.secTiming),
                  _slider(
                    label: s.workCycle,
                    value: _draft.cycleMinutes.toDouble(),
                    min: 1,
                    max: 60,
                    suffix: '${_draft.cycleMinutes} ${s.unitMin}',
                    onChanged: (v) =>
                        _set(_draft.copyWith(cycleMinutes: v.round())),
                  ),
                  _slider(
                    label: s.breakDuration,
                    value: _draft.phaseSeconds.toDouble(),
                    min: 5,
                    max: 120,
                    suffix: '${_draft.phaseSeconds} ${s.unitSec}',
                    onChanged: (v) =>
                        _set(_draft.copyWith(phaseSeconds: v.round())),
                  ),

                  _sectionTitle(s.secAppearance),
                  _slider(
                    label: s.ballSize,
                    value: _draft.ballSize,
                    min: AppDefaults.minBallSize,
                    max: AppDefaults.maxBallSize,
                    suffix: '${_draft.ballSize.round()} px',
                    onChanged: (v) => _set(_draft.copyWith(ballSize: v)),
                  ),
                  _colorRow(
                    label: s.colorNormal,
                    selected: _draft.idleColor,
                    onPick: (c) => _set(_draft.copyWith(idleColor: c)),
                  ),
                  _colorRow(
                    label: s.colorAlert,
                    selected: _draft.alertColor,
                    onPick: (c) => _set(_draft.copyWith(alertColor: c)),
                  ),
                  _slider(
                    label: s.opacityNormal,
                    value: _draft.idleOpacity,
                    min: 0.3,
                    max: 1.0,
                    suffix: '${(_draft.idleOpacity * 100).round()}%',
                    onChanged: (v) => _set(_draft.copyWith(idleOpacity: v)),
                  ),
                  _slider(
                    label: s.blinkSpeed,
                    value: _draft.blinkMs.toDouble(),
                    min: 200,
                    max: 1500,
                    suffix: '${_draft.blinkMs} ms',
                    onChanged: (v) => _set(_draft.copyWith(blinkMs: v.round())),
                  ),
                  _switchRow(
                    label: s.progressRing,
                    value: _draft.showProgressRing,
                    onChanged: (v) =>
                        _set(_draft.copyWith(showProgressRing: v)),
                  ),

                  _sectionTitle(s.secDuringBreak),
                  _switchRow(
                    label: s.gentleMode,
                    value: _draft.gentleMode,
                    onChanged: (v) => _set(_draft.copyWith(gentleMode: v)),
                  ),
                  _hint(s.gentleHint),
                  const SizedBox(height: 8),
                  _switchRow(
                    label: s.dimBackground,
                    value: _draft.dimBackground,
                    onChanged: (v) => _set(_draft.copyWith(dimBackground: v)),
                  ),
                  if (_draft.dimBackground)
                    _slider(
                      label: s.dimIntensity,
                      value: _draft.dimOpacity,
                      min: 0.0,
                      max: 0.6,
                      suffix: '${(_draft.dimOpacity * 100).round()}%',
                      onChanged: (v) => _set(_draft.copyWith(dimOpacity: v)),
                    ),
                  _slider(
                    label: s.overlayOpacity,
                    value: _draft.overlayOpacity,
                    min: 0.05,
                    max: 0.4,
                    suffix: '${(_draft.overlayOpacity * 100).round()}%',
                    onChanged: (v) => _set(_draft.copyWith(overlayOpacity: v)),
                  ),
                  _slider(
                    label: s.overlayBlur,
                    value: _draft.overlayBlur,
                    min: 0,
                    max: 40,
                    suffix: '${_draft.overlayBlur.round()} px',
                    onChanged: (v) => _set(_draft.copyWith(overlayBlur: v)),
                  ),

                  _sectionTitle(s.secEyeDrops),
                  _switchRow(
                    label: s.eyeDropsEnable,
                    value: _draft.eyeDropsEnabled,
                    onChanged: (v) => _set(_draft.copyWith(eyeDropsEnabled: v)),
                  ),
                  if (_draft.eyeDropsEnabled) ...[
                    const SizedBox(height: 6),
                    _hint(s.eyeDropsInterval),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _choiceButton(
                          label: s.eyeDropsEvery4h,
                          selected: _draft.eyeDropsIntervalHours == 4,
                          onTap: () =>
                              _set(_draft.copyWith(eyeDropsIntervalHours: 4)),
                        ),
                        const SizedBox(width: 10),
                        _choiceButton(
                          label: s.eyeDropsEvery6h,
                          selected: _draft.eyeDropsIntervalHours == 6,
                          onTap: () =>
                              _set(_draft.copyWith(eyeDropsIntervalHours: 6)),
                        ),
                      ],
                    ),
                  ],

                  _sectionTitle(s.secInactivity),
                  _switchRow(
                    label: s.pauseOnInactivityLabel,
                    value: _draft.pauseOnInactivity,
                    onChanged: (v) =>
                        _set(_draft.copyWith(pauseOnInactivity: v)),
                  ),
                  if (_draft.pauseOnInactivity) ...[
                    _switchRow(
                      label: s.cameraPresenceLabel,
                      value: _draft.cameraPresence,
                      onChanged: Platform.isMacOS
                          ? (v) => _onToggleCamera(v, s)
                          : null,
                    ),
                    _hint(
                      Platform.isMacOS
                          ? s.cameraPresenceHint
                          : s.cameraUnavailableHint,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _resettingLearning ? null : _resetLearning,
                        icon: const Icon(Icons.restart_alt, size: 18),
                        label: Text(s.resetLearningLabel),
                      ),
                    ),
                  ],

                  _sectionTitle(s.secGeneral),
                  _switchRow(
                    label: s.enableSound,
                    value: _draft.soundEnabled,
                    onChanged: (v) => _set(_draft.copyWith(soundEnabled: v)),
                  ),
                  _switchRow(
                    label: s.enableNotifications,
                    value: _draft.notificationsEnabled,
                    onChanged: (v) =>
                        _set(_draft.copyWith(notificationsEnabled: v)),
                  ),
                  _switchRow(
                    label: s.launchAtLogin,
                    value: _draft.launchAtLogin,
                    onChanged: (v) => _set(_draft.copyWith(launchAtLogin: v)),
                  ),
                  _switchRow(
                    label: s.hideDock,
                    value: _draft.hideDockIcon,
                    onChanged: (v) => _set(_draft.copyWith(hideDockIcon: v)),
                  ),

                  _sectionTitle(s.secVisibility),
                  _switchRow(
                    label: s.disableMenuBar,
                    value: _draft.hideMenuBarItem,
                    onChanged: (v) => _set(
                      _draft.copyWith(
                        hideMenuBarItem: v,
                        hideFloatingWidget: v
                            ? false
                            : _draft.hideFloatingWidget,
                      ),
                    ),
                  ),
                  _switchRow(
                    label: s.disableFloating,
                    value: _draft.hideFloatingWidget,
                    onChanged: (v) => _set(
                      _draft.copyWith(
                        hideFloatingWidget: v,
                        hideMenuBarItem: v ? false : _draft.hideMenuBarItem,
                      ),
                    ),
                  ),
                  _hint(s.exclusivityHint),
                  const SizedBox(height: 8),
                  Text(
                    s.defaultPosition,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  DropdownButton<BallCorner>(
                    value: _draft.defaultCorner,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF2A2A2A),
                    style: const TextStyle(color: AppColors.textPrimary),
                    underline: Container(
                      height: 1,
                      color: AppColors.glassBorder,
                    ),
                    items: [
                      for (final corner in BallCorner.values)
                        DropdownMenuItem(
                          value: corner,
                          child: Text(s.cornerLabel(corner)),
                        ),
                    ],
                    onChanged: (v) => _set(
                      _draft.copyWith(defaultCorner: v ?? _draft.defaultCorner),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(color: AppColors.glassBorder),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              TextButton(
                onPressed: widget.onReset,
                child: Text(s.restoreDefaults),
              ),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(s.save),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Componentes auxiliares --------------------------------------------

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 4),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.idleBall,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      ),
    ),
  );

  Widget _hint(String text) => Text(
    text,
    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
  );

  Widget _langButton({
    required String label,
    required Widget flag,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.idleBall.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.idleBall : AppColors.glassBorder,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              flag,
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _choiceButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.idleBall.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.idleBall : AppColors.glassBorder,
              width: selected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _slider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String suffix,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
            ),
            Text(
              suffix,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _switchRow({
    required String label,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }

  Widget _colorRow({
    required String label,
    required int selected,
    required ValueChanged<int> onPick,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final color in AppPalette.options)
                _ColorDot(
                  color: color,
                  selected: color.toARGB32() == selected,
                  onTap: () => onPick(color.toARGB32()),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.white : AppColors.glassBorder,
            width: selected ? 3 : 1,
          ),
        ),
        child: selected
            ? Icon(
                Icons.check,
                size: 16,
                color: color.computeLuminance() > 0.6
                    ? Colors.black
                    : Colors.white,
              )
            : null,
      ),
    );
  }
}
