import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/app_state.dart';
import '../models/widget_settings.dart';
import '../utils/constants.dart';

/// Painel de configurações. Edita uma cópia local de [WidgetSettings] e
/// devolve o resultado via [onSave].
class SettingsDialog extends StatefulWidget {
  const SettingsDialog({
    super.key,
    required this.initial,
    required this.onSave,
    required this.onClose,
    required this.onReset,
  });

  final WidgetSettings initial;
  final ValueChanged<WidgetSettings> onSave;
  final VoidCallback onClose;
  final VoidCallback onReset;

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late WidgetSettings _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.initial;
  }

  void _set(WidgetSettings next) => setState(() => _draft = next);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: 400,
          constraints: const BoxConstraints(maxHeight: 620),
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
                  const Text(
                    'Configurações',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
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
                      _sectionTitle('Temporização'),
                      _slider(
                        label: 'Ciclo de trabalho',
                        value: _draft.cycleMinutes.toDouble(),
                        min: 1,
                        max: 60,
                        suffix: '${_draft.cycleMinutes} min',
                        onChanged: (v) =>
                            _set(_draft.copyWith(cycleMinutes: v.round())),
                      ),
                      _slider(
                        label: 'Duração de cada fase',
                        value: _draft.phaseSeconds.toDouble(),
                        min: 5,
                        max: 120,
                        suffix: '${_draft.phaseSeconds} s',
                        onChanged: (v) =>
                            _set(_draft.copyWith(phaseSeconds: v.round())),
                      ),

                      _sectionTitle('Aparência'),
                      _slider(
                        label: 'Tamanho da bolinha',
                        value: _draft.ballSize,
                        min: AppDefaults.minBallSize,
                        max: AppDefaults.maxBallSize,
                        suffix: '${_draft.ballSize.round()} px',
                        onChanged: (v) => _set(_draft.copyWith(ballSize: v)),
                      ),
                      _colorRow(
                        label: 'Cor (normal)',
                        selected: _draft.idleColor,
                        onPick: (c) =>
                            _set(_draft.copyWith(idleColor: c)),
                      ),
                      _colorRow(
                        label: 'Cor (alerta)',
                        selected: _draft.alertColor,
                        onPick: (c) =>
                            _set(_draft.copyWith(alertColor: c)),
                      ),
                      _slider(
                        label: 'Opacidade (normal)',
                        value: _draft.idleOpacity,
                        min: 0.3,
                        max: 1.0,
                        suffix: '${(_draft.idleOpacity * 100).round()}%',
                        onChanged: (v) =>
                            _set(_draft.copyWith(idleOpacity: v)),
                      ),
                      _slider(
                        label: 'Velocidade do piscar',
                        value: _draft.blinkMs.toDouble(),
                        min: 200,
                        max: 1500,
                        suffix: '${_draft.blinkMs} ms',
                        onChanged: (v) =>
                            _set(_draft.copyWith(blinkMs: v.round())),
                      ),
                      _switchRow(
                        label: 'Anel de progresso',
                        value: _draft.showProgressRing,
                        onChanged: (v) =>
                            _set(_draft.copyWith(showProgressRing: v)),
                      ),

                      _sectionTitle('Durante a pausa'),
                      _switchRow(
                        label: 'Escurecer o fundo',
                        value: _draft.dimBackground,
                        onChanged: (v) =>
                            _set(_draft.copyWith(dimBackground: v)),
                      ),
                      if (_draft.dimBackground)
                        _slider(
                          label: 'Intensidade do escurecimento',
                          value: _draft.dimOpacity,
                          min: 0.0,
                          max: 0.6,
                          suffix: '${(_draft.dimOpacity * 100).round()}%',
                          onChanged: (v) =>
                              _set(_draft.copyWith(dimOpacity: v)),
                        ),
                      _slider(
                        label: 'Opacidade do overlay',
                        value: _draft.overlayOpacity,
                        min: 0.05,
                        max: 0.4,
                        suffix: '${(_draft.overlayOpacity * 100).round()}%',
                        onChanged: (v) =>
                            _set(_draft.copyWith(overlayOpacity: v)),
                      ),
                      _slider(
                        label: 'Desfoque do overlay',
                        value: _draft.overlayBlur,
                        min: 0,
                        max: 40,
                        suffix: '${_draft.overlayBlur.round()} px',
                        onChanged: (v) =>
                            _set(_draft.copyWith(overlayBlur: v)),
                      ),

                      _sectionTitle('Geral'),
                      _switchRow(
                        label: 'Ativar som',
                        value: _draft.soundEnabled,
                        onChanged: (v) =>
                            _set(_draft.copyWith(soundEnabled: v)),
                      ),
                      _switchRow(
                        label: 'Ativar notificações',
                        value: _draft.notificationsEnabled,
                        onChanged: (v) =>
                            _set(_draft.copyWith(notificationsEnabled: v)),
                      ),
                      _switchRow(
                        label: 'Iniciar com o sistema',
                        value: _draft.launchAtLogin,
                        onChanged: (v) =>
                            _set(_draft.copyWith(launchAtLogin: v)),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Posição padrão da bolinha',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      DropdownButton<BallCorner>(
                        value: _draft.defaultCorner,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF2A2A2A),
                        style: const TextStyle(color: AppColors.textPrimary),
                        underline:
                            Container(height: 1, color: AppColors.glassBorder),
                        items: [
                          for (final corner in BallCorner.values)
                            DropdownMenuItem(
                                value: corner, child: Text(corner.label)),
                        ],
                        onChanged: (v) => _set(
                            _draft.copyWith(defaultCorner: v ?? _draft.defaultCorner)),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(color: AppColors.glassBorder),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: widget.onReset,
                    child: const Text('Restaurar padrões'),
                  ),
                  FilledButton(
                    onPressed: () {
                      widget.onSave(_draft);
                      widget.onClose();
                    },
                    child: const Text('Salvar'),
                  ),
                ],
              ),
            ],
          ),
        ),
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
            Text(label,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 14)),
            Text(suffix,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
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
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
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
          Text(label,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 14)),
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
