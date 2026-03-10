/**
 * Mousepad Desktop Server — Node.js alternative
 *
 * Setup:
 *   npm install
 *
 * Run:
 *   npm start
 *
 * macOS: grant Accessibility access for Terminal / node in System Settings.
 */

const WebSocket = require('ws');
const robot = require('@jitsi/robotjs');

robot.setMouseDelay(0);
robot.setKeyboardDelay(0);

const PORT = 8765;
const wss = new WebSocket.Server({ port: PORT });

console.log(`Mousepad server running on ws://0.0.0.0:${PORT}`);

wss.on('connection', (ws, req) => {
  const addr = req.socket.remoteAddress;
  console.log(`[+] Connected: ${addr}`);

  ws.on('message', (data) => {
    try {
      const msg = JSON.parse(data);
      const { t } = msg;

      if (t === 'm') {
        const pos = robot.getMousePos();
        robot.moveMouse(
          Math.round(pos.x + msg.x),
          Math.round(pos.y + msg.y),
        );
      } else if (t === 'l') {
        robot.mouseClick('left');
      } else if (t === 'r') {
        robot.mouseClick('right');
      } else if (t === 's') {
        const ticks = Math.round(msg.d ?? 0);
        if (ticks !== 0) robot.scrollMouse(0, -ticks);
      } else if (t === 'ld') {
        robot.mouseToggle('down', 'left');
      } else if (t === 'lu') {
        robot.mouseToggle('up', 'left');
      }
    } catch (e) {
      console.error('[!] Bad message:', e.message);
    }
  });

  ws.on('close', () => console.log(`[-] Disconnected: ${addr}`));
});
