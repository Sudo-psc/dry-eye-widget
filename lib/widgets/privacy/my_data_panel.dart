import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/feature_strings.dart';
import '../../models/dvrs_assessment.dart';
import '../../providers/settings_provider.dart';
import '../../services/activity_stats_service.dart';
import '../../services/dvrs_storage_service.dart';
import '../../services/health_data_service.dart';
import '../../services/screen_time_service.dart';
import '../../services/storage_service.dart';
import '../../ui/app_theme.dart';
import '../liquid_glass.dart';

/// Painel LGPD: exportar JSON local e apagar histórico de saúde.
class MyDataPanel extends StatefulWidget {
  const MyDataPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  State<MyDataPanel> createState() => _MyDataPanelState();
}

class _MyDataPanelState extends State<MyDataPanel> {
  bool _busy = false;
  String? _status;

  HealthDataService _service(BuildContext context) => HealthDataService(
        storage: context.read<StorageService>(),
        dvrs: context.read<DvrsStorageService>(),
        screenTime: context.read<ScreenTimeService>(),
        activity: context.read<ActivityStatsService>(),
      );

  Future<void> _export() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final path = await _service(context).exportToFile();
      if (!mounted) return;
      final f = FeatureStrings.of(
        context.read<SettingsProvider>().value.languageCode,
      );
      setState(() {
        _status = f.myDataExported.replaceAll('{path}', path);
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = e.toString();
        _busy = false;
      });
    }
  }

  Future<void> _clear() async {
    if (_busy) return;
    final f = FeatureStrings.of(
      context.read<SettingsProvider>().value.languageCode,
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(f.myDataClearHealth),
        content: Text(f.myDataConfirmClear),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(f.myDataCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(f.myDataConfirm),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    await _service(context).clearHealthHistory();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = f.myDataCleared;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = context.watch<SettingsProvider>().value.languageCode;
    final f = FeatureStrings.of(lang);
    final count = context.read<DvrsStorageService>().getDvrsHistory().length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: LiquidGlass(
          fillOpacity: 0.8,
          blur: 20,
          child: Column(
            children: [
              _header(theme, f),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      f.myDataSubtitle,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _infoCard(
                      theme,
                      children: [
                        _row(theme, f.myDataInstrument, DvrsResult.dvrsVersion),
                        const SizedBox(height: 8),
                        _row(theme, f.myDataDvrsCount, '$count'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _busy ? null : _export,
                      icon: const Icon(Icons.download_outlined),
                      label: Text(f.myDataExport),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _clear,
                      icon: const Icon(Icons.delete_outline),
                      label: Text(f.myDataClearHealth),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        foregroundColor: theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      f.myDataClearHealthHint,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.55),
                      ),
                    ),
                    if (_status != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.idleBall.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.idleBall.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _status!,
                          style: const TextStyle(fontSize: 13, height: 1.35),
                        ),
                      ),
                    ],
                    if (_busy) ...[
                      const SizedBox(height: 16),
                      const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      f.myDataDisclaimer,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(ThemeData theme, FeatureStrings f) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.55),
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 14, 6),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: widget.onClose,
              tooltip: f.myDataClose,
              style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
            ),
            Expanded(
              child: Text(
                f.myDataTitle,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.shield_outlined, color: AppColors.idleBall),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(ThemeData theme, {required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _row(ThemeData theme, String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
