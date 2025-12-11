import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../providers/patient_providers.dart';
import 'add_patient_screen.dart';

class PatientListScreen extends ConsumerWidget {
  const PatientListScreen({super.key});

  static const routeName = '/patients';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final patientsAsync = ref.watch(patientListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('patients_title')),
      ),
      body: patientsAsync.when(
        data: (patients) {
          if (patients.isEmpty) {
            return Center(child: Text(loc.translate('no_patients')));
          }
          return ListView.builder(
            itemCount: patients.length,
            itemBuilder: (context, index) {
              final p = patients[index];
              return ListTile(
                title: Text(p.name),
                subtitle: p.pronouns != null ? Text(p.pronouns!) : null,
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).pushNamed(
                    '/patient-details',
                    arguments: p,
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pushNamed(AddPatientScreen.routeName),
        child: const Icon(Icons.add),
      ),
    );
  }
}
