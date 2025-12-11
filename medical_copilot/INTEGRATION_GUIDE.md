# Medical Copilot - Integration Guide

## Overview

This document describes the complete integration between the Flutter frontend (`medical_copilot`) and the backend API. The application has been fully configured to work with the production backend endpoints as specified in the API documentation.

## Backend Configuration

### API Endpoints

The application is configured to use the following backend URLs:

- **Base URL**: `https://app.scribehealth.ai/api`
- **Backend URL** (for user ID resolution): `https://medinote-backend-staging-616605604904.us-central1.run.app/api`

These URLs are configured in `lib/core/network/dio_client.dart` and can be overridden via SharedPreferences for local development.

### Backend Implementation

The backend (`backend/` directory) is a mock implementation that matches all API endpoints from the Postman collection:

- ✅ Patient Management (GET, POST)
- ✅ Patient Details (GET)
- ✅ Sessions (GET by patient, GET all)
- ✅ Templates (GET)
- ✅ Session Creation (POST)
- ✅ Presigned URL Generation (POST)
- ✅ Chunk Upload Notification (POST)

## Frontend Configuration

### Authentication

1. **Auth Token**: Set in Settings screen
   - Navigate to Settings → Enter your Bearer token
   - Token is stored in SharedPreferences and automatically included in all API requests

2. **User Email**: Set in Settings screen
   - Navigate to Settings → Enter your email address
   - The app automatically resolves your User ID from the email using the `/users/asd3fd2faec` endpoint

### Key Features Implemented

1. **Patient Management**
   - View list of patients
   - Add new patients
   - Patient selection in recording screen

2. **Template Management**
   - Fetch templates for the user
   - Template selection in recording screen

3. **Recording Session**
   - Start/stop/pause recording
   - Real-time audio chunking and upload
   - Background upload queue with retry logic
   - Session metadata tracking

4. **Settings**
   - Theme selection (Light/Dark/System)
   - Language selection (English/Hindi)
   - Auth token configuration
   - User email configuration

## Usage Instructions

### Initial Setup

1. **Configure Authentication**
   - Open the app
   - Navigate to Settings (gear icon)
   - Enter your Auth Token (Bearer token)
   - Enter your User Email
   - The app will automatically resolve your User ID

2. **Add Patients**
   - Navigate to Patients screen (people icon)
   - Tap the "+" button
   - Enter patient name
   - Save

3. **Start Recording**
   - Navigate to Recording screen (home)
   - Select a Patient from the dropdown
   - Select a Template from the dropdown
   - Tap "Start Recording"
   - Recording will automatically chunk and upload audio

### Recording Flow

1. User selects Patient and Template
2. User taps "Start Recording"
3. App creates a session via `/v1/upload-session`
4. Audio is recorded in ~1 second chunks
5. For each chunk:
   - Get presigned URL via `/v1/get-presigned-url`
   - Upload chunk to GCS via PUT request
   - Notify backend via `/v1/notify-chunk-uploaded`
6. When recording stops, last chunk is marked as `isLast: true`

### Offline Support

- Chunks are queued locally if network is unavailable
- Chunks automatically upload when connectivity is restored
- Queue persists across app restarts

## Code Structure

### Key Files

- `lib/core/network/dio_client.dart` - HTTP client configuration
- `lib/core/network/api_client.dart` - API endpoint implementations
- `lib/core/providers/app_providers.dart` - Global providers (auth, API client, userId)
- `lib/features/recording/providers/recording_providers.dart` - Patient/template selection
- `lib/features/audio_streaming/providers/audio_providers.dart` - Recording controller
- `lib/features/audio_streaming/services/chunk_uploader.dart` - Chunk upload logic

### Provider Architecture

- `authTokenProvider` - Stores auth token
- `userEmailProvider` - Stores user email
- `userIdProvider` - Resolves userId from email (async)
- `apiClientProvider` - API client instance
- `patientListProvider` - List of patients for user
- `templatesProvider` - List of templates for user
- `selectedPatientProvider` - Currently selected patient
- `selectedTemplateProvider` - Currently selected template
- `recordingControllerProvider` - Recording state management

## Testing

### Local Backend

To test with the local mock backend:

1. Start the backend:
   ```bash
   cd backend
   npm install
   npm run dev
   ```

2. Update SharedPreferences in the app:
   - `api_base_url`: `http://10.0.2.2:3000/api` (Android emulator)
   - `backend_base_url`: `http://10.0.2.2:3000/api`

### Production Backend

The app is configured to use production endpoints by default. Ensure:
- Auth token is valid
- User email exists in the backend system
- Network connectivity is available

## Troubleshooting

### "User ID not available"
- Check that email is set in Settings
- Verify email exists in backend system
- Check network connectivity

### "Please select a patient/template"
- Ensure patient is selected before starting recording
- Ensure template is selected before starting recording

### Chunks not uploading
- Check network connectivity
- Verify auth token is valid
- Check app logs for error messages

## Next Steps

For production deployment:

1. Replace mock backend with real implementation
2. Implement actual GCS presigned URL generation
3. Add error handling and retry logic improvements
4. Add session recovery for interrupted recordings
5. Implement proper authentication flow (OAuth, etc.)

