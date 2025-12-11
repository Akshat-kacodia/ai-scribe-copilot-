# Medical Copilot - Setup Guide

## Overview

This project consists of:
1. **Flutter Frontend** (`medical_copilot/`) - Mobile app
2. **Mock Backend** (`backend/`) - API server that you need to deploy

The URLs in the API documentation are **reference examples only**. You need to deploy your own backend.

## Quick Start

### Step 1: Start the Backend Locally

```bash
# Navigate to backend directory
cd backend

# Install dependencies
npm install

# Start the server (runs on http://localhost:3000)
npm run dev
```

The backend will start on `http://localhost:3000`

### Step 2: Configure the Flutter App

1. **Run the Flutter app** (Android emulator or iOS simulator)

2. **Open Settings** (gear icon in the app)

3. **Configure Backend URLs** (optional - defaults to localhost):
   - **API Base URL**: Leave empty for localhost, or enter your deployed backend URL
   - **Backend Base URL**: Leave empty to use API Base URL, or enter custom URL

4. **Set Auth Token**: 
   - Enter any token (e.g., `test-token-123`)
   - The mock backend accepts any Bearer token

5. **Set User Email**:
   - Enter `user@example.com` (this user exists in the mock backend)
   - The app will automatically resolve your User ID

### Step 3: Test the App

1. **Add a Patient**:
   - Go to Patients screen → Tap "+" → Enter name → Save

2. **Start Recording**:
   - Select a Patient from dropdown
   - Select a Template from dropdown  
   - Tap "Start Recording"
   - Audio chunks will upload automatically

## Deploying the Backend

### Option 1: Docker (Recommended)

```bash
# Build and run with Docker Compose
docker-compose up --build

# Or build manually
docker build -t medical-copilot-backend ./backend
docker run -p 3000:3000 medical-copilot-backend
```

### Option 2: Google Cloud Run

```bash
# Build and deploy
gcloud builds submit --tag gcr.io/YOUR_PROJECT_ID/medical-copilot-backend ./backend
gcloud run deploy medical-copilot-backend \
  --image gcr.io/YOUR_PROJECT_ID/medical-copilot-backend \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 3000

# Get the URL
gcloud run services describe medical-copilot-backend --region us-central1 --format 'value(status.url)'
```

### Option 3: Other Platforms

- **Heroku**: `git push heroku main` (if configured)
- **Railway**: Connect GitHub repo, auto-deploys
- **Render**: Connect GitHub repo, auto-deploys
- **AWS/Azure**: Use Docker image

See `backend/README.md` for detailed deployment instructions.

## After Deployment

Once your backend is deployed:

1. **Get your backend URL** (e.g., `https://your-backend.run.app`)

2. **Update Flutter App Settings**:
   - Open Settings
   - Set **API Base URL** to: `https://your-backend.run.app/api`
   - Set **Backend Base URL** to: `https://your-backend.run.app/api` (same)
   - Set **Auth Token** to any value
   - Set **User Email** to `user@example.com`

3. **Test the connection**:
   - The User ID should resolve automatically
   - Try adding a patient to verify API connectivity

## Default Configuration

### Local Development (Default)

- **Backend**: `http://localhost:3000/api`
- **Android Emulator**: `http://10.0.2.2:3000/api` (automatically used)
- **iOS Simulator**: `http://localhost:3000/api` (automatically used)
- **Physical Device**: Use your computer's LAN IP (e.g., `http://192.168.1.100:3000/api`)

### Mock Backend Features

- ✅ All API endpoints implemented
- ✅ Accepts any Bearer token
- ✅ In-memory data storage (resets on restart)
- ✅ Mock presigned URLs (not real GCS/S3)
- ✅ Health check endpoint at `/health`

## Troubleshooting

### "Connection refused" or "Network error"

- **Check backend is running**: `curl http://localhost:3000/health`
- **Check URL in Settings**: Should be `http://10.0.2.2:3000/api` for Android emulator
- **For physical device**: Use your computer's LAN IP instead of localhost

### "User ID not resolved"

- Check email is set in Settings
- Check backend is accessible
- Check auth token is set
- Try: `curl -H "Authorization: Bearer test-token" "http://localhost:3000/api/users/asd3fd2faec?email=user@example.com"`

### "Please select a patient/template"

- Make sure you've added at least one patient
- Make sure templates are loading (check network)
- Try refreshing the app

## Next Steps

For production:

1. **Replace mock backend** with real implementation
2. **Add database** (PostgreSQL, MongoDB, etc.)
3. **Implement real authentication** (OAuth, JWT validation)
4. **Add real file storage** (GCS, S3 presigned URLs)
5. **Add error handling and logging**

## Files Changed

- `lib/core/network/dio_client.dart` - Defaults to localhost, configurable via Settings
- `lib/features/settings/ui/settings_screen.dart` - Added backend URL configuration
- `backend/README.md` - Deployment instructions
- `backend/src/index.ts` - Added health check endpoint

