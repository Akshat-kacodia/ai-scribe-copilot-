# Step-by-Step Commands to Start the Project

## Step 1: Start the Backend Server

Open a PowerShell terminal and run:

```powershell
cd backend
npm run dev
```

**OR** if you prefer to run the compiled version:

```powershell
cd backend
npm run build
node dist/index.js
```

**Expected output:** You should see:
```
[INFO] ts-node-dev ver. 2.0.0
medical_copilot backend listening on port 3000
```

**Keep this terminal window open!** The backend needs to keep running.

---

## Step 2: Verify Backend is Running

Open a **NEW** PowerShell terminal and run:

```powershell
curl http://localhost:3000/health
```

**Expected output:**
```json
{"status":"healthy","timestamp":"2025-12-09T..."}
```

If you see this, the backend is working! ✅

---

## Step 3: Check Connected Devices

In the same or a new terminal, run:

```powershell
cd medical_copilot
flutter devices
```

**Expected output:** You should see your device listed, for example:
```
Found 4 connected devices:
  I2301 (mobile)    • 10BD8M1Q0P0005H • android-arm64  • Android 15 (API 35)
  ...
```

**Note the device ID** (e.g., `10BD8M1Q0P0005H`) - you'll need it for the next step.

---

## Step 4: Start the Flutter App

Still in the `medical_copilot` directory, run:

```powershell
flutter run -d 10BD8M1Q0P0005H
```

**Replace `10BD8M1Q0P0005H` with your actual device ID from Step 3.**

**Expected output:**
- Flutter will start building the app
- You'll see build progress
- The app will install and launch on your phone automatically

**First build may take 2-5 minutes.** Subsequent builds are faster.

---

## Step 5: Configure App Settings

Once the app opens on your phone:

1. **Tap the Settings icon (⚙️)** in the top-right corner
2. **Enter Auth Token:** `test-token-123` (or any value)
3. **Enter User Email:** `user@example.com`
4. **For Physical Android Device:** 
   - Find your computer's IP address: Run `ipconfig` in PowerShell (look for IPv4 Address, e.g., `192.168.1.100`)
   - Enter API Base URL: `http://YOUR_IP:3000/api` (e.g., `http://192.168.1.100:3000/api`)
   - Leave empty only if using Android Emulator (uses `10.0.2.2:3000/api` automatically)
5. **Verify:** You should see "User ID: user_123" below the email field (green text)
   - If you see an error (red text), check:
     - Backend is running: `curl http://localhost:3000/health`
     - For physical device, use your computer's IP address in API Base URL
     - Auth token is entered
     - Both phone and computer are on the same WiFi network

---

## Quick Start (All Commands)

If you want to run everything quickly:

**Terminal 1 (Backend):**
```powershell
cd backend
npm run dev
```

**Terminal 2 (Flutter App):**
```powershell
cd medical_copilot
flutter devices
flutter run -d YOUR_DEVICE_ID
```

---

## Troubleshooting

### Backend not starting?
- Make sure port 3000 is not in use: `netstat -ano | findstr :3000`
- Check if Node.js is installed: `node --version`
- Verify dependencies: `cd backend && npm install`

### Flutter device not detected?
- Make sure USB debugging is enabled on your phone
- Run `flutter doctor` to check for issues
- Try unplugging and replugging your phone

### App can't connect to backend?
- **Android Emulator:** Use `http://10.0.2.2:3000/api`
- **Physical Device:** Use your computer's IP address (e.g., `http://192.168.1.100:3000/api`)
- Find your IP: `ipconfig` (look for IPv4 Address)

---

## Stop the Project

- **Backend:** Press `Ctrl+C` in the backend terminal
- **Flutter:** Press `q` in the Flutter terminal or `Ctrl+C`

