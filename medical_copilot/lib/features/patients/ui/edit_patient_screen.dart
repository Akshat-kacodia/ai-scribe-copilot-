import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/models/patient_details.dart';
import '../providers/patient_providers.dart';

class EditPatientScreen extends ConsumerStatefulWidget {
  const EditPatientScreen({super.key, required this.patientDetails, required this.patientId});

  final PatientDetails patientDetails;
  final String patientId;

  @override
  ConsumerState<EditPatientScreen> createState() => _EditPatientScreenState();
}

class _EditPatientScreenState extends ConsumerState<EditPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _pronounsController;
  late TextEditingController _emailController;
  late TextEditingController _backgroundController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.patientDetails.name);
    _pronounsController = TextEditingController(text: widget.patientDetails.pronouns ?? '');
    _emailController = TextEditingController(text: widget.patientDetails.email ?? '');
    _backgroundController = TextEditingController(text: widget.patientDetails.background ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pronounsController.dispose();
    _emailController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final updateController = ref.watch(updatePatientControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Patient'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: loc.translate('patient_name'),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _pronounsController,
                  decoration: const InputDecoration(
                    labelText: 'Pronouns',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _backgroundController,
                  decoration: InputDecoration(
                    labelText: loc.translate('background'),
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: updateController.isLoading
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
                            
                            final navigator = Navigator.of(context);
                            final data = {
                              'name': _nameController.text.trim(),
                              'email': _emailController.text.trim(),
                              'pronouns': _pronounsController.text.trim(),
                              'background': _backgroundController.text.trim(),
                            };

                            await ref
                                .read(updatePatientControllerProvider.notifier)
                                .updatePatient(widget.patientId, data);
                            
                            if (!mounted) return;
                            navigator.pop(true); // Return true to indicate update happened
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: updateController.isLoading
                        ? const CircularProgressIndicator.adaptive()
                        : Text(loc.translate('save')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}