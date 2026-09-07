#!/usr/bin/env python3
import json
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

memory = {"id": "ci-memory", "text": None}


class Handler(BaseHTTPRequestHandler):
    def _json(self):
        length = int(self.headers.get("Content-Length", "0"))
        return json.loads(self.rfile.read(length) or b"{}")

    def _send(self, body, status=200):
        payload = json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def do_GET(self):
        if self.path == "/openapi.json":
            self._send({"paths": {"/memories": {}, "/search": {}}})
        else:
            self._send({"error": "not found"}, 404)

    def do_POST(self):
        body = self._json()
        if self.path == "/memories":
            messages = body.get("messages") or []
            memory["text"] = messages[0].get("content", "") if messages else ""
            self._send({"event_id": "ci-event"})
        elif self.path == "/search":
            results = []
            if memory["text"] is not None:
                results.append({"id": memory["id"], "memory": memory["text"], "score": 1.0})
            self._send({"results": results})
        else:
            self._send({"error": "not found"}, 404)

    def do_PUT(self):
        if self.path == f"/memories/{memory['id']}":
            memory["text"] = self._json().get("text", "")
            self._send({})
        else:
            self._send({"error": "not found"}, 404)

    def do_DELETE(self):
        if self.path == f"/memories/{memory['id']}":
            memory["text"] = None
            self._send({})
        else:
            self._send({"error": "not found"}, 404)

    def log_message(self, fmt, *args):
        print(fmt % args, file=sys.stderr)


port = int(sys.argv[1]) if len(sys.argv) > 1 else 8888
ThreadingHTTPServer(("127.0.0.1", port), Handler).serve_forever()
