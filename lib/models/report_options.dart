import 'package:flutter/foundation.dart';

import 'osdi_assessment.dart';
import 'screen_time_data.dart';

@immutable
class UserProfile {
  const UserProfile({
    this.name,
    this.observations,
  });

  final String? name;
  final String? observations;
}

@immutable
class ReportOptions {
  const ReportOptions({
    required this.startDate,
    required this.endDate,
    this.includeOsdi = true,
    this.includeScreenTime = true,
    this.includeBreaks = true,
    this.includeSymptoms = true,
    this.includeEnvironment = true,
  });

  final DateTime startDate;
  final DateTime endDate;
  final bool includeOsdi;
  final bool includeScreenTime;
  final bool includeBreaks;
  final bool includeSymptoms;
  final bool includeEnvironment;
}

/// Agrega os dados necessários para o relatório.
@immutable
class ReportData {
  const ReportData({
    required this.profile,
    required this.options,
    required this.osdiHistory,
    required this.screenTimeData,
    this.latestOsdi,
    this.previousOsdi,
    this.averageScreenTimeSeconds = 0,
    this.totalScreenTimeSeconds = 0,
  });

  final UserProfile profile;
  final ReportOptions options;
  final List<OsdiAssessment> osdiHistory;
  final ScreenTimeData screenTimeData;

  final OsdiAssessment? latestOsdi;
  final OsdiAssessment? previousOsdi;

  final int averageScreenTimeSeconds;
  final int totalScreenTimeSeconds;
}
