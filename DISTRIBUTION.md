# Installing Mousepad on Android (Sideloading)

Mousepad is distributed outside of the Google Play Store. Follow the steps below to install it directly on your Android phone or tablet.

---

## Step 1 — Download the APK

Go to the [Releases](../../releases) page of this repository and download the APK for your device:

| File | Architecture | Use for |
|---|---|---|
| `app-arm64-v8a-release.apk` | ARM 64-bit | Most modern Android phones and tablets (recommended) |
| `app-armeabi-v7a-release.apk` | ARM 32-bit | Older Android devices |
| `app-x86_64-release.apk` | x86 64-bit | Android emulators / some Chromebooks |

**Not sure which one to pick?** Download `app-arm64-v8a-release.apk` — it works on the vast majority of modern Android devices.

---

## Step 2 — Open the APK on your device

Locate the downloaded APK in your **Downloads** folder and tap it to begin installation.

---

## Step 3 — Allow installation from this source

Android will show a security prompt the first time you install an app outside of the Play Store.

1. When prompted, tap **Settings**
2. Toggle **Allow from this source** to **ON**
3. Press the back button to return to the installer

> This setting only applies to the app you used to open the file (e.g. your browser or file manager). It does not disable Android's security globally.

---

## Step 4 — Complete the installation

Tap **Install** and wait for the installation to finish. Once done, tap **Open** to launch Mousepad.

---

## Troubleshooting

**"Install blocked" or no prompt appears**
- Go to **Settings → Apps → Special app access → Install unknown apps**
- Find your browser or file manager and toggle **Allow from this source** to ON
- Try opening the APK again

**"App not installed" error**
- Make sure you downloaded the correct APK for your device architecture
- Try the `app-arm64-v8a-release.apk` if unsure

**App installs but won't connect**
- Ensure your Android device and computer are on the **same Wi-Fi network**
- Make sure `MousepadServer.exe` (Windows) or `MousepadServer` (Mac) is running on your computer
- Open Mousepad, go to **Settings**, and tap **FIND** to discover your computer automatically
