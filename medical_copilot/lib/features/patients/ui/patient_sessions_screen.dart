import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/models/patient.dart';
import '../../../core/models/patient_sessions.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/app_providers.dart';
import '../widgets/audio_player_widget.dart';

class PatientSessionsScreen extends ConsumerWidget {
  const PatientSessionsScreen({super.key, required this.patient});

  static const routeName = '/patient-sessions';
  final Patient patient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final userIdAsync = ref.watch(userIdProvider);
    final apiAsync = ref.watch(apiClientProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('${loc.translate('patient_sessions')} - ${patient.name}'),
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
              return FutureBuilder<List<AllSessionItem>>(
                future: _fetchSessions(api, userId, patient.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final sessions = snapshot.data ?? [];
                  if (sessions.isEmpty) {
                    return Center(child: Text(loc.translate('no_sessions')));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
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
                                        if (session.date != null)
                                          Text(
                                            '${loc.translate('session_date')}: ${session.date}',
                                            style: Theme.of(context).textTheme.bodySmall,
                                          ),
                                        if (session.startTime != null)
                                          Text(
                                            'Started: ${_formatTime(session.startTime!)}',
                                            style: Theme.of(context).textTheme.bodySmall,
                                          ),
                                        if (session.startTime != null && session.endTime != null)
                                          Text(
                                            '${loc.translate('duration')}: ${_calculateDuration(session.startTime!, session.endTime!)}',
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
                              if (session.transcript != null &&
                                  session.transcript!.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                ExpansionTile(
                                  title: Text(loc.translate('transcript')),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Text(
                                        session.transcript!,
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
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

  Future<List<AllSessionItem>> _fetchSessions(
    ApiClient api,
    String userId,
    String patientId,
  ) async {
    final response = await api.getAllSessions(userId: userId);
    return response.sessions
        .where((s) => s.patientId == patientId)
        .toList()
      ..sort((a, b) {
        // Sort by date descending (newest first)
        final dateA = a.date ?? '';
        final dateB = b.date ?? '';
        return dateB.compareTo(dateA);
      });
  }

  String _formatTime(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoString;
    }
  }

  String _calculateDuration(String startTime, String endTime) {
    try {
      final start = DateTime.parse(startTime);
      final end = DateTime.parse(endTime);
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
}

