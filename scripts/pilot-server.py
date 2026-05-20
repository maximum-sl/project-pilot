#!/usr/bin/env python3
"""Static HTTP server for the Project Pilot briefs root.

Loopback-only, no-cache headers, no directory listing. Used by `pilot open` to
make plan.html clickable from any chat or editor.
"""

import http.server
import os
import socketserver
import sys


class BriefsHandler(http.server.SimpleHTTPRequestHandler):
    # Disable directory listing , return 404 instead of an index page.
    def list_directory(self, path):
        self.send_error(404, "Directory listing disabled")
        return None

    # Always send no-store headers so re-rendered plan.html shows up on refresh.
    def end_headers(self):
        self.send_header("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        super().end_headers()

    # Quiet the console , one log line per access is enough for our use.
    def log_message(self, fmt, *args):
        sys.stderr.write(f"{self.address_string()} - {fmt % args}\n")


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else os.getcwd()
    port = int(sys.argv[2]) if len(sys.argv) > 2 else 8765
    host = sys.argv[3] if len(sys.argv) > 3 else "127.0.0.1"

    os.chdir(root)
    http.server.ThreadingHTTPServer.allow_reuse_address = True
    with http.server.ThreadingHTTPServer((host, port), BriefsHandler) as httpd:
        sys.stderr.write(f"pilot-server: http://{host}:{port}  root={root}\n")
        httpd.serve_forever()


if __name__ == "__main__":
    main()
