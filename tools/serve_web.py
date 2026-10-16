#!/usr/bin/env python3
"""Serve the exported web build with the MIME types Godot expects.

A Godot web build does not work when the files are opened directly from disk
(`file://`), and it does not work from a server that sends the wrong type for
`.wasm` (the browser refuses to instantiate it). This serves the files correctly
so the build can be opened in a browser.

Usage
-----
    python tools/serve_web.py                    # serve build/web on port 8060
    python tools/serve_web.py --port 9000
    python tools/serve_web.py --dir build/web --threads

`--threads` adds the COOP/COEP headers a *threaded* build needs. The build in
`build/web` is exported with `variant/thread_support=false`, so it does **not**
need them and will run from any plain static host. Only pass `--threads` if you
re-export with thread support enabled.

Then open http://localhost:8060/ in a browser.
"""

from __future__ import annotations

import argparse
import functools
import http.server
import os
import socketserver
import sys

# `.wasm` is the one that matters: with the wrong type the browser refuses to
# compile the module and the page hangs on a blank canvas.
EXTRA_TYPES = {
    ".wasm": "application/wasm",
    ".pck": "application/octet-stream",
    ".js": "text/javascript",
    ".mjs": "text/javascript",
    ".json": "application/json",
    ".png": "image/png",
    ".svg": "image/svg+xml",
    ".ogg": "audio/ogg",
    ".webm": "video/webm",
}


class Handler(http.server.SimpleHTTPRequestHandler):
    """Static file handler with Godot's MIME types and the header options."""

    threads = False

    def end_headers(self) -> None:  # noqa: D102 - inherited behaviour
        if self.threads:
            self.send_header("Cross-Origin-Opener-Policy", "same-origin")
            self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        # The build is meant to be re-exported, so let the browser revalidate
        # rather than holding a stale wasm.
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def guess_type(self, path):  # noqa: D102 - inherited behaviour
        _, ext = os.path.splitext(str(path).lower())
        if ext in EXTRA_TYPES:
            return EXTRA_TYPES[ext]
        return super().guess_type(path)

    def log_message(self, fmt: str, *args) -> None:  # quieter output
        sys.stderr.write("%s\n" % (fmt % args))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, default=8060)
    parser.add_argument("--dir", default=os.path.join("build", "web"))
    parser.add_argument("--threads", action="store_true",
                        help="add COOP/COEP headers for a threaded build")
    args = parser.parse_args()

    root = os.path.abspath(args.dir)
    if not os.path.isfile(os.path.join(root, "index.html")):
        print("No index.html in %s." % root)
        print("Export it first:")
        print('  godot --headless --path . --export-release "Web" build/web/index.html')
        return 1

    Handler.threads = args.threads
    handler = functools.partial(Handler, directory=root)
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("127.0.0.1", args.port), handler) as httpd:
        print("Serving %s at http://localhost:%d/" % (root, args.port))
        if args.threads:
            print("COOP/COEP headers enabled (threaded build).")
        else:
            print("Plain headers (single-threaded build).")
        print("Press Ctrl+C to stop.")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nStopped.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
