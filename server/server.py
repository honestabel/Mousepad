#!/usr/bin/env python3
"""
Mousepad UDP Server v3.0
Listens for UDP datagrams from the Flutter app and drives the mouse.
Auto-discovery: responds to MOUSEPAD_DISCOVER broadcasts on port 8766.

Protocol (plain text, UTF-8):
  MOVE:dx,dy    -- relative mouse move  (e.g. "MOVE:10.50,-3.25")
  LEFT          -- left click
  RIGHT         -- right click
  SCROLL:ticks  -- scroll wheel        (e.g. "SCROLL:-2" = scroll up 2 ticks)

Setup:
    pip install pyautogui

Run:
    python server.py

macOS: grant Accessibility access in System Settings -> Privacy -> Accessibility.
Windows: run once as Administrator so firewall rules are added automatically.
"""

import socket
import sys
import threading

import pyautogui

pyautogui.FAILSAFE = False
pyautogui.PAUSE = 0

HOST = '0.0.0.0'
PORT = 8765
DISCOVER_PORT = 8766
BUFSIZE = 64


def get_local_ip() -> str:
    """Return the machine's LAN IP (not 127.0.0.1)."""
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(('10.255.255.255', 1))
        return s.getsockname()[0]
    except Exception:
        return '127.0.0.1'
    finally:
        s.close()


def add_firewall_rules() -> None:
    """Try to add Windows Firewall rules for ports 8765 and 8766 (UDP inbound)."""
    try:
        import subprocess
        import platform
        if platform.system() != 'Windows':
            return
        for port, name in [(PORT, 'Mousepad-Control'), (DISCOVER_PORT, 'Mousepad-Discovery')]:
            subprocess.run(
                [
                    'netsh', 'advfirewall', 'firewall', 'add', 'rule',
                    f'name={name}',
                    'dir=in',
                    'action=allow',
                    'protocol=UDP',
                    f'localport={port}',
                ],
                capture_output=True,
                check=False,
            )
        print('  FW   : firewall rules added (UDP 8765 + 8766 inbound)')
    except Exception as e:
        print(f'  FW   : could not add firewall rules ({e})')


def discovery_thread(local_ip: str, control_port: int) -> None:
    """Listen for MOUSEPAD_DISCOVER broadcasts and reply with our address."""
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        sock.bind(('', DISCOVER_PORT))
        reply = f'MOUSEPAD_HERE:{control_port}'.encode('utf-8')
        while True:
            try:
                data, addr = sock.recvfrom(64)
                if data.strip() == b'MOUSEPAD_DISCOVER':
                    sock.sendto(reply, addr)
            except Exception:
                pass
    except Exception as e:
        print(f'  DISC : discovery listener failed ({e})')


def main() -> None:
    local_ip = get_local_ip()

    print('[ Mousepad UDP Server v3.0 ]')
    print(f'  UDP  : listening on {local_ip}:{PORT}')
    print(f'  DISC : auto-discovery on port {DISCOVER_PORT}')

    add_firewall_rules()

    t = threading.Thread(target=discovery_thread, args=(local_ip, PORT), daemon=True)
    t.start()

    print()

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        sock.bind((HOST, PORT))
    except OSError as e:
        if e.errno == 10048 or e.errno == 98:  # Windows / Linux address in use
            print(f'\n[!] Port {PORT} is already in use.')
            print('    Another instance of MousepadServer may be running.')
            print('    Open Task Manager, find MousepadServer.exe, and end it.')
            input('\nPress Enter to exit...')
        else:
            raise
        sys.exit(1)
    print('  NOTE: Your iPad, tablet, or smartphone must be connected to the same')
    print('        Wi-Fi network as this computer for Mousepad to work.\n')
    print('  Minimize this window — keep it running in the background while using Mousepad.')
    print('  Once your device is connected and the app is working properly, keep this')
    print('  terminal running. Close it only when you are completely done using Mousepad.\n')
    print('Waiting for tablet...')
    print('  -> On your tablet, open the Mousepad app, go to Settings, select "Find", done.\n')
    print('  If the app says "Desktop not found", enter these manually in the app,')
    print('  then tap the Apply button in the application:')
    print(f'    IP Address : {local_ip}')
    print(f'    Port       : {PORT}\n')

    connected = False
    try:
        while True:
            try:
                data, addr = sock.recvfrom(BUFSIZE)
                msg = data.decode('utf-8').strip()

                if not connected:
                    connected = True
                    print(f'\n  *** CONNECTION SUCCESSFUL ***')
                    print(f'  Device connected from {addr[0]} — Mousepad is active and ready to use.')
                    print()
                    print('  Keep this window running in the background while using Mousepad.')
                    print('  Close it only when you are completely done.')
                    print()
                    print('  REMINDER: The next time you want to use Mousepad, you will need to:')
                    print('    1. Reopen MousepadServer.exe on your computer')
                    print('    2. Open the Mousepad app on your tablet, smartphone, or device and tap FIND again to re-establish the connection')
                    print()

                if msg.startswith('MOVE:'):
                    dx_s, dy_s = msg[5:].split(',')
                    pyautogui.moveRel(float(dx_s), float(dy_s), duration=0)

                elif msg == 'LEFT':
                    pyautogui.click(button='left')

                elif msg == 'RIGHT':
                    pyautogui.click(button='right')

                elif msg.startswith('SCROLL:'):
                    ticks = int(msg[7:])
                    if ticks != 0:
                        pyautogui.scroll(-ticks)

            except (ValueError, UnicodeDecodeError) as e:
                print(f'[!] Bad packet: {e}')

    except KeyboardInterrupt:
        pass
    finally:
        sock.close()
        print('\nServer stopped.')
        sys.exit(0)


if __name__ == '__main__':
    main()
