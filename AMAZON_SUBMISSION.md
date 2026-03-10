# Amazon Appstore Submission Assets

---

## 1. App Description
*(Under 2000 characters — paste into the "Long Description" field)*

Mousepad turns your Android phone or tablet into a wireless trackpad for your PC or Mac — with near-zero latency.

Unlike most remote mouse apps that route input through cloud servers, Bluetooth stacks, or WebSocket relays, Mousepad sends raw UDP datagrams directly to your computer over your local Wi-Fi. The result is response times of 1–5ms — indistinguishable from a physical mouse.

**Features:**
- Dedicated Left Click and Right Click buttons for precise control
- Smooth scroll strip for fast, accurate scrolling
- Large, touch-friendly trackpad surface
- Auto-discovery — tap FIND and the app locates your computer instantly, no IP address needed
- Adjustable sensitivity and scroll speed
- Natural scroll toggle
- No account required. No Bluetooth pairing. No cloud relay.

**Zero ads. Zero tracking. Zero data collection.**
Mousepad communicates exclusively with the companion server running on your own computer. No data ever leaves your local network.

**Getting started:**
1. Download the free MousepadServer for Windows or Mac directly from the app's Settings screen
2. Run it on your computer
3. Open Mousepad, tap Settings, then tap FIND — you are connected

Works on all Android phones and tablets. Requires the free companion server app running on your Windows PC or Mac.

---

## 2. Technical Details — Feature Requirements

| Requirement | Details |
|---|---|
| **Network Access** | Required. The app sends UDP datagrams to the companion server on port 8765. Auto-discovery uses UDP broadcast on port 8766. |
| **Wi-Fi Connection** | Required. The Android device and the computer must be connected to the same local Wi-Fi network. Mobile data is not supported. |
| **Internet Permission** | `android.permission.INTERNET` — used for local UDP socket communication only. No external internet traffic. |
| **Touchscreen** | Required. All input (trackpad gestures, button taps, scrolling) is touch-based. |
| **Minimum Android SDK** | API 21 (Android 5.0 Lollipop) |
| **Target Android SDK** | API 34 (Android 14) |

---

## 3. Device Support — Amazon Fire Tablets

| Feature | Supported | Notes |
|---|---|---|
| **Touchscreen** | Yes | Flutter renders a native touch surface. All gestures work on Fire tablet touchscreens. |
| **Keyboard/Mouse input** | Not required | Mousepad *replaces* a mouse — no physical keyboard or mouse is needed to operate the app. |
| **Fire OS (Android fork)** | Yes | Built against Android API 21+. Compatible with Fire OS 5 and above (Fire HD 8, HD 10, Fire 7). |
| **Landscape/Portrait** | Yes | Layout adapts to both orientations via Flutter's responsive build. |
| **Hardware acceleration** | Yes | Enabled in AndroidManifest (`android:hardwareAccelerated="true"`). |

---

## 4. SEO Keywords
*(Enter individually in the Keywords field — one per line or comma-separated)*

1. Remote Mouse
2. Wireless Trackpad
3. Tablet Trackpad
4. PC Remote Control
5. Low Latency Mouse
6. WiFi Mouse
7. Android Trackpad
8. Desktop Controller
9. Developer Utility
10. Computer Remote

---

## 5. Privacy Policy
*(Paste into the Privacy Policy URL field, or host this text at your GitHub Pages / repo)*

---

### Privacy Policy for Mousepad

**Effective Date:** March 10, 2026

**Overview**

Mousepad is a local network utility that allows your Android device to control your computer's mouse over Wi-Fi. We are committed to your privacy. This policy describes what data the app does and does not collect.

**Data Collection**

Mousepad does **not** collect, store, transmit, or share any personal data. Specifically:

- No account registration or login is required
- No analytics or crash reporting SDKs are included
- No advertising SDKs or third-party trackers are included
- No device identifiers, usage statistics, or behavioral data are collected
- No data is sent to any remote server, cloud service, or third party

**Network Communication**

Mousepad communicates exclusively over your local Wi-Fi network using UDP datagrams sent directly to the companion server application running on your own computer. All communication stays within your local network and never reaches the internet.

**Permissions**

The app requests `android.permission.INTERNET` solely to open a local UDP socket. This permission is used only for device-to-computer communication on your local network.

**Changes to This Policy**

If this policy changes in a future version, the updated policy will be posted in this repository and the effective date will be updated.

**Contact**

For questions about this privacy policy, open an issue at:
https://github.com/honestabel/Mousepad/issues
