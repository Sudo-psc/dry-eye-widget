import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_strings.dart';
import '../l10n/feature_strings.dart';
import '../models/dvrs_assessment.dart';
import '../models/environment_checklist.dart';
import '../models/report_options.dart';
import '../providers/settings_provider.dart';
import '../services/dvrs_storage_service.dart';
import '../services/pdf_report_service.dart';
import '../services/report_builder.dart';
import '../services/screen_time_service.dart';
import '../services/storage_service.dart';
import 'common/panel_entrance.dart';
import 'common/panel_header.dart';
import '../ui/panel_state_view.dart';
import 'liquid_glass.dart';

class ReportDialog extends StatefulWidget {
  const ReportDialog({super.key, required this.onClose, this.embedded = false});

  final VoidCallback onClose;
  final bool embedded;

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final _nameController = TextEditingController();
  final _obsController = TextEditingController();
  final _builder = const ReportBuilder();
  final _pdfService = PdfReportService();

  ReportPeriod _period = ReportPeriod.last30;
  DateTime _customStart = DateTime.now().subtract(const Duration(days: 14));
  DateTime _customEnd = DateTime.now();
  bool _isBusy = false;
  String? _errorMessage;

  /// Checklist ambiental opcional (carregado e persistido localmente).
  EnvironmentChecklist? _environment;

  /// Último PDF salvo no dispositivo (para permitir exclusão).
  File? _lastSavedFile;

