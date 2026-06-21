import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/osdi_assessment.dart';
import '../models/report_options.dart';
import '../models/screen_time_data.dart';
import '../services/pdf_report_service.dart';
import '../services/screen_time_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import 'glass_overlay.dart';

class ReportDialog extends StatefulWidget {
  const ReportDialog({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final _nameController = TextEditingController();
  final _obsController = TextEditingController();
  int _days = 30; // default period
  bool _isGenerating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  Future<void> _generateAndShare(BuildContext context) async {
    setState(() => _isGenerating = true);
    
    try {
      final storage = context.read<StorageService>();
      final screenTimeService = context.read<ScreenTimeService>();
      
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: _days));
      
      final osdiHistory = storage.loadOsdiHistory();
      final filteredOsdi = osdiHistory.where((e) {
        return e.completedAt.isAfter(startDate) && e.completedAt.isBefore(endDate);
      }).toList();

      final screenTimeData = screenTimeService.data;
      final series = screenTimeData.dailySeries(endDate, _days);
      int totalScreenTime = 0;
      int daysWithScreen = 0;
      for (final point in series) {
        if (point.seconds > 0) {
          totalScreenTime += point.seconds;
          daysWithScreen++;
        }
      }
      final averageScreenTime = daysWithScreen > 0 ? totalScreenTime ~/ daysWithScreen : 0;

      OsdiAssessment? latestOsdi;
      OsdiAssessment? previousOsdi;
      if (filteredOsdi.isNotEmpty) {
        latestOsdi = filteredOsdi.last;
        if (filteredOsdi.length > 1) {
          previousOsdi = filteredOsdi[filteredOsdi.length - 2];
        }
      }

      final reportData = ReportData(
        profile: UserProfile(
          name: _nameController.text,
          observations: _obsController.text,
        ),
        options: ReportOptions(
          startDate: startDate,
          endDate: endDate,
        ),
        osdiHistory: filteredOsdi,
        screenTimeData: screenTimeData,
        latestOsdi: latestOsdi,
        previousOsdi: previousOsdi,
        totalScreenTimeSeconds: totalScreenTime,
        averageScreenTimeSeconds: averageScreenTime,
      );

      final service = PdfReportService();
      final pdfBytes = await service.generateReport(reportData);
      
      final file = await service.savePdfFile(pdfBytes, 'Relatorio_Ocular_Digital_${DateTime.now().millisecondsSinceEpoch}');
      
      // Share functionality
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Este relatório pode conter informações pessoais de saúde. Compartilhe apenas com pessoas ou profissionais de sua confiança.',
        subject: 'Relatório de Saúde Visual Digital - Dry Eye Widget',
      );

    } catch (e) {
      debugPrint('Erro ao gerar relatório: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao gerar relatório: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: GlassOverlay(
          opacity: 0.8,
          sigma: 20,
          child: Column(
            children: [
              // Header
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withOpacity(0.5),
                  border: Border(
                    bottom: BorderSide(
                      color: theme.colorScheme.onSurface.withOpacity(0.1),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: widget.onClose,
                      tooltip: 'Voltar',
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Relatórios',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Body
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.picture_as_pdf, color: theme.colorScheme.primary),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Relatório Pessoal',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Exporte seus sintomas, escore OSDI, tempo de tela e pausas em PDF.',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    const Text('Período', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 7, label: Text('7 dias')),
                        ButtonSegment(value: 30, label: Text('30 dias')),
                        ButtonSegment(value: 90, label: Text('90 dias')),
                      ],
                      selected: {_days},
                      onSelectionChanged: (Set<int> newSelection) {
                        setState(() {
                          _days = newSelection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    const Text('Identificação (Opcional)', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Seu Nome',
                        filled: true,
                        fillColor: theme.colorScheme.surface.withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _obsController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Observações Pessoais',
                        alignLabelWithHint: true,
                        filled: true,
                        fillColor: theme.colorScheme.surface.withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: theme.colorScheme.error),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Este relatório é educativo e não substitui avaliação oftalmológica.',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    SizedBox(
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: _isGenerating ? null : () => _generateAndShare(context),
                        icon: _isGenerating 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.share),
                        label: Text(_isGenerating ? 'Gerando...' : 'Gerar e Compartilhar PDF'),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
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
}
