import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/feature_strings.dart';
import '../../providers/settings_provider.dart';
import '../../utils/constants.dart';
import '../dashboard/dashboard_screen.dart';
import '../progress/progress_screen.dart';
import '../summary/day_summary_screen.dart';
import '../liquid_glass.dart';

/// Hub unificado de saúde visual: Hoje · Progresso · Painel (tela + DVRS).
///
/// Reduz a densidade do menu flutuante e concentra descoberta em uma janela.
class HealthHubScreen extends StatefulWidget {
  const HealthHubScreen({
    super.key,
    required this.onClose,
    required this.onStartBreak,
    required this.onDvrs,
    required this.onReports,
    required this.onSnoozeDvrsNudge,
    this.initialTab = 0,
  });

  final VoidCallback onClose;
  final VoidCallback onStartBreak;
  final VoidCallback onDvrs;
  final VoidCallback onReports;
  final Future<void> Function() onSnoozeDvrsNudge;
  final int initialTab;

  @override
  State<HealthHubScreen> createState() => _HealthHubScreenState();
}

class _HealthHubScreenState extends State<HealthHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialTab.clamp(0, 2);
    _tabs = TabController(length: 3, vsync: this, initialIndex: initial);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _goTab(int i) {
    _tabs.animateTo(i.clamp(0, 2));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = context.watch<SettingsProvider>().value.languageCode;
    final f = FeatureStrings.of(lang);

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
              Material(
                color: theme.colorScheme.surface.withValues(alpha: 0.35),
                child: TabBar(
                  controller: _tabs,
                  labelColor: AppColors.idleBall,
                  unselectedLabelColor:
                      theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  indicatorColor: AppColors.idleBall,
                  tabs: [
                    Tab(text: f.healthHubTabToday),
                    Tab(text: f.healthHubTabProgress),
                    Tab(text: f.healthHubTabScreen),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    // Sem chrome próprio: DaySummary ainda tem header; usamos
                    // onClose do hub e CTAs para abas internas.
                    DaySummaryScreen(
                      onClose: widget.onClose,
                      onStartBreak: widget.onStartBreak,
                      onDvrs: widget.onDvrs,
                      onProgress: () => _goTab(1),
                      onDashboard: () => _goTab(2),
                      onSnoozeDvrsNudge: widget.onSnoozeDvrsNudge,
                      embedded: true,
                    ),
                    ProgressScreen(onClose: widget.onClose, embedded: true),
                    DashboardScreen(onClose: widget.onClose, embedded: true),
                  ],
                ),
              ),
              _footerActions(theme, f),
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
            const SizedBox(width: 2),
            Expanded(
              child: Text(
                f.healthHubTitle,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.idleBall.withValues(alpha: 0.16),
              ),
              child: Icon(
                Icons.favorite_outline,
                color: AppColors.idleBall,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _footerActions(ThemeData theme, FeatureStrings f) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: widget.onDvrs,
              icon: const Icon(Icons.assignment_outlined, size: 18),
              label: Text(f.healthHubOpenQuestionnaire),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: widget.onReports,
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: Text(f.healthHubOpenReports),
            ),
          ),
        ],
      ),
    );
  }
}
