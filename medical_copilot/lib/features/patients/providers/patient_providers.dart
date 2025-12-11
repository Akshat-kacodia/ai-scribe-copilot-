import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/patient.dart';
import '../../../core/providers/app_providers.dart';

final patientListProvider = FutureProvider<List<Patient>>((ref) async {
  final api = await ref.watch(apiClientProvider.future);
  final userIdAsync = await ref.watch(userIdProvider.future);
  
  if (userIdAsync == null) return [];
  return api.getPatients(userId: userIdAsync);
});

class AddPatientController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> addPatient(String name) async {
    state = const AsyncLoading();
    final api = await ref.read(apiClientProvider.future);
    final userIdAsync = await ref.read(userIdProvider.future);
    
    if (userIdAsync == null) {
      state = AsyncError('User ID not available. Please set your email in settings.', StackTrace.current);
      return;
    }
    
    state = await AsyncValue.guard(() async {
      await api.createPatient(name: name, userId: userIdAsync);
    });
    // Refresh list after successful creation
    ref.invalidate(patientListProvider);
  }
}

final addPatientControllerProvider =
    AsyncNotifierProvider<AddPatientController, void>(AddPatientController.new);

class UpdatePatientController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> updatePatient(String patientId, Map<String, dynamic> data) async {
    state = const AsyncLoading();
    final api = await ref.read(apiClientProvider.future);
    
    state = await AsyncValue.guard(() async {
      await api.updatePatient(patientId: patientId, data: data);
    });
    
    // Refresh relevant providers
    ref.invalidate(patientListProvider);
  }
}

final updatePatientControllerProvider =
    AsyncNotifierProvider<UpdatePatientController, void>(UpdatePatientController.new);