import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/models/patient.dart';
import '../../../core/models/patient_sessions.dart';
import '../../../core/providers/app_providers.dart';
import '../../patients/ui/patient_sessions_screen.dart';
import '../../patients/widgets/audio_player_widget.dart';

class AllSessionsScreen extends ConsumerStatefulWidget {
  const AllSessionsScreen({super.key});

  static const routeName = '/all-sessions';

  @override
  ConsumerState<AllSessionsScreen> createState() => _AllSessionsScreenState();
}

class _AllSessionsScreenState extends ConsumerState<AllSessionsScreen> {
  String _searchQuery = '';
  String? _selectedStatus;
  String? _selectedPatientId;
  List<String> _availableStatuses = [];
  List<String> _availablePatientIds = [];
  Map<String, String> _patientNames = {};

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final userIdAsync = ref.watch(userIdProvider);
    final apiAsync = ref.watch(apiClientProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('all_sessions')),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context, loc),
          ),
        ],
      ),
      body: userIdAsync.when(
        data: (userId) {
          if (userId == null) {
            return Center(
              child: Text('User ID not available. Please set your email in settings.'),
            );
          }
          return apiAsync.when(
            data: (api) {
              return FutureBuilder<AllSessionsResponse>(
                future: api.getAllSessions(userId: userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final response = snapshot.data;
                  if (response == null || response.sessions.isEmpty) {
                    return Center(child: Text(loc.translate('no_recordings')));
                  }

                  // Update available filters
                  if (_availableStatuses.isEmpty) {
                    _availableStatuses = response.sessions
                        .map((s) => s.status ?? 'unknown')
                        .toSet()
                        .toList();
                    _availablePatientIds = response.sessions
                        .map((s) => s.patientId ?? '')
                        .where((id) => id.isNotEmpty)
                        .toSet()
                        .toList();
                    _patientNames = response.patientMap.map(
                      (key, value) => MapEntry(key, value.name),
                    );
                  }

                  // Filter sessions
                  var filteredSessions = response.sessions.where((session) {
                    // Search filter
                    if (_searchQuery.isNotEmpty) {
                      final query = _searchQuery.toLowerCase();
                      final matchesSearch = 
                          (session.patientName?.toLowerCase().contains(query) ?? false) ||
                          (session.sessionTitle?.toLowerCase().contains(query) ?? false) ||
                          (session.sessionSummary?.toLowerCase().contains(query) ?? false);
                      if (!matchesSearch) return false;
                    }

                    // Status filter
                    if (_selectedStatus != null && _selectedStatus!.isNotEmpty) {
                      if (session.status != _selectedStatus) return false;
                    }

                    // Patient filter
                    if (_selectedPatientId != null && _selectedPatientId!.isNotEmpty) {
                      if (session.patientId != _selectedPatientId) return false;
                    }

                    return true;
                  }).toList();

                  // Sort by date descending (newest first)
                  filteredSessions.sort((a, b) {
                    final dateA = a.date ?? '';
                    final dateB = b.date ?? '';
                    if (dateA != dateB) return dateB.compareTo(dateA);
                    final timeA = a.startTime ?? '';
                    final timeB = b.startTime ?? '';
                    return timeB.compareTo(timeA);
                  });

                  // Calculate statistics
                  final totalSessions = filteredSessions.length;
                  final totalDuration = _calculateTotalDuration(filteredSessions);

                  return Column(
                    children: [
                      // Search bar
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: loc.translate('search_sessions'),
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                      // Statistics
                      if (totalSessions > 0)
                        Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      totalSessions.toString(),
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Text(loc.translate('total_sessions')),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text(
                                      _formatDuration(totalDuration),
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Text(loc.translate('total_duration')),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      // Sessions list
                      Expanded(
                        child: filteredSessions.isEmpty
                            ? Center(child: Text(loc.translate('no_recordings')))
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: filteredSessions.length,
                                itemBuilder: (context, index) {
                                  final session = filteredSessions[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    child: InkWell(
                                      onTap: () {
                                        // Navigate to patient sessions if patient exists
                                        if (session.patientId != null) {
                                          final patient = response.patientMap[session.patientId!];
                                          if (patient != null) {
                                            // Navigate to patient sessions
                                            final patientMapEntry = response.patientMap[session.patientId!];
                                            if (patientMapEntry != null) {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) => PatientSessionsScreen(
                                                    patient: Patient(
                                                      id: session.patientId!,
                                                      name: session.patientName ?? patientMapEntry.name,
                                                      pronouns: patientMapEntry.pronouns,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        session.sessionTitle ?? 'Session',
                                                        style: Theme.of(context).textTheme.titleMedium,
                                                      ),
                                                      const SizedBox(height: 4),
                                                      if (session.patientName != null)
                                                        Text(
                                                          'Patient: ${session.patientName}',
                                                          style: Theme.of(context).textTheme.bodySmall,
                                                        ),
                                                      if (session.date != null)
                                                        Text(
                                                          '${loc.translate('session_date')}: ${session.date}',
                                                          style: Theme.of(context).textTheme.bodySmall,
                                                        ),
                                                      if (session.startTime != null && session.endTime != null)
                                                        Text(
                                                          '${loc.translate('duration')}: ${_calculateSessionDuration(session)}',
                                                          style: Theme.of(context).textTheme.bodySmall,
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                if (session.status != null)
                                                  Chip(
                                                    label: Text(session.status!),
                                    backgroundColor: session.status == 'completed'
                                        ? Colors.green.withValues(alpha: 0.2)
                                        : Colors.orange.withValues(alpha: 0.2),
                                                  ),
                                              ],
                                            ),
                                            if (session.sessionSummary != null &&
                                                session.sessionSummary!.isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              Text(
                                                session.sessionSummary!,
                                                style: Theme.of(context).textTheme.bodyMedium,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                            if (session.audioUrl != null) ...[
                                              const SizedBox(height: 16),
                                              AudioPlayerWidget(audioUrl: session.audioUrl!),
                                              const SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  TextButton.icon(
                                                    onPressed: () async {
                                                      await Share.share(
                                                        session.audioUrl!,
                                                        subject: 'Recording: ${session.sessionTitle ?? "Session"}',
                                                      );
                                                    },
                                                    icon: const Icon(Icons.share),
                                                    label: Text(loc.translate('share_audio')),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showFilterDialog(BuildContext context, AppLocalizations loc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.translate('filter_by_status')),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status filter
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: loc.translate('filter_by_status'),
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text(loc.translate('all_statuses')),
                    ),
                    ..._availableStatuses.map((status) => DropdownMenuItem<String>(
                          value: status,
                          child: Text(status),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Patient filter
                DropdownButtonFormField<String>(
                  value: _selectedPatientId,
                  decoration: InputDecoration(
                    labelText: loc.translate('filter_by_patient'),
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text(loc.translate('all_patients')),
                    ),
                    ..._availablePatientIds.map((patientId) => DropdownMenuItem<String>(
                          value: patientId,
                          child: Text(_patientNames[patientId] ?? patientId),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedPatientId = value;
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedStatus = null;
                _selectedPatientId = null;
              });
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.translate('save')),
          ),
        ],
      ),
    ).then((_) {
      setState(() {});
    });
  }

  Duration _calculateTotalDuration(List<AllSessionItem> sessions) {
    Duration total = Duration.zero;
    for (final session in sessions) {
      if (session.startTime != null && session.endTime != null) {
        try {
          final start = DateTime.parse(session.startTime!);
          final end = DateTime.parse(session.endTime!);
          total += end.difference(start);
        } catch (e) {
          // Ignore parse errors
        }
      }
    }
    return total;
  }

  String _calculateSessionDuration(AllSessionItem session) {
    if (session.startTime == null || session.endTime == null) {
      return 'Unknown';
    }
    try {
      final start = DateTime.parse(session.startTime!);
      final end = DateTime.parse(session.endTime!);
      final duration = end.difference(start);
      if (duration.inHours > 0) {
        return '${duration.inHours}h ${duration.inMinutes % 60}m';
      } else {
        return '${duration.inMinutes}m';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }
}

