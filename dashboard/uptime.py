"""Expose host uptime and last boot to Glance on the private Compose network."""

import json
from datetime import datetime, timedelta, timezone
from http.server import BaseHTTPRequestHandler, HTTPServer

AWST = timezone(timedelta(hours=8))


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path != "/":
            self.send_error(404)
            return

        with open("/host/proc/uptime", encoding="utf-8") as f:
            seconds = int(float(f.read().split()[0]))
        with open("/host/proc/stat", encoding="utf-8") as f:
            boot = next(int(line.split()[1]) for line in f if line.startswith("btime "))

        days, remainder = divmod(seconds, 86400)
        hours, remainder = divmod(remainder, 3600)
        minutes = remainder // 60
        uptime = f"{days}d {hours}h {minutes}m" if days else f"{hours}h {minutes}m"
        last_boot = datetime.fromtimestamp(boot, AWST).strftime("%d %b %Y %H:%M")
        body = json.dumps({"uptime": uptime, "last_boot": last_boot}).encode()

        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


HTTPServer(("0.0.0.0", 8081), Handler).serve_forever()
