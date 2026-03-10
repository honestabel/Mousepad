# Mousepad

Turn your iPhone or Android tablet into a wireless trackpad for your desktop — instantly.

Mousepad is built for **zero-lag mouse control**. Most remote mouse apps route input through WebSockets, Bluetooth stacks, or cloud relays, introducing 100–300ms of delay that makes them feel sluggish and unusable. Mousepad uses raw UDP datagrams fired directly to your desktop over your local network — no handshaking, no buffering, no middleman. The result is a trackpad that feels like hardware.

---

## Why Mousepad

| | Mousepad | Most other apps |
|---|---|---|
| Protocol | Raw UDP (fire-and-forget) | WebSocket / Bluetooth / cloud |
| Latency | ~1–5ms on local Wi-Fi | 100–300ms+ |
| Setup | Download .exe, tap FIND | Accounts, pairing, config files |
| Works offline | Yes | Often no |

---

## Getting started

### On your desktop
1. Open the Mousepad app on your phone or tablet
2. Tap **⚙** to open Settings
3. Tap the **Windows** or **macOS** download button to get the server
4. Run **MousepadServer.exe** (Windows) or **MousepadServer** (Mac)
5. Mac only: allow it in **System Settings → Privacy & Security → Accessibility**

### On your device
6. Tap **FIND** — the app discovers your desktop automatically
7. Tap **APPLY** — you're connected

That's it. No IP addresses, no accounts, no configuration.

---

## Controls

| Gesture | Action |
|---|---|
| Drag one finger | Move mouse |
| Tap left button | Left click |
| Tap right button | Right click |
| Swipe scroll strip | Scroll |

Sensitivity and scroll speed are adjustable in Settings.

---

## Installing on iOS

iOS requires sideloading since Mousepad is not on the App Store:

1. Download the latest `Mousepad.ipa` from [Actions](../../actions) → latest **Build iOS** run
2. Install [Sideloadly](https://sideloadly.io) on your PC
3. Plug in your iPhone/iPad, drag the IPA onto Sideloadly, sign with your Apple ID
4. Trust the app on your device: **Settings → VPN & Device Management**

Re-sign every 7 days (free Apple ID) or annually (paid Apple Developer account).

---

## Installing on Android

Download the APK from [Actions](../../actions) → latest build, or build from source:

```
flutter build apk --release
```

---

## Building from source

```bash
git clone https://github.com/honestabel/Mousepad
cd Mousepad
flutter pub get
flutter run
```

Requires Flutter 3.x and Dart 3.x.

---

## How it works

The app sends plain-text UDP datagrams to the desktop server on port **8765**:

```
MOVE:dx,dy     relative mouse movement
LEFT           left click
RIGHT          right click
SCROLL:ticks   scroll wheel
```

Auto-discovery broadcasts `MOUSEPAD_DISCOVER` on port **8766**. The server responds with `MOUSEPAD_HERE:8765` and the app connects automatically — no manual IP entry required.
