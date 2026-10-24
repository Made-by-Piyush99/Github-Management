"""
DevSync Studio - Backend Worker Server.
Communicates with the C++/Qt process via JSON-based protocol over standard I/O pipes.
Stdout is strictly reserved for JSON protocol lines.
Stderr is for diagnostic logs (no secrets).
"""

import sys
import json
import logging
import threading
from concurrent.futures import ThreadPoolExecutor
from typing import Dict, Any

from .dispatcher import Dispatcher

# Ensure stdout and stderr use UTF-8 safely
if sys.stdout is not None and hasattr(sys.stdout, "reconfigure"):
    try:
        sys.stdout.reconfigure(encoding="utf-8", line_buffering=True)
    except Exception:
        pass

if sys.stderr is not None and hasattr(sys.stderr, "reconfigure"):
    try:
        sys.stderr.reconfigure(encoding="utf-8", line_buffering=True)
    except Exception:
        pass

# Configure logging to STDERR ONLY
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] [%(name)s] %(message)s",
    stream=sys.stderr,
)
logger = logging.getLogger("DevSync.Server")


class BackendServer:
    def __init__(self, db_path=None):
        self.dispatcher = Dispatcher(db_path)
        self.executor = ThreadPoolExecutor(max_workers=4, thread_name_prefix="Worker")
        self._write_lock = threading.Lock()
        self._running = True

    def send_response(self, response_dict: Dict[str, Any]):
        """Serializes and sends a response strictly on stdout followed by newline and flush."""
        data = json.dumps(response_dict, ensure_ascii=False)
        with self._write_lock:
            sys.stdout.write(data + "\n")
            sys.stdout.flush()

    def send_event(self, event_name: str, payload: Dict[str, Any]):
        """Emits an asynchronous push event to the C++ application."""
        self.send_response({"event": event_name, "data": payload})

    def handle_request(self, req_id: str, cmd: str, args: Dict[str, Any]):
        """Dispatches request on worker thread and sends back result."""
        try:
            logger.debug("Executing command '%s' (req_id=%s)", cmd, req_id)
            result = self.dispatcher.dispatch(cmd, args)
            self.send_response({
                "id": req_id,
                "success": True,
                "data": result,
                "error": None,
            })
        except Exception as e:
            logger.exception("Error executing command '%s' (req_id=%s): %s", cmd, req_id, e)
            self.send_response({
                "id": req_id,
                "success": False,
                "data": None,
                "error": str(e),
            })

    def run(self):
        """Main event loop reading from standard input."""
        logger.info("DevSync Studio Backend Server started. Listening on stdin...")

        # Send initial ready event
        self.send_event("ready", {"version": "1.0.0"})

        while self._running:
            try:
                line = sys.stdin.readline()
                if not line:
                    logger.info("Stdin EOF encountered. Exiting cleanly.")
                    break

                line = line.strip()
                if not line:
                    continue

                try:
                    payload = json.loads(line)
                except json.JSONDecodeError as jde:
                    logger.error("Invalid JSON received on stdin: %s", line[:100])
                    self.send_response({
                        "id": None,
                        "success": False,
                        "error": f"JSON parse error: {str(jde)}",
                    })
                    continue

                req_id = payload.get("id")
                cmd = payload.get("cmd", "")
                args = payload.get("args") or {}

                if cmd == "system.shutdown":
                    logger.info("Shutdown requested.")
                    self.send_response({"id": req_id, "success": True, "data": "Shutting down"})
                    break

                # Execute in thread pool to prevent blocking stdin reader
                self.executor.submit(self.handle_request, req_id, cmd, args)

            except KeyboardInterrupt:
                logger.info("KeyboardInterrupt received. Exiting.")
                break
            except Exception as e:
                logger.exception("Unexpected error in main loop: %s", e)
                break

        self.shutdown()

    def shutdown(self):
        self._running = False
        self.executor.shutdown(wait=False)
        logger.info("Backend server terminated.")


def main():
    server = BackendServer()
    server.run()


if __name__ == "__main__":
    main()
