"""
B (port) — HTTP server for port reachability test.
Listens on 0.0.0.0:8080 and responds to GET / with a plain-text banner.
The smoke-test.sh wrapper curls this from WSL to confirm NAS port is reachable.
Runs indefinitely until the container is stopped.

WARNING: do not run this while the main openalgo container is up —
both use port 8080.
"""
import http.server
import datetime


def log(msg):
    ts = datetime.datetime.now().isoformat(timespec="seconds")
    print(f"[{ts}] [PORT] {msg}", flush=True)


class SmokeHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        body = b"OpenAlgo NAS smoke PORT OK\n"
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)
        log(f"GET {self.path} from {self.client_address[0]} — 200 OK")

    def log_message(self, fmt, *args):
        pass  # suppress default access log; we handle it in do_GET


log("=" * 55)
log("B (port): HTTP server on 0.0.0.0:8080")
log("From WSL, verify with: curl http://192.168.1.72:8080/")
log("=" * 55)

server = http.server.HTTPServer(("0.0.0.0", 8080), SmokeHandler)
log("PORT server ready — waiting for connections...")
server.serve_forever()
