# Network Error Resolution Guide

## ✅ Error Handling Improved

The app now handles network errors gracefully without crashing. However, you need to ensure the backend is accessible.

## 🔧 How to Fix "No route to host" Error

### Step 1: Start the Backend

**Option A: Using Docker (Recommended)**
```bash
cd backend
docker-compose up --build
```

**Option B: Using Node.js**
```bash
cd backend
npm install
npm run dev
```

The backend should start on `http://localhost:3000`

### Step 2: Configure Backend URL in App

1. **Open Settings** in the app (gear icon)
2. **Check Current Backend URL** - Shows what URL the app is using
3. **Click "Test Connection"** - Verifies backend is reachable

### Step 3: Set Correct URL Based on Your Setup

#### For Android Emulator:
- **Leave API Base URL empty** (defaults to `http://10.0.2.2:3000/api`)
- Or manually set: `http://10.0.2.2:3000/api`

#### For Physical Android Device:
- **Use your computer's LAN IP address**
- Find your IP: 
  - Windows: `ipconfig` (look for IPv4 Address)
  - Mac/Linux: `ifconfig` or `ip addr`
- Example: `http://192.168.1.100:3000/api` (replace with your IP)

#### For iOS Simulator:
- **Leave API Base URL empty** (defaults to `http://localhost:3000/api`)
- Or manually set: `http://localhost:3000/api`

#### For Deployed Backend:
- Set API Base URL to: `https://your-backend-url.com/api`
- Set Backend Base URL to: `https://your-backend-url.com/api`

### Step 4: Verify Connection

1. Click **"Test Connection"** button in Settings
2. Should show: ✓ Connection successful!
3. If error: Follow the troubleshooting steps shown

## 🛠️ Troubleshooting

### Error: "Cannot reach backend"

**Check:**
1. ✅ Backend is running (`curl http://localhost:3000/health`)
2. ✅ Correct URL/IP in Settings
3. ✅ Device and computer on same WiFi network (for physical device)
4. ✅ Firewall allows port 3000
5. ✅ No VPN interfering

### Error: "Connection timeout"

**Solutions:**
- Backend may be slow to respond
- Check backend logs for errors
- Try restarting backend
- Increase timeout in code (if needed)

### Error: "No route to host"

**This means:**
- Backend URL is incorrect
- Backend is not running
- Network is unreachable
- Firewall blocking connection

**Fix:**
1. Verify backend is running
2. Check URL/IP is correct
3. Test with `curl` from command line
4. Use "Test Connection" button in Settings

## 📱 Settings Screen Features

### New Features Added:
- ✅ **Current Backend URL Display** - Shows exactly what URL is being used
- ✅ **Test Connection Button** - Verifies backend is reachable
- ✅ **Helpful Instructions** - Quick setup guide
- ✅ **Better Error Messages** - Clear explanation of what's wrong

### How to Use:
1. Open Settings (gear icon)
2. Scroll to "Backend Configuration"
3. See current URL being used
4. Click "Test Connection" to verify
5. Adjust URL if needed
6. Test again until successful

## ✅ Verification Checklist

- [ ] Backend is running (`npm run dev` or `docker-compose up`)
- [ ] Backend responds to `curl http://localhost:3000/health`
- [ ] Correct URL set in app Settings
- [ ] "Test Connection" shows success
- [ ] User Email is set
- [ ] Auth Token is set
- [ ] User ID resolves successfully

## 🎯 Quick Fix Summary

**Most Common Issue:** Backend not running

**Quick Fix:**
```bash
# Terminal 1: Start backend
cd backend
npm run dev

# Terminal 2: Verify it's running
curl http://localhost:3000/health
# Should return: {"status":"healthy","timestamp":"..."}
```

Then in the app:
1. Open Settings
2. Leave API Base URL empty (for emulator) or set your computer's IP (for physical device)
3. Click "Test Connection"
4. Should show success!

## 📝 Network Error Behavior

The app now:
- ✅ **Doesn't crash** on network errors
- ✅ **Logs errors** for debugging
- ✅ **Keeps chunks in queue** for retry
- ✅ **Retries automatically** when network is restored
- ✅ **Shows helpful messages** in Settings

Your recordings are safe - chunks are queued locally and will upload when the backend is available!

