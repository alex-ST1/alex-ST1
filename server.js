#!/usr/bin/env node
/**
 * Zero-dependency Node.js Local Network Server for Savings Tracker.
 */
const http = require('http');
const fs = require('fs');
const path = require('path');
const os = require('os');

const PORT = 8080;

// MIME types dictionary
const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.ico': 'image/x-icon'
};

function getLocalIp() {
  const interfaces = os.networkInterfaces();
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name]) {
      if (iface.family === 'IPv4' && !iface.internal) {
        return iface.address;
      }
    }
  }
  return '127.0.0.1';
}

const server = http.createServer((req, res) => {
  let filePath = path.join(__dirname, req.url === '/' ? 'index.html' : req.url);
  filePath = filePath.split('?')[0]; // Remove query string

  fs.stat(filePath, (err, stats) => {
    if (err || !stats.isFile()) {
      res.writeHead(404, { 'Content-Type': 'text/plain' });
      res.end('404 Not Found');
      return;
    }

    const ext = path.extname(filePath).toLowerCase();
    const contentType = MIME_TYPES[ext] || 'application/octet-stream';

    res.writeHead(200, {
      'Content-Type': contentType,
      'Cache-Control': 'no-cache',
      'Access-Control-Allow-Origin': '*'
    });

    fs.createReadStream(filePath).pipe(res);
  });
});

server.listen(PORT, '0.0.0.0', () => {
  const localIp = getLocalIp();
  console.log('\n==============================================================');
  console.log(' 🚀  SAVINGS TRACKER - NODE.JS SERVER RUNNING');
  console.log('==============================================================');
  console.log(`  • Preview on Kali Linux : http://localhost:${PORT}`);
  if (localIp !== '127.0.0.1') {
    console.log(`  • Open on your iPhone   : http://${localIp}:${PORT}`);
  }
  console.log('--------------------------------------------------------------');
  console.log('  📲 HOW TO INSTALL ON IPHONE:');
  console.log('  1. Ensure iPhone is on the same Wi-Fi network.');
  console.log(`  2. Open Safari on iPhone and navigate to: http://${localIp}:${PORT}`);
  console.log('  3. Tap Share icon -> "Add to Home Screen" -> "Add".');
  console.log('==============================================================\n');
});
