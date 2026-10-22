"""
Tests the line-delimited JSON IPC protocol used between C++ and Python worker.
"""

import json
import subprocess
import sys
import time


def test_server_ipc_protocol():
    # Spawn python -m backend.server
    proc = subprocess.Popen(
        [sys.executable, "-m", "backend.server"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        encoding="utf-8",
    )

    try:
        # 1. Read ready event
        ready_line = proc.stdout.readline()
        ready_data = json.loads(ready_line)
        assert ready_data.get("event") == "ready"

        # 2. Send system.info request
        req1 = {"id": "req-1", "cmd": "system.info", "args": {}}
        proc.stdin.write(json.dumps(req1) + "\n")
        proc.stdin.flush()

        res1_line = proc.stdout.readline()
        res1 = json.loads(res1_line)
        assert res1.get("id") == "req-1"
        assert res1.get("success") is True
        assert res1["data"]["app_name"] == "DevSync Studio"

        # 3. Send invalid command and verify error handling
        req2 = {"id": "req-2", "cmd": "invalid.command", "args": {}}
        proc.stdin.write(json.dumps(req2) + "\n")
        proc.stdin.flush()

        res2_line = proc.stdout.readline()
        res2 = json.loads(res2_line)
        assert res2.get("id") == "req-2"
        assert res2.get("success") is False
        assert "Unknown command" in res2.get("error", "")

        # 4. Graceful shutdown
        req_exit = {"id": "req-exit", "cmd": "system.shutdown", "args": {}}
        proc.stdin.write(json.dumps(req_exit) + "\n")
        proc.stdin.flush()

        exit_line = proc.stdout.readline()
        exit_res = json.loads(exit_line)
        assert exit_res.get("id") == "req-exit"

        proc.wait(timeout=5.0)
        assert proc.returncode == 0

    finally:
        if proc.poll() is None:
            proc.kill()
