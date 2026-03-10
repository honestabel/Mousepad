#!/usr/bin/env python3
"""
Mousepad UDP Server
Listens for UDP datagrams from the Flutter app and drives the mouse.

Protocol (plain text, UTF-8):
  MOVE:dx,dy    — relative mouse move  (e.g. "MOVE:10.50,-3.25")
  LEFT          — left click
  RIGHT         — right click
  SCROLL:ticks  — scroll wheel        (e.g. "SCROLL:-2" = scroll up 2 ticks)

Setup:
    pip install pyautogui

Run:
    python server.py

macOS: grant Accessibility access in System Settings → Privacy → Accessibility.
"""

import socket
import sys

import pyautogui

# ── pyautogui config ───────────────────────────────────────────────────────
pyautogui.FAILSAFE = False   # don't abort on corner-move
pyautogui.PAUSE = 0          # zero inter-call delay → lowest latency

HOST = '0.0.0.0'
PORT = 8765
BUFSIZE = 64          # max datagram size; longest message is ~28 bytes


def main() -> None:
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind((HOST, PORT))

    print('╔══════════════════════════════════════╗')
    print('║      Mousepad UDP Server  v2.0       ║')
    print(f'║   Listening on udp://{HOST}:{PORT}     ║')
    print('╚══════════════════════════════════════╝')
    print('Waiting for tablet...\n')

    while True:
        try:
            data, addr = sock.recvfrom(BUFSIZE)
            msg = data.decode('utf-8').strip()

            if msg.startswith('MOVE:'):
                # "MOVE:dx,dy"
                dx_s, dy_s = msg[5:].split(',')
                pyautogui.moveRel(float(dx_s), float(dy_s), duration=0)

            elif msg == 'LEFT':
                pyautogui.click(button='left')

            elif msg == 'RIGHT':
                pyautogui.click(button='right')

            elif msg.startswith('SCROLL:'):
                # "SCROLL:ticks"  positive = down, negative = up
                ticks = int(msg[7:])
                if ticks != 0:
                    pyautogui.scroll(-ticks)   # pyautogui positive = up

        except (ValueError, UnicodeDecodeError) as e:
            print(f'[!] Bad packet from {addr}: {e}')
        except Exception as e:
            print(f'[!] Error: {e}')


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print('\nServer stopped.')
        sys.exit(0)
