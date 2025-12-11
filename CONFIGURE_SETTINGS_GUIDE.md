# How to Configure Settings - Step by Step Guide

## 📍 Where to Configure Settings

**Settings are configured INSIDE the Flutter app** after you launch it. There's no separate configuration file - everything is done through the app's Settings screen.

## 🚀 Step-by-Step Instructions

### Step 1: Launch the App

```bash
cd medical_copilot
flutter run
```

The app will launch and show the **Recording Screen** (main screen).

### Step 2: Open Settings Screen

**On the Recording Screen, look at the top-right corner:**

You'll see several icons in the AppBar (top bar):
- 🆔 Badge icon (capture patient ID)
- 👥 People icon (patients list)
- ⚙️ **Settings icon** ← **Click this one!**
- 🔧 Services icon (background debug)

**Tap the Settings icon (⚙️)** to open the Settings screen.

### Step 3: Configure Required Settings

Once you're on the Settings screen, you'll see several sections. Here's what to configure:

#### 🔐 Authentication Section (REQUIRED)

1. **Auth Token Field**
   - **Label**: "Auth Token"
   - **What to enter**: Any text value (e.g., `test-token-123` or `my-secret-token`)
   - **Why**: The mock backend accepts any Bearer token, so any value works
   - **How**: Tap the field and type any token value

2. **User Email Field**
   - **Label**: "User Email"
   - **What to enter**: `user@example.com`
   - **Why**: This email exists in the mock backend and will resolve to `user_123`
   - **How**: Tap the field and enter `user@example.com`
   - **What happens**: The app will automatically resolve your User ID and show it below the field

#### 🌐 Backend Configuration (OPTIONAL - Only if using deployed backend)

**If you're using localhost backend (default):**
- **Leave these fields EMPTY** - the app will automatically use:
  - Android Emulator: `http://10.0.2.2:3000/api`
  - iOS Simulator: `http://localhost:3000/api`

**If you deployed your backend to the cloud:**
1. **API Base URL Field**
   - **Label**: "API Base URL (optional)"
   - **What to enter**: Your deployed backend URL + `/api`
   - **Example**: `https://your-backend.run.app/api`
   - **Leave empty** if using localhost

2. **Backend Base URL Field**
   - **Label**: "Backend Base URL (optional)"
   - **What to enter**: Same as API Base URL (or leave empty)
   - **Leave empty** if using localhost

#### 🎨 Optional Settings

- **Theme**: Choose Light/Dark/System (saves automatically)
- **Language**: Choose English/Hindi (saves automatically)

### Step 4: Verify Configuration

After entering the Auth Token and User Email:

1. **Check User ID Resolution**
   - Below the User Email field, you should see:
     - "User ID: user_123" (if resolved successfully)
     - "Resolving user ID..." (while loading)
     - "Error: ..." (if there's a problem)

2. **If User ID shows successfully**, you're ready to use the app!

3. **If there's an error**, check:
   - Backend is running: `curl http://localhost:3000/health`
   - Network connectivity
   - API Base URL is correct (if using deployed backend)

## 📸 Visual Guide

```
┌─────────────────────────────────────┐
│  Recording Screen (Main Screen)    │
│                                     │
│  [Title]  [🆔] [👥] [⚙️] [🔧]     │  ← Tap ⚙️ here
│                                     │
│  Select Patient: [Dropdown]        │
│  Select Template: [Dropdown]       │
│  [Start Recording] [Pause] [Stop] │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│  Settings Screen                    │
│                                     │
│  Theme                              │
│  ○ System  ○ Light  ○ Dark         │
│                                     │
│  Language                           │
│  ○ English  ○ Hindi                │
│                                     │
│  Backend Configuration              │
│  API Base URL: [________________]   │  ← Leave empty for localhost
│  Backend Base URL: [____________]   │  ← Leave empty for localhost
│                                     │
│  Authentication                     │
│  Auth Token: [test-token-123]      │  ← Enter any token
│  User Email: [user@example.com]    │  ← Enter this email
│  User ID: user_123                 │  ← Should appear automatically
└─────────────────────────────────────┘
```

## ✅ Quick Configuration Checklist

- [ ] App is running
- [ ] Tapped Settings icon (⚙️) from Recording screen
- [ ] Entered Auth Token (any value)
- [ ] Entered User Email (`user@example.com`)
- [ ] User ID shows as `user_123` (or similar)
- [ ] (Optional) Set API Base URL if using deployed backend

## 🎯 What Each Setting Does

| Setting | Purpose | Required? | Default Value |
|---------|---------|-----------|---------------|
| **Auth Token** | Bearer token for API authentication | ✅ Yes | None |
| **User Email** | Used to resolve your User ID from backend | ✅ Yes | None |
| **API Base URL** | Main API endpoint URL | ❌ No | Auto-detects localhost |
| **Backend Base URL** | User ID resolution endpoint | ❌ No | Uses API Base URL |
| **Theme** | Light/Dark/System theme | ❌ No | System |
| **Language** | English/Hindi | ❌ No | English |

## 🔄 Settings Persist Automatically

All settings are **automatically saved** when you change them. You don't need to tap a "Save" button - just enter the values and they're saved immediately.

## 🐛 Troubleshooting

### "User ID: Not resolved"
- Check backend is running: `curl http://localhost:3000/health`
- Verify User Email is `user@example.com`
- Check API Base URL is correct (or leave empty for localhost)

### "Error: Connection refused"
- Backend not running - start it with `npm run dev` in backend folder
- Wrong API Base URL - leave empty for localhost, or check deployed URL

### Settings screen not opening
- Make sure app is fully launched
- Tap the ⚙️ icon in the top-right corner of Recording screen
- Check app logs for errors

## 📝 Example Configuration

**For Local Development (Default):**
```
Auth Token: test-token-123
User Email: user@example.com
API Base URL: (leave empty)
Backend Base URL: (leave empty)
```

**For Deployed Backend:**
```
Auth Token: my-production-token
User Email: user@example.com
API Base URL: https://my-backend.run.app/api
Backend Base URL: https://my-backend.run.app/api
```

---

**That's it!** Once you've configured these settings, you can start using the app to record medical consultations.

