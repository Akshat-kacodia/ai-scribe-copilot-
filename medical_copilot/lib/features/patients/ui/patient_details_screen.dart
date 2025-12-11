import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/models/patient.dart';
import '../../../core/models/patient_details.dart';
import '../../../core/providers/app_providers.dart';
import 'edit_patient_screen.dart';
import 'patient_sessions_screen.dart';

class PatientDetailsScreen extends ConsumerStatefulWidget {
  const PatientDetailsScreen({super.key, required this.patient});

  static const routeName = '/patient-details';
  final Patient patient;

  @override
  ConsumerState<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends ConsumerState<PatientDetailsScreen> {
  // To trigger rebuilds/refetches manually if needed
  int _refreshKey = 0;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final apiAsync = ref.watch(apiClientProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.patient.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: loc.translate('view_sessions'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PatientSessionsScreen(patient: widget.patient),
                ),
              );
            },
          ),
        ],
      ),
      body: apiAsync.when(
        data: (api) {
          return FutureBuilder<PatientDetails>(
            // Use _refreshKey to force FutureBuilder to run again when needed
            key: ValueKey(_refreshKey),
            future: api.getPatientDetails(widget.patient.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final details = snapshot.data;
              if (details == null) {
                return Center(child: Text('Patient details not found'));
              }

              // We now have details, update the AppBar with the Edit button
              // that needs these details to pre-fill the form
              WidgetsBinding.instance.addPostFrameCallback((_) {
                 // Note: Updating UI during build is unsafe, but here we just need
                 // the Edit button to be available. Since we can't easily update
                 // the parent Scaffold AppBar from here, we can use a FloatingActionButton
                 // or wrap the Scaffold content better. 
                 // Better approach: Move AppBar actions logic here or just pass patientId to edit 
                 // and fetch again, but passing details is better UX.
              });

              return Scaffold(
                // Nested scaffold to add the FAB or specific actions
                backgroundColor: Colors.transparent,
                floatingActionButton: FloatingActionButton(
                  onPressed: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EditPatientScreen(
                          patientDetails: details,
                          patientId: widget.patient.id,
                        ),
                      ),
                    );
                    
                    if (result == true) {
                      setState(() {
                        _refreshKey++;
                      });
                    }
                  },
                  child: const Icon(Icons.edit),
                ),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Info Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                details.name,
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              if (details.pronouns != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  details.pronouns!,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                ),
                              ],
                              if (details.email != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.email, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      details.email!,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Background
                      if (details.background != null && details.background!.isNotEmpty)
                        _buildSection(
                          context,
                          loc,
                          loc.translate('background'),
                          details.background!,
                          Icons.info_outline,
                        ),
                      // Medical History
                      if (details.medicalHistory != null && details.medicalHistory!.isNotEmpty)
                        _buildSection(
                          context,
                          loc,
                          loc.translate('medical_history'),
                          details.medicalHistory!,
                          Icons.medical_services_outlined,
                        ),
                      // Family History
                      if (details.familyHistory != null && details.familyHistory!.isNotEmpty)
                        _buildSection(
                          context,
                          loc,
                          loc.translate('family_history'),
                          details.familyHistory!,
                          Icons.family_restroom,
                        ),
                      // Social History
                      if (details.socialHistory != null && details.socialHistory!.isNotEmpty)
                        _buildSection(
                          context,
                          loc,
                          loc.translate('social_history'),
                          details.socialHistory!,
                          Icons.people_outline,
                        ),
                      // Previous Treatment
                      if (details.previousTreatment != null && details.previousTreatment!.isNotEmpty)
                        _buildSection(
                          context,
                          loc,
                          loc.translate('previous_treatment'),
                          details.previousTreatment!,
                          Icons.medication_outlined,
                        ),
                      const SizedBox(height: 16),
                      // View Sessions Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PatientSessionsScreen(patient: widget.patient),
                              ),
                            );
                          },
                          icon: const Icon(Icons.history),
                          label: Text(loc.translate('view_sessions')),
                        ),
                      ),
                      // Space for FAB
                      const SizedBox(height: 72),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    AppLocalizations loc,
    String title,
    String content,
    IconData icon,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: Icon(icon),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}