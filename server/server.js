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

let connected = false;

server.on('message', (data, rinfo) => {
  const msg = data.toString('utf8').trim();

  if (!connected) {
    connected = true;
    console.log(`\n  *** CONNECTION SUCCESSFUL ***`);
    console.log(`  Device connected from ${rinfo.address} — Mousepad is active and ready to use.`);
    console.log();
    console.log('  Keep this window running in the background while using Mousepad.');
    console.log('  Close it only when you are completely done.');
    console.log();
    console.log('  REMINDER: The next time you want to use Mousepad, you will need to:');
    console.log('    1. Reopen MousepadServer on your computer');
    console.log('    2. Open the Mousepad app on your tablet, smartphone, or device and tap FIND again to re-establish the connection');
    console.log();
  }

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
  console.log('  NOTE: Your iPad, tablet, or smartphone must be connected to the same');
  console.log('        Wi-Fi network as this computer for Mousepad to work.\n');
  console.log('  Once your device is connected and the app is working properly, keep this');
  console.log('  terminal running. Close it only when you are completely done using Mousepad.\n');
  console.log('Waiting for tablet...');
  console.log('  -> On your tablet, open the Mousepad app, go to Settings, select "Find", done.\n');
});
