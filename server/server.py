#!/usr/bin/env python3
"""
Mousepad Desktop Server
WebSocket-based remote mouse controller.

Setup:
    pip install websockets pyautogui

Run:
    python server.py

macOS: grant Accessibility access in System Settings → Privacy → Accessibility.
"""

import asyncio
import json
import sys

import pyautogui
import websockets

# ── pyautogui safety settings ──────────────────────────────────────────────
pyautogui.FAILSAFE = False   # disable move-to-corner kill switch
pyautogui.PAUSE = 0          # remove default 0.1 s inter-call pause

HOST = "0.0.0.0"
PORT = 8765


async def handler(websocket: websockets.ServerConnection) -> None:
    addr = websocket.remote_address
    print(f"[+] Connected:  {addr[0]}:{addr[1]}")
    try:
        async for raw in websocket:
            try:
                msg: dict = json.loads(raw)
                t = msg.get("t")

                if t == "m":
                    # Relative mouse move — dx/dy in logical pixels
                    pyautogui.moveRel(msg["x"], msg["y"], duration=0)

                elif t == "l":
                    # Left click
                    pyautogui.click(button="left")

                elif t == "r":
                    # Right click
                    pyautogui.click(button="right")

                elif t == "s":
                    # Scroll — d is signed tick count (+= down, -= up)
                    ticks = int(msg.get("d", 0))
                    if ticks != 0:
                        pyautogui.scroll(-ticks)   # pyautogui: positive = up

                elif t == "ld":
                    pyautogui.mouseDown(button="left")

                elif t == "lu":
                    pyautogui.mouseUp(button="left")

            except (KeyError, TypeError, json.JSONDecodeError) as e:
                print(f"[!] Bad message: {e}  raw={raw!r}")

    except websockets.exceptions.ConnectionClosedError:
        pass
    finally:
        print(f"[-] Disconnected: {addr[0]}:{addr[1]}")


async def main() -> None:
    print("╔══════════════════════════════════════╗")
    print("║       Mousepad Server  v1.0          ║")
    print(f"║   Listening on ws://{HOST}:{PORT}     ║")
    print("╚══════════════════════════════════════╝")
    print("Waiting for tablet connection...\n")

    async with websockets.serve(
        handler,
        HOST,
        PORT,
        ping_interval=20,
        ping_timeout=10,
    ):
        await asyncio.Future()   # run forever


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\nServer stopped.")
        sys.exit(0)
