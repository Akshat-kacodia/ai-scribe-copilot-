import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/patient.dart';
import '../../../core/models/template_model.dart';
import '../../../core/providers/app_providers.dart';

/// Provider for fetching templates
final templatesProvider = FutureProvider<List<TemplateModel>>((ref) async {
  final api = await ref.watch(apiClientProvider.future);
  final userIdAsync = await ref.watch(userIdProvider.future);
  
  if (userIdAsync == null) return [];
  return api.getTemplates(userId: userIdAsync);
});

/// Provider for selected patient (can be null if none selected)
final selectedPatientProvider = StateProvider<Patient?>((ref) => null);

/// Provider for selected template (can be null if none selected)
final selectedTemplateProvider = StateProvider<TemplateModel?>((ref) => null);

