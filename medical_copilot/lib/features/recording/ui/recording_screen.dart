import 'dart:async';
import 'dart:io'; // Needed for Platform check

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart'; // Add this import
import 'package:share_plus/share_plus.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/native/audio_native_channel.dart';
import '../../audio_streaming/providers/audio_providers.dart';
import '../../patients/ui/patient_list_screen.dart';
import '../../patients/providers/patient_providers.dart';
import '../../sessions/ui/all_sessions_screen.dart';
import '../../settings/ui/settings_screen.dart';
import '../../background/ui/background_debug_screen.dart';
import '../providers/recording_providers.dart';

class RecordingScreen extends ConsumerStatefulWidget {
  const RecordingScreen({super.key});

  static const routeName = '/recording';

  @override
  ConsumerState<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends ConsumerState<RecordingScreen> {
  StreamSubscription<String>? _interruptionSub;

  @override
  void initState() {
    super.initState();
    _interruptionSub =
        AudioNativeChannel.instance.interruptionStream.listen((reason) async {
      if (!mounted) return;
      try {
        final controller = ref.read(recordingControllerProvider.notifier);
        if (reason == 'pause') {
          await controller.pause();
        } else if (reason == 'resume') {
          await controller.resume();
        }
      } catch (e) {
        debugPrint('Error handling interruption: $e');
      }
    }, onError: (error) {
      debugPrint('Interruption stream error: $error');
    });
  }

  @override
  void dispose() {
    _interruptionSub?.cancel();
    super.dispose();
  }

  Future<void> _capturePatientId() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(AppLocalizations.of(context).translate('capture_patient_id')),
      ),
    );
  }

  Future<void> _startRecording() async {
    try {
      HapticFeedback.mediumImpact();

      // NEW: Explicitly request Notification permission for Android 13+
      if (Platform.isAndroid) {
        final status = await Permission.notification.status;
        if (status.isDenied) {
          final result = await Permission.notification.request();
          if (result.isDenied) {
            // If user denies, we can still record, but they won't see the notification
            debugPrint("Notification permission denied");
          }
        }
      }

      // Start recording session (does mic permission check and prompts user)
      await ref.read(recordingControllerProvider.notifier).startNewSession();

      // Start the foreground service notification
      try {
        await AudioNativeChannel.instance.startForegroundService();
      } catch (e) {
        debugPrint("Failed to start foreground service: $e");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Warning: Background service failed ($e). Recording might stop if app is minimized.'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recording started'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      String errorMessage = 'Failed to start recording: ';
      if (e.toString().contains('permission')) {
        errorMessage = 'Microphone permission denied. Please grant microphone permission in app settings.';
      } else if (e.toString().contains('User ID')) {
        errorMessage = 'User ID not available. Please configure your email in settings.';
      } else if (e.toString().contains('patient')) {
        errorMessage = 'Please select a patient before starting recording.';
      } else if (e.toString().contains('template')) {
        errorMessage = 'Please select a template before starting recording.';
      } else {
        errorMessage += e.toString().replaceAll('Exception: ', '');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final status = ref.watch(recordingControllerProvider);
    final micLevelAsync = ref.watch(micLevelProvider);
    final patientsAsync = ref.watch(patientListProvider);
    final templatesAsync = ref.watch(templatesProvider);
    final selectedPatient = ref.watch(selectedPatientProvider);
    final selectedTemplate = ref.watch(selectedTemplateProvider);

    ref.watch(chunkUploaderProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('recording_title')),
        actions: [
          IconButton(
            tooltip: loc.translate('capture_patient_id'),
            icon: const Icon(Icons.badge_outlined),
            onPressed: _capturePatientId,
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'All Sessions',
            onPressed: () =>
                Navigator.of(context).pushNamed(AllSessionsScreen.routeName),
          ),
          IconButton(
            icon: const Icon(Icons.people_outline),
            onPressed: () =>
                Navigator.of(context).pushNamed(PatientListScreen.routeName),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () =>
                Navigator.of(context).pushNamed(SettingsScreen.routeName),
          ),
          IconButton(
            icon: const Icon(Icons.miscellaneous_services_outlined),
            onPressed: () => Navigator.of(context)
                .pushNamed(BackgroundDebugScreen.routeName),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                status == RecordingStatus.recording
                    ? loc.translate('session_status_active')
                    : loc.translate('session_status_idle'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              // Patient Selection
              Text('Select Patient', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              patientsAsync.when(
                data: (patients) {
                  if (patients.isEmpty) {
                    return OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pushNamed(PatientListScreen.routeName),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Patient'),
                    );
                  }
                  return DropdownButtonFormField<String>(
                    value: selectedPatient?.id,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Select a patient',
                    ),
                    items: patients.map((patient) {
                      return DropdownMenuItem<String>(
                        value: patient.id,
                        child: Text(patient.name),
                      );
                    }).toList(),
                    onChanged: (patientId) {
                      if (patientId != null) {
                        final patient = patients.firstWhere((p) => p.id == patientId);
                        ref.read(selectedPatientProvider.notifier).state = patient;
                      }
                    },
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error loading patients: $e', style: const TextStyle(color: Colors.red)),
              ),
              const SizedBox(height: 16),
              // Template Selection
              Text('Select Template', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              templatesAsync.when(
                data: (templates) {
                  if (templates.isEmpty) {
                    return const Text('No templates available', style: TextStyle(color: Colors.grey));
                  }
                  return DropdownButtonFormField<String>(
                    value: selectedTemplate?.id,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Select a template',
                    ),
                    items: templates.map((template) {
                      return DropdownMenuItem<String>(
                        value: template.id,
                        child: Text(template.title),
                      );
                    }).toList(),
                    onChanged: (templateId) {
                      if (templateId != null) {
                        final template = templates.firstWhere((t) => t.id == templateId);
                        ref.read(selectedTemplateProvider.notifier).state = template;
                      }
                    },
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error loading templates: $e', style: const TextStyle(color: Colors.red)),
              ),
              const SizedBox(height: 16),
            Text(loc.translate('gain')),
            Consumer(
              builder: (context, ref, _) {
                final gainValue = ref.watch(gainProvider);
                return Slider(
                  value: gainValue,
                  onChanged: (value) {
                    ref.read(gainProvider.notifier).state = value;
                    ref
                        .read(recordingControllerProvider.notifier)
                        .setGain(value);
                    AudioNativeChannel.instance.setGain(value);
                  },
                  min: 0.5,
                  max: 3.0,
                );
              },
            ),
            const SizedBox(height: 16),
            Text(loc.translate('recording_title')),
            const SizedBox(height: 8),
            micLevelAsync.when(
              data: (level) => LinearProgressIndicator(value: level),
              loading: () => const LinearProgressIndicator(value: 0.0),
              error: (_, __) => const LinearProgressIndicator(value: 0.0),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: (selectedPatient == null || selectedTemplate == null)
                      ? null
                      : _startRecording,
                  icon: const Icon(Icons.fiber_manual_record),
                  label: Text(loc.translate('start_recording')),
                ),
                ElevatedButton.icon(
                  onPressed: status == RecordingStatus.recording
                      ? () async {
                          HapticFeedback.lightImpact();
                          await ref
                              .read(recordingControllerProvider.notifier)
                              .pause();
                        }
                      : status == RecordingStatus.paused
                          ? () async {
                              HapticFeedback.lightImpact();
                              await ref
                                  .read(recordingControllerProvider.notifier)
                                  .resume();
                            }
                          : null,
                  icon: Icon(status == RecordingStatus.recording
                      ? Icons.pause
                      : Icons.play_arrow),
                  label: Text(
                    status == RecordingStatus.recording
                        ? loc.translate('pause_recording')
                        : loc.translate('resume_recording'),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    HapticFeedback.heavyImpact();
                    await ref
                        .read(recordingControllerProvider.notifier)
                        .stop();
                    await AudioNativeChannel.instance.stopForegroundService();
                  },
                  icon: const Icon(Icons.stop),
                  label: Text(loc.translate('stop_recording')),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  await Share.share('Recording session metadata shared.');
                },
                icon: const Icon(Icons.share),
                label: Text(loc.translate('share_recording')),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}