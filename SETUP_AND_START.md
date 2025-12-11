# Complete Setup and Start Guide

## ✅ Project Status: COMPLETE

All core requirements from the Attack Capital Mobile Engineering Challenge have been implemented:

- ✅ Real-time audio streaming during recording
- ✅ Bulletproof interruption handling (phone calls, app switching, network outages, phone restarts)
- ✅ Theme & language switching (persisted, no restart)
- ✅ Native platform features (microphone, camera, share, notifications, haptic feedback)
- ✅ Android foreground service
- ✅ iOS background audio
- ✅ Chunk queue persistence (survives app restarts)
- ✅ Mock backend with Docker deployment

## 🚀 Step-by-Step Setup

### Step 1: Prerequisites

```bash
# Check Flutter version (tested with 3.27.0)
flutter --version

# Should show:
# Flutter 3.27.0 • channel stable
```

**Required:**
- Flutter SDK 3.7.0+
- Android Studio / Xcode (for building)
- Node.js 18+ (for backend)
- Docker (optional, for backend)

### Step 2: Clone and Setup

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/ai-scribe-copilot.git
cd ai-scribe-copilot

# Install Flutter dependencies
cd medical_copilot
flutter pub get

# Install backend dependencies
cd ../backend
npm install
```

### Step 3: Start Backend

**Option A: Docker (Recommended)**
```bash
# From project root
docker-compose up --build
```

**Option B: Local Node.js**
```bash
cd backend
npm run dev
```

Backend will start on `http://localhost:3000`

**Verify backend is running:**
```bash
curl http://localhost:3000/health
# Should return: {"status":"healthy","timestamp":"..."}
```

### Step 4: Configure Flutter App

1. **Launch the app:**
   ```bash
   cd medical_copilot
   flutter run
   ```

2. **Open Settings Screen:**
   - When the app launches, you'll see the **Recording Screen** (main screen)
   - Look at the **top-right corner** of the screen
   - You'll see several icons: 🆔 👥 **⚙️** 🔧
   - **Tap the Settings icon (⚙️)** to open Settings

3. **Configure Required Settings:**
   - **Auth Token**: Enter any value (e.g., `test-token-123`)
     - This is the Bearer token for API authentication
     - The mock backend accepts any token, so any value works
   - **User Email**: Enter `user@example.com`
     - This email exists in the mock backend
     - The app will automatically resolve your User ID (should show `user_123`)
   - **API Base URL**: **Leave empty** for localhost
     - The app auto-detects: `http://10.0.2.2:3000/api` (Android) or `http://localhost:3000/api` (iOS)
   - **Backend Base URL**: **Leave empty** (uses API Base URL)

4. **Verify Connection:**
   - Below the User Email field, you should see: **"User ID: user_123"**
   - If you see an error, check that the backend is running
   - Go back to Recording screen and check that templates load

**📖 For detailed visual guide, see `CONFIGURE_SETTINGS_GUIDE.md`**

### Step 5: Test Recording

1. **Add a Patient:**
   - Go to Patients screen → Tap "+"
   - Enter patient name → Save

2. **Start Recording:**
   - Select Patient from dropdown
   - Select Template from dropdown
   - Tap "Start Recording"
   - Verify audio level visualization shows activity

3. **Test Interruptions:**
   - Lock phone → Unlock (recording continues)
   - Receive phone call → End call (auto-pause/resume)
   - Enable airplane mode → Disable (chunks queue and upload)

## 📱 Building for Release

### Android APK

```bash
cd medical_copilot
flutter build apk --release
```

**APK Location:** `build/app/outputs/flutter-apk/app-release.apk`

**Upload to GitHub Releases:**
```bash
gh release create v1.0.0 build/app/outputs/flutter-apk/app-release.apk --title "Release v1.0.0"
```

### iOS Build

**Simulator:**
```bash
flutter build ios --simulator
```

**Device (requires Apple Developer account):**
```bash
flutter build ios --release
# Then open Xcode, archive, and distribute
```

## 🌐 Deploy Backend

### Google Cloud Run

```bash
# Build and deploy
gcloud builds submit --tag gcr.io/YOUR_PROJECT_ID/medical-copilot-backend ./backend

gcloud run deploy medical-copilot-backend \
  --image gcr.io/YOUR_PROJECT_ID/medical-copilot-backend \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 3000

# Get URL
gcloud run services describe medical-copilot-backend \
  --region us-central1 \
  --format 'value(status.url)'
```

### Other Platforms

See `backend/README.md` for Railway, Render, Heroku, AWS, Azure options.

## ✅ Verification Checklist

Before submission, verify:

- [ ] Backend runs locally: `curl http://localhost:3000/health`
- [ ] Flutter app builds: `flutter build apk --release`
- [ ] Recording works with phone locked
- [ ] Phone call pauses/resumes recording
- [ ] Network outage queues chunks locally
- [ ] App restart recovers unsent chunks
- [ ] Theme switching persists
- [ ] Language switching works (English/Hindi)
- [ ] Native share sheet works
- [ ] Camera captures patient ID
- [ ] Haptic feedback on all buttons

## 📝 Submission Requirements

1. **GitHub Repo:** ✅ Ready
2. **Android APK:** Build and upload to GitHub Releases
3. **iOS Loom Video:** Record 5-minute demo showing all features
4. **Backend URL:** Deploy and add to README
5. **Docker Setup:** ✅ `docker-compose up` works
6. **Demo Video:** Record Loom showing interruption handling
7. **README:** ✅ Complete with all links

## 🎬 Demo Video Script

Record a 5-minute Loom covering:

1. **Setup (30s):** Show Settings configuration
2. **Basic Recording (1min):** Start recording, show audio levels
3. **Phone Lock Test (30s):** Lock phone, unlock, verify recording continues
4. **Phone Call Test (1min):** Receive call, verify auto-pause/resume
5. **Network Test (1min):** Enable airplane mode, disable, verify queue uploads
6. **App Switch Test (30s):** Open camera, take photo, return to app
7. **Theme/Language (30s):** Switch theme and language
8. **Native Features (30s):** Show share sheet, camera, haptic feedback

## 🐛 Common Issues

### Backend not starting
```bash
# Check port 3000 is available
netstat -an | grep 3000

# Try different port
PORT=3001 npm run dev
# Then update API Base URL in app settings
```

### App can't connect to backend
- **Android Emulator:** Use `http://10.0.2.2:3000/api`
- **iOS Simulator:** Use `http://localhost:3000/api`
- **Physical Device:** Use your computer's LAN IP (e.g., `http://192.168.1.100:3000/api`)

### Recording stops when app minimized
- Check foreground service notification is visible (Android)
- Verify `UIBackgroundModes` includes `audio` in iOS Info.plist

### Chunks not uploading
- Check network connectivity
- Verify auth token is set
- Check backend logs
- Use Background Debug screen to check queue status

## 📞 Support

For issues, check:
- `medical_copilot/README.md` - Full documentation
- `backend/README.md` - Backend deployment guide
- `SETUP_GUIDE.md` - Quick start guide

---

**Ready to submit!** 🚀

