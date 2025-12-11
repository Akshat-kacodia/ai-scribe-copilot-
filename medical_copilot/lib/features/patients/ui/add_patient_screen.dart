import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../providers/patient_providers.dart';

class AddPatientScreen extends ConsumerStatefulWidget {
  const AddPatientScreen({super.key});

  static const routeName = '/add-patient';

  @override
  ConsumerState<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends ConsumerState<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final addController = ref.watch(addPatientControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('add_patient_title')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: loc.translate('patient_name'),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: addController.isLoading
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;
                        final navigator = Navigator.of(context);
                        await ref
                            .read(addPatientControllerProvider.notifier)
                            .addPatient(_nameController.text.trim());
                        if (!mounted) return;
                        navigator.pop();
                      },
                child: addController.isLoading
                    ? const CircularProgressIndicator.adaptive()
                    : Text(loc.translate('save')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
