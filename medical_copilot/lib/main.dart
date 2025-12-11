import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/localization/app_localizations.dart';
import 'core/models/patient.dart';
import 'core/providers/app_providers.dart';
import 'core/theme/app_theme.dart';
import 'features/background/ui/background_debug_screen.dart';
import 'features/patients/ui/add_patient_screen.dart';
import 'features/patients/ui/patient_details_screen.dart';
import 'features/patients/ui/patient_list_screen.dart';
import 'features/recording/ui/recording_screen.dart';
import 'features/sessions/ui/all_sessions_screen.dart';
import 'features/settings/ui/settings_screen.dart';

void main() {
  runApp(const ProviderScope(child: MedicalCopilotApp()));
}

class MedicalCopilotApp extends ConsumerWidget {
  const MedicalCopilotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'Medical Copilot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
      ],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case RecordingScreen.routeName:
          case '/':
            return MaterialPageRoute(
              builder: (_) => const RecordingScreen(),
              settings: settings,
            );
          case PatientListScreen.routeName:
            return MaterialPageRoute(
              builder: (_) => const PatientListScreen(),
              settings: settings,
            );
          case AddPatientScreen.routeName:
            return MaterialPageRoute(
              builder: (_) => const AddPatientScreen(),
              settings: settings,
            );
          case SettingsScreen.routeName:
            return MaterialPageRoute(
              builder: (_) => const SettingsScreen(),
              settings: settings,
            );
          case BackgroundDebugScreen.routeName:
            return MaterialPageRoute(
              builder: (_) => const BackgroundDebugScreen(),
              settings: settings,
            );
          case AllSessionsScreen.routeName:
            return MaterialPageRoute(
              builder: (_) => const AllSessionsScreen(),
              settings: settings,
            );
          case PatientDetailsScreen.routeName:
            final patient = settings.arguments as Patient;
            return MaterialPageRoute(
              builder: (_) => PatientDetailsScreen(patient: patient),
              settings: settings,
            );
          default:
            return MaterialPageRoute(
              builder: (_) => const RecordingScreen(),
              settings: settings,
            );
        }
      },
    );
  }
}