  @override
  void initState() {
    super.initState();
    _environment = context.read<StorageService>().loadEnvironmentChecklist();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  // --- Montagem dos dados -------------------------------------------------

  ReportOptions _resolveOptions() {
    final now = DateTime.now();
    final includeEnv = _environment != null;
    final days = _period.days;
    if (days != null) {
      return ReportOptions(
        period: _period,
        startDate: now.subtract(Duration(days: days)),
        endDate: now,
        includeEnvironment: includeEnv,
      );
    }
    return ReportOptions(
      period: ReportPeriod.custom,
      startDate: _customStart,
      endDate: _customEnd,
      includeEnvironment: includeEnv,
    );
  }

  /// Histórico do DVRS para o relatório. Protegido com try/catch: em contextos
  /// de teste que não registram o provider, devolve lista vazia.
  List<DvrsResult> _dvrsHistory() {
    try {
      return context.read<DvrsStorageService>().getDvrsHistory();
    } catch (_) {
      return const <DvrsResult>[];
    }
  }

  ReportData _buildReportData() {
    final storage = context.read<StorageService>();
    final screenTimeService = context.read<ScreenTimeService>();

    return _builder.build(
      profile: UserProfile(
        name: _nameController.text,
        observations: _obsController.text,
      ),
      options: _resolveOptions(),
      screenTime: screenTimeService.data,
      breakStats: storage.loadBreakStats(),
      environment: _environment,
      dvrsHistory: _dvrsHistory(),
    );
  }

  String _fileName() =>
      'Relatorio_Saude_Visual_${DateTime.now().millisecondsSinceEpoch}';

  // --- Ações --------------------------------------------------------------

  Future<void> _savePdf(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final strings = context.read<SettingsProvider>().strings;
    final data = _buildReportData();
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });
    try {
      final bytes = await _pdfService.generateReport(data);
      final file = await _pdfService.savePdfToDevice(bytes, _fileName());
      if (mounted) setState(() => _lastSavedFile = file);
      messenger.showSnackBar(
        SnackBar(content: Text(strings.reportsPdfSavedText(file.path))),
      );
    } catch (e) {
      _showError(messenger, e);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _deleteLastPdf(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final strings = context.read<SettingsProvider>().strings;
    final file = _lastSavedFile;
    if (file == null) return;
    try {
      if (await file.exists()) await file.delete();
      if (mounted) setState(() => _lastSavedFile = null);
      messenger.showSnackBar(
        SnackBar(content: Text(strings.reportsPdfDeleted)),
      );
    } catch (e) {
      _showError(messenger, e);
    }
  }

  Future<void> _sharePdf(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    // Privacidade (LGPD): exige confirmação explícita antes de compartilhar.
    final confirmed = await _confirmPrivacy(context);
    if (confirmed != true || !mounted) return;

    final data = _buildReportData();
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });
    try {
      final bytes = await _pdfService.generateReport(data);
      final file = await _pdfService.savePdfFile(bytes, _fileName());
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: PdfReportService.privacyNotice,
          subject: 'Relatório de Saúde Visual Digital — Dry Eye Widget',
        ),
      );
    } catch (e) {
      _showError(messenger, e);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<bool?> _confirmPrivacy(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          context.read<SettingsProvider>().strings.reportsBeforeShare,
        ),
        content: const Text(PdfReportService.privacyNotice),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.read<SettingsProvider>().strings.reportsCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(context.read<SettingsProvider>().strings.reportsShare),
          ),
        ],
      ),
    );
  }

  void _showError(ScaffoldMessengerState messenger, Object e) {
    debugPrint('Erro ao gerar relatório: $e');
    final message = context.read<SettingsProvider>().strings.reportsErrorText(
      e,
    );
    if (mounted) setState(() => _errorMessage = message);
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 400)),
      lastDate: now,
      initialDateRange: DateTimeRange(start: _customStart, end: _customEnd),
    );
    if (picked != null) {
      setState(() {
        _customStart = picked.start;
        _customEnd = picked.end;
        _period = ReportPeriod.custom;
      });
    }
  }

  // --- UI -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = context.watch<SettingsProvider>().strings;
    final f = FeatureStrings.of(
      context.watch<SettingsProvider>().value.languageCode,
    );
    // Prévia recalculada a cada rebuild (dados locais em memória).
    final preview = _buildReportData();

    final content = Column(
      children: [
        if (!widget.embedded)
          PanelHeader(
            title: strings.menuReports,
            onLeading: widget.onClose,
            leadingTooltip: strings.back,
            leadingIcon: Icons.arrow_back_rounded,
            trailingIcon: Icons.description_outlined,
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _personalCard(theme, strings),
              const SizedBox(height: 24),
              _periodSelector(theme),
              const SizedBox(height: 24),
              _identificationFields(theme),
              const SizedBox(height: 24),
              _environmentSection(theme),
              const SizedBox(height: 24),
              _previewCard(theme, preview),
              const SizedBox(height: 16),
              _disclaimerBanner(theme),
              const SizedBox(height: 24),
              if (_errorMessage != null) ...[
                PanelStateView(
                  compact: true,
                  tone: PanelStateTone.error,
                  icon: Icons.error_outline,
                  title: f.stateReportErrorTitle,
                  message: _errorMessage!,
                ),
                const SizedBox(height: 16),
              ],
              if (_lastSavedFile != null) ...[
                PanelStateView(
                  compact: true,
                  tone: PanelStateTone.success,
                  icon: Icons.check_circle_outline,
                  title: f.stateReportSuccessTitle,
                  message: strings.reportsPdfSavedText(_lastSavedFile!.path),
                ),
                const SizedBox(height: 16),
              ],
              _actionButtons(),
            ],
          ),
        ),
      ],
    );
    if (widget.embedded) return content;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: LiquidGlass(
          fillOpacity: 0.8,
          blur: 20,
          child: PanelEntrance(child: content),
        ),
      ),
    );
  }

  Widget _personalCard(ThemeData theme, AppStrings strings) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: theme.colorScheme.primary.withValues(alpha: 0.3),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.picture_as_pdf, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                strings.reportsPersonalTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          strings.reportsPersonalSubtitle,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    ),
  );

  Widget _periodSelector(ThemeData theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        context.read<SettingsProvider>().strings.reportsPeriod,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      SegmentedButton<ReportPeriod>(
        segments: [
          ButtonSegment(
            value: ReportPeriod.last7,
            label: Text(context.read<SettingsProvider>().strings.reportsDays7),
          ),
          ButtonSegment(
            value: ReportPeriod.last30,
            label: Text(context.read<SettingsProvider>().strings.reportsDays30),
          ),
          ButtonSegment(
            value: ReportPeriod.last90,
            label: Text(context.read<SettingsProvider>().strings.reportsDays90),
          ),
          ButtonSegment(
            value: ReportPeriod.custom,
            label: Text(context.read<SettingsProvider>().strings.reportsCustom),
            icon: const Icon(Icons.event),
          ),
        ],
        selected: {_period},
        onSelectionChanged: (sel) {
          final value = sel.first;
          if (value == ReportPeriod.custom) {
            _pickCustomRange(context);
          } else {
            setState(() => _period = value);
          }
        },
      ),
      if (_period == ReportPeriod.custom) ...[
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.date_range, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              '${_fmt(_customStart)} — ${_fmt(_customEnd)}',
              style: const TextStyle(fontSize: 13),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => _pickCustomRange(context),
              child: Text(
                context.read<SettingsProvider>().strings.reportsChange,
              ),
            ),
          ],
        ),
      ],
    ],
  );

  Widget _identificationFields(ThemeData theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        context.read<SettingsProvider>().strings.reportsIdentification,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: _nameController,
        onChanged: (_) => setState(() {}),
        decoration: _fieldDecoration(
          theme,
          context.read<SettingsProvider>().strings.reportsNameHint,
        ),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _obsController,
        maxLines: 3,
        onChanged: (_) => setState(() {}),
        decoration: _fieldDecoration(
          theme,
          context.read<SettingsProvider>().strings.reportsNotesHint,
          alignHint: true,
        ),
      ),
    ],
  );

  InputDecoration _fieldDecoration(
    ThemeData theme,
    String label, {
    bool alignHint = false,
  }) => InputDecoration(
    labelText: label,
    alignLabelWithHint: alignHint,
    filled: true,
    fillColor: theme.colorScheme.surface.withValues(alpha: 0.5),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );

  Widget _previewCard(ThemeData theme, ReportData data) {
    final (Color color, String label) = switch (data.indication) {
      OverallIndication.monitor => (Colors.green, 'Acompanhar a evolução'),
      OverallIndication.reinforceBreaks => (
        Colors.orange,
        'Reforçar as pausas visuais',
      ),
      OverallIndication.seekEvaluation => (
        Colors.red,
        'Considere avaliação oftalmológica',
      ),
    };

    final lines = <(String, String)>[];
    final dvrs = data.dvrs;
    if (dvrs != null) {
      lines.add(('DVRS', 'Perfil educativo por domínios incluído'));
    }
    if (data.screenTime.hasData) {
      lines.add((
        'Tempo médio/dia',
        _duration(data.screenTime.averageDailySeconds),
      ));
    }
    if (data.breaks.adherenceRate != null) {
      lines.add((
        'Adesão às pausas',
        '${(data.breaks.adherenceRate! * 100).toStringAsFixed(0)}%',
      ));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.read<SettingsProvider>().strings.reportsPreview,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Período: ${_fmt(data.options.startDate)} a ${_fmt(data.options.endDate)}',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 10, color: color),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(color: color, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (lines.isEmpty)
            Text(
              'Preencha mais dados para acompanhar tendências ao longo do tempo.',
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            )
          else
            ...lines.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.$1, style: const TextStyle(fontSize: 13)),
                    Text(
                      e.$2,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _disclaimerBanner(ThemeData theme) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(Icons.info_outline, color: theme.colorScheme.error),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Este relatório é educativo e não substitui avaliação oftalmológica.',
            style: TextStyle(fontSize: 12, color: theme.colorScheme.error),
          ),
        ),
      ],
    ),
  );

  // --- Checklist ambiental ------------------------------------------------

  void _toggleEnv(bool on) {
    final storage = context.read<StorageService>();
    if (on) {
      final created = EnvironmentChecklist(updatedAt: DateTime.now());
      setState(() => _environment = created);
      storage.saveEnvironmentChecklist(created);
    } else {
      setState(() => _environment = null);
      storage.clearEnvironmentChecklist();
    }
  }

  void _updateEnv(EnvironmentChecklist Function(EnvironmentChecklist) f) {
    final cur = _environment;
    if (cur == null) return;
    final next = f(cur).copyWith(updatedAt: DateTime.now());
    setState(() => _environment = next);
    context.read<StorageService>().saveEnvironmentChecklist(next);
  }

  Widget _envCheck(String label, bool value, ValueChanged<bool> onChanged) =>
      CheckboxListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        value: value,
        onChanged: (v) => onChanged(v ?? false),
        title: Text(label, style: const TextStyle(fontSize: 13)),
      );

  Widget _environmentSection(ThemeData theme) {
    final env = _environment;
    final (Color color, String label) = switch (env?.risk) {
      null => (theme.colorScheme.onSurface, ''),
      EnvironmentRisk.adequate => (Colors.green, 'Adequado'),
      EnvironmentRisk.attention => (Colors.orange, 'Atenção'),
      EnvironmentRisk.increased => (Colors.red, 'Risco aumentado'),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Ambiente visual (opcional)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Switch(value: env != null, onChanged: _toggleEnv),
            ],
          ),
          const Text(
            'Inclua um checklist do seu ambiente de trabalho no relatório.',
            style: TextStyle(fontSize: 13),
          ),
          if (env != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Classificação: ', style: TextStyle(fontSize: 13)),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(),
            const Text(
              'Ergonomia adequada',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            _envCheck(
              'Distância da tela adequada',
              env.screenDistanceOk,
              (v) => _updateEnv((e) => e.copyWith(screenDistanceOk: v)),
            ),
            _envCheck(
              'Altura do monitor adequada',
              env.monitorHeightOk,
              (v) => _updateEnv((e) => e.copyWith(monitorHeightOk: v)),
            ),
            _envCheck(
              'Brilho confortável',
              env.brightnessOk,
              (v) => _updateEnv((e) => e.copyWith(brightnessOk: v)),
            ),
            _envCheck(
              'Contraste confortável',
              env.contrastOk,
              (v) => _updateEnv((e) => e.copyWith(contrastOk: v)),
            ),
            _envCheck(
              'Iluminação do ambiente adequada',
              env.lightingOk,
              (v) => _updateEnv((e) => e.copyWith(lightingOk: v)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Fatores de risco presentes',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            _envCheck(
              'Reflexo na tela',
              env.glare,
              (v) => _updateEnv((e) => e.copyWith(glare: v)),
            ),
            _envCheck(
              'Ar-condicionado',
              env.airConditioning,
              (v) => _updateEnv((e) => e.copyWith(airConditioning: v)),
            ),
            _envCheck(
              'Ambiente seco / baixa umidade',
              env.dryAir,
              (v) => _updateEnv((e) => e.copyWith(dryAir: v)),
            ),
            _envCheck(
              'Múltiplos monitores',
              env.multiMonitor,
              (v) => _updateEnv((e) => e.copyWith(multiMonitor: v)),
            ),
            _envCheck(
              'Home office',
              env.homeOffice,
              (v) => _updateEnv((e) => e.copyWith(homeOffice: v)),
            ),
            _envCheck(
              'Ventilador direcionado ao rosto',
              env.fanOnFace,
              (v) => _updateEnv((e) => e.copyWith(fanOnFace: v)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _actionButtons() => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: _isBusy ? null : () => _savePdf(context),
                icon: _isBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_alt),
                label: Text(
                  context.read<SettingsProvider>().strings.reportsSavePdf,
                ),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 50,
              child: FilledButton.tonalIcon(
                onPressed: _isBusy ? null : () => _sharePdf(context),
                icon: const Icon(Icons.share),
                label: Text(
                  context.read<SettingsProvider>().strings.reportsShare,
                ),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      if (_lastSavedFile != null) ...[
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: _isBusy ? null : () => _deleteLastPdf(context),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: Text(
              context.read<SettingsProvider>().strings.reportsDeleteSavedPdf,
            ),
          ),
        ),
      ],
      const SizedBox(height: 12),
      SizedBox(
        height: 44,
        width: double.infinity,
        child: OutlinedButton(
          onPressed: _isBusy ? null : widget.onClose,
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(context.read<SettingsProvider>().strings.reportsCancel),
        ),
      ),
    ],
  );

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _duration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${minutes}min';
    return '${minutes}min';
  }
}
