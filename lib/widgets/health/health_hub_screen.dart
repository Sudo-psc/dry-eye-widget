import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n/feature_strings.dart';
import '../../providers/settings_provider.dart';
import '../../utils/constants.dart';
import '../dashboard/dashboard_screen.dart';
import '../dvrs/dvrs_screen.dart';
import '../progress/progress_screen.dart';
import '../report_dialog.dart';
import '../summary/day_summary_screen.dart';
import '../liquid_glass.dart';

/// Hub unificado de saúde visual: Hoje · Tendências · DVRS · Relatórios.
///
/// Reduz a densidade do menu flutuante e concentra descoberta em uma janela.
class HealthHubScreen extends StatefulWidget {
  const HealthHubScreen({
    super.key,
    required this.onClose,
    required this.onStartBreak,
    required this.onSnoozeDvrsNudge,
    this.initialTab = 0,
    this.onTabChanged,
  });

  final VoidCallback onClose;
  final VoidCallback onStartBreak;
  final Future<void> Function() onSnoozeDvrsNudge;
  final int initialTab;
  final ValueChanged<int>? onTabChanged;

  @override
  State<HealthHubScreen> createState() => _HealthHubScreenState();
}

class _HealthHubScreenState extends State<HealthHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  int _evolutionIndex = 0;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialTab.clamp(0, 3);
    _tabs = TabController(length: 4, vsync: this, initialIndex: initial);
    _tabs.addListener(_handleTabChanged);
  }

  @override
  void dispose() {
    _tabs.removeListener(_handleTabChanged);
    _tabs.dispose();
    super.dispose();
  }

  void _handleTabChanged() {
    if (!_tabs.indexIsChanging) {
      widget.onTabChanged?.call(_tabs.index);
    }
  }

  void _goTab(int i) {
    _tabs.animateTo(i.clamp(0, 3));
  }

  void _openEvolution(int index) {
    setState(() => _evolutionIndex = index.clamp(0, 1));
    _goTab(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = context.watch<SettingsProvider>().value.languageCode;
    final f = FeatureStrings.of(lang);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): widget.onClose,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
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
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelColor: AppColors.idleBall,
                      unselectedLabelColor: theme.colorScheme.onSurface
                          .withValues(alpha: 0.65),
                      indicatorColor: AppColors.idleBall,
                      tabs: [
                        Tab(text: f.healthHubTabToday),
                        Tab(text: f.healthHubTabProgress),
                        Tab(text: f.healthHubTabDvrs),
                        Tab(text: f.healthHubTabReports),
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
                          onDvrs: () => _goTab(2),
                          onProgress: () => _openEvolution(0),
                          onDashboard: () => _openEvolution(1),
                          onSnoozeDvrsNudge: widget.onSnoozeDvrsNudge,
                          embedded: true,
                        ),
                        _EvolutionSection(
                          index: _evolutionIndex,
                          onChanged: (index) {
                            setState(() => _evolutionIndex = index);
                          },
                        ),
                        DvrsScreen(
                          embedded: true,
                          onClose: () => _goTab(0),
                          onExportPdf: (_) async => _goTab(3),
                        ),
                        ReportDialog(embedded: true, onClose: () => _goTab(0)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(ThemeData theme, FeatureStrings f) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.55),
        border: Border(bottom: BorderSide(color: AppColors.divider)),
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
}

class _EvolutionSection extends StatelessWidget {
  const _EvolutionSection({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = context.watch<SettingsProvider>().value.languageCode;
    final f = FeatureStrings.of(lang);

    return Column(
      children: [
        Material(
          color: theme.colorScheme.surface.withValues(alpha: 0.2),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                segments: [
                  ButtonSegment(
                    value: 0,
                    icon: const Icon(Icons.local_florist_outlined),
                    label: Text(f.healthHubEvolutionHabits),
                  ),
                  ButtonSegment(
                    value: 1,
                    icon: const Icon(Icons.insights_outlined),
                    label: Text(f.healthHubTabScreen),
                  ),
                ],
                selected: {index},
                onSelectionChanged: (selection) => onChanged(selection.first),
              ),
            ),
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: index,
            children: [
              ProgressScreen(onClose: () {}, embedded: true),
              DashboardScreen(
                onClose: () {},
                embedded: true,
                initialTab: 1,
                showTabs: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
