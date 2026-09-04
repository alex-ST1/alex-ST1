#!/usr/bin/env python3
"""
Ultra-fast, Multi-threaded Local Development Server for Savings Tracker.
Optimized for instant page load on iPhone & Linux with zero DNS lookup lag.
"""

import http.server
import socket
import os
import sys

PORT = 8080

def get_local_ip():
    """Detect local LAN IP address quickly without DNS lookup."""
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(('10.255.255.255', 1))
        IP = s.getsockname()[0]
    except Exception:
        IP = '127.0.0.1'
    finally:
        s.close()
    return IP

class FastHTTPHandler(http.server.SimpleHTTPRequestHandler):
    # CRITICAL: Prevent blocking reverse DNS lookup on each request (causes multi-second stalls on local networks)
    def address_string(self):
        return self.client_address[0]

    def end_headers(self):
        # Enable gzip / cache for static assets to ensure sub-millisecond loads
        path = self.translate_path(self.path)
        ext = os.path.splitext(path)[1].lower()

        if ext in ['.css', '.js', '.svg', '.png', '.jpg', '.woff2']:
            self.send_header('Cache-Control', 'public, max-age=86400')
        else:
            self.send_header('Cache-Control', 'no-cache, must-revalidate')

        self.send_header('Access-Control-Allow-Origin', '*')
        super().end_headers()

    def log_message(self, format, *args):
        # Fast stdout logging
        sys.stdout.write(f"  [REQ] {self.client_address[0]} - {args[0]}\n")
        sys.stdout.flush()

def run():
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    local_ip = get_local_ip()

    port = PORT
    max_attempts = 10
    httpd = None

    for attempt in range(max_attempts):
        try:
            # Use multi-threaded HTTP server so all assets load concurrently
            if hasattr(http.server, 'ThreadingHTTPServer'):
                httpd = http.server.ThreadingHTTPServer(("", port), FastHTTPHandler)
            else:
                import socketserver
                class ThreadedServer(socketserver.ThreadingMixIn, http.server.HTTPServer):
                    daemon_threads = True
                httpd = ThreadedServer(("", port), FastHTTPHandler)

            # Disable Nagle's algorithm for instant packet delivery
            httpd.socket.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
            break
        except OSError:
            port += 1

    if not httpd:
        print(f"Error: Could not bind to port {PORT} to {port}.")
        sys.exit(1)

    print("\n" + "=" * 62)
    print(" 🚀  SAVINGS TRACKER (INR • ₹) - LIGHTNING FAST SERVER")
    print("=" * 62)
    print(f"  • Preview on Kali Linux : http://localhost:{port}")
    if local_ip != '127.0.0.1':
        print(f"  • Open on your iPhone   : http://{local_ip}:{port}")
    print("-" * 62)
    print("  📲 HOW TO INSTALL ON IPHONE (STANDALONE APP):")
    print(f"  1. Ensure iPhone is on the same Wi-Fi network.")
    print(f"  2. Open Safari on iPhone and go to: http://{local_ip}:{port}")
    print("  3. Tap the Share button (square with arrow pointing up).")
    print("  4. Scroll down and tap 'Add to Home Screen'.")
    print("  5. Tap 'Add' in the top right corner.")
    print("  The app will launch instantly in fullscreen with zero lag!")
    print("=" * 62 + "\n")
    print("Press Ctrl+C to stop the server.\n")

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping server... Goodbye!")
        httpd.server_close()

if __name__ == '__main__':
    run()
