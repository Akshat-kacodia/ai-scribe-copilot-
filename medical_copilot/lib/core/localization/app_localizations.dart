import 'package:flutter/widgets.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('en'), Locale('hi')];

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'Medical Copilot',
      'recording_title': 'Recording',
      'patients_title': 'Patients',
      'add_patient_title': 'Add Patient',
      'settings_title': 'Settings',
      'background_debug_title': 'Background Service',
      'start_recording': 'Start Recording',
      'pause_recording': 'Pause',
      'resume_recording': 'Resume',
      'stop_recording': 'Stop',
      'gain': 'Gain',
      'session_status_active': 'Session Active',
      'session_status_idle': 'Idle',
      'no_patients': 'No patients yet',
      'add_patient': 'Add Patient',
      'patient_name': 'Patient name',
      'save': 'Save',
      'theme': 'Theme',
      'theme_system': 'System',
      'theme_light': 'Light',
      'theme_dark': 'Dark',
      'language': 'Language',
      'language_english': 'English',
      'language_hindi': 'Hindi',
      'background_service_start': 'Start Foreground Service',
      'background_service_stop': 'Stop Foreground Service',
      'share_recording': 'Share',
      'capture_patient_id': 'Capture patient ID photo',
      'patient_sessions': 'Patient Sessions',
      'no_sessions': 'No recordings found for this patient',
      'play_audio': 'Play Recording',
      'pause_audio': 'Pause',
      'resume_audio': 'Resume',
      'stop_audio': 'Stop',
      'loading_audio': 'Loading...',
      'audio_error': 'Error loading audio',
      'session_date': 'Date',
      'session_title': 'Session',
      'transcript': 'Transcript',
      'view_sessions': 'View Recordings',
      'all_sessions': 'All Sessions',
      'all_recordings': 'All Recordings',
      'no_recordings': 'No recordings found',
      'patient_details': 'Patient Details',
      'medical_history': 'Medical History',
      'family_history': 'Family History',
      'social_history': 'Social History',
      'previous_treatment': 'Previous Treatment',
      'background': 'Background',
      'duration': 'Duration',
      'search_sessions': 'Search sessions...',
      'filter_by_status': 'Filter by Status',
      'filter_by_patient': 'Filter by Patient',
      'all_statuses': 'All Statuses',
      'all_patients': 'All Patients',
      'statistics': 'Statistics',
      'total_sessions': 'Total Sessions',
      'total_duration': 'Total Duration',
      'share_audio': 'Share Audio',
      'download_audio': 'Download Audio',
    },
    'hi': {
      'app_title': 'मेडिकल कोपायलट',
      'recording_title': 'रिकॉर्डिंग',
      'patients_title': 'रोगी',
      'add_patient_title': 'रोगी जोड़ें',
      'settings_title': 'सेटिंग्स',
      'background_debug_title': 'पृष्ठभूमि सेवा',
      'start_recording': 'रिकॉर्डिंग शुरू करें',
      'pause_recording': 'रोकें',
      'resume_recording': 'फिर से शुरू करें',
      'stop_recording': 'बंद करें',
      'gain': 'गेन',
      'session_status_active': 'सत्र सक्रिय',
      'session_status_idle': 'निष्क्रिय',
      'no_patients': 'अभी कोई रोगी नहीं',
      'add_patient': 'रोगी जोड़ें',
      'patient_name': 'रोगी का नाम',
      'save': 'सेव करें',
      'theme': 'थीम',
      'theme_system': 'सिस्टम',
      'theme_light': 'हल्का',
      'theme_dark': 'गहरा',
      'language': 'भाषा',
      'language_english': 'अंग्रेजी',
      'language_hindi': 'हिंदी',
      'background_service_start': 'फोरग्राउंड सेवा शुरू करें',
      'background_service_stop': 'फोरग्राउंड सेवा बंद करें',
      'share_recording': 'शेयर करें',
      'capture_patient_id': 'रोगी की फोटो कैप्चर करें',
      'patient_sessions': 'रोगी सत्र',
      'no_sessions': 'इस रोगी के लिए कोई रिकॉर्डिंग नहीं मिली',
      'play_audio': 'रिकॉर्डिंग चलाएं',
      'pause_audio': 'रोकें',
      'resume_audio': 'फिर से शुरू करें',
      'stop_audio': 'बंद करें',
      'loading_audio': 'लोड हो रहा है...',
      'audio_error': 'ऑडियो लोड करने में त्रुटि',
      'session_date': 'तारीख',
      'session_title': 'सत्र',
      'transcript': 'ट्रांसक्रिप्ट',
      'view_sessions': 'रिकॉर्डिंग देखें',
      'all_sessions': 'सभी सत्र',
      'all_recordings': 'सभी रिकॉर्डिंग',
      'no_recordings': 'कोई रिकॉर्डिंग नहीं मिली',
      'patient_details': 'रोगी विवरण',
      'medical_history': 'चिकित्सा इतिहास',
      'family_history': 'पारिवारिक इतिहास',
      'social_history': 'सामाजिक इतिहास',
      'previous_treatment': 'पिछला उपचार',
      'background': 'पृष्ठभूमि',
      'duration': 'अवधि',
      'search_sessions': 'सत्र खोजें...',
      'filter_by_status': 'स्थिति से फ़िल्टर करें',
      'filter_by_patient': 'रोगी से फ़िल्टर करें',
      'all_statuses': 'सभी स्थितियां',
      'all_patients': 'सभी रोगी',
      'statistics': 'आंकड़े',
      'total_sessions': 'कुल सत्र',
      'total_duration': 'कुल अवधि',
      'share_audio': 'ऑडियो साझा करें',
      'download_audio': 'ऑडियो डाउनलोड करें',
    },
  };

  String translate(String key) {
    final lang = locale.languageCode;
    return _localizedValues[lang]?[key] ?? _localizedValues['en']?[key] ?? key;
  }

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.contains(Locale(locale.languageCode));

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}
