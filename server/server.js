/**
 * Mousepad UDP Server — Node.js alternative
 *
 * Protocol (plain text, UTF-8):
 *   MOVE:dx,dy    — relative mouse move
 *   LEFT          — left click
 *   RIGHT         — right click
 *   SCROLL:ticks  — scroll (positive=down, negative=up)
 *
 * Setup:  npm install
 * Run:    npm start
 *
 * macOS: grant Accessibility access for Terminal/node in System Settings.
 */

const dgram = require('dgram');
const robot = require('@jitsi/robotjs');

robot.setMouseDelay(0);
robot.setKeyboardDelay(0);

const PORT = 8765;
const server = dgram.createSocket('udp4');

server.on('message', (data) => {
  const msg = data.toString('utf8').trim();

  if (msg.startsWith('MOVE:')) {
    const [dx, dy] = msg.slice(5).split(',').map(Number);
    const pos = robot.getMousePos();
    robot.moveMouse(Math.round(pos.x + dx), Math.round(pos.y + dy));

  } else if (msg === 'LEFT') {
    robot.mouseClick('left');

  } else if (msg === 'RIGHT') {
    robot.mouseClick('right');

  } else if (msg.startsWith('SCROLL:')) {
    const ticks = parseInt(msg.slice(7), 10);
    if (ticks !== 0) robot.scrollMouse(0, -ticks);
  }
});

server.on('error', (err) => {
  console.error(`Server error: ${err.message}`);
  server.close();
});

server.bind(PORT, () => {
  console.log(`Mousepad UDP server listening on port ${PORT}`);
  console.log('Waiting for tablet...');
  console.log('  -> On your tablet, open the Mousepad app, go to Settings, select "Find", done.\n');
});
