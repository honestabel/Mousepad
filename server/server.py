#!/usr/bin/env python3
"""
Mousepad UDP Server
Listens for UDP datagrams from the Flutter app and drives the mouse.
Advertises itself via mDNS so the app can find it automatically.

Protocol (plain text, UTF-8):
  MOVE:dx,dy    -- relative mouse move  (e.g. "MOVE:10.50,-3.25")
  LEFT          -- left click
  RIGHT         -- right click
  SCROLL:ticks  -- scroll wheel        (e.g. "SCROLL:-2" = scroll up 2 ticks)

Setup:
    pip install pyautogui zeroconf

Run:
    python server.py

macOS: grant Accessibility access in System Settings -> Privacy -> Accessibility.
"""

import socket
import sys

import pyautogui

pyautogui.FAILSAFE = False
pyautogui.PAUSE = 0

HOST = '0.0.0.0'
PORT = 8765
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


def start_mdns(local_ip: str, port: int):
    """Register _mousepad._udp.local via Bonjour/mDNS. Optional — needs zeroconf."""
    try:
        from zeroconf import IPVersion, ServiceInfo, Zeroconf
        info = ServiceInfo(
            '_mousepad._udp.local.',
            'Mousepad._mousepad._udp.local.',
            addresses=[socket.inet_aton(local_ip)],
            port=port,
            properties={'version': '2'},
        )
        zc = Zeroconf(ip_version=IPVersion.V4Only)
        zc.register_service(info)
        print(f'  mDNS : advertising as Mousepad._mousepad._udp.local')
        return zc, info
    except ImportError:
        print('  mDNS : zeroconf not installed — auto-discovery unavailable')
        print('         run:  pip install zeroconf')
        return None, None


def main() -> None:
    local_ip = get_local_ip()

    print('[ Mousepad UDP Server v2.0 ]')
    print(f'  UDP  : listening on {local_ip}:{PORT}')

    zc, info = start_mdns(local_ip, PORT)
    print()

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind((HOST, PORT))
    print('Waiting for tablet...\n')

    try:
        while True:
            try:
                data, _ = sock.recvfrom(BUFSIZE)
                msg = data.decode('utf-8').strip()

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
        if zc and info:
            zc.unregister_service(info)
            zc.close()
        print('\nServer stopped.')
        sys.exit(0)


if __name__ == '__main__':
    main()
