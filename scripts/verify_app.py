import subprocess
import time
import os
import sys

def verify_desktop_app():
    # Test packaged standalone executable in dist/
    exe_path = os.path.abspath("dist/DevSyncStudio/DevSyncStudio.exe")
    if not os.path.exists(exe_path):
        exe_path = os.path.abspath("build/DevSyncStudio.exe")

    print(f"Launching {exe_path}...")
    env = os.environ.copy()
    env["PATH"] = r"C:\Qt\6.8.3\msvc2022_64\bin;" + env.get("PATH", "")

    proc = subprocess.Popen([exe_path], env=env)
    print(f"Process launched with PID: {proc.pid}")

    time.sleep(3)

    poll = proc.poll()
    if poll is None:
        print("SUCCESS: DevSyncStudio launched and remained running stably!")
        proc.terminate()
        try:
            proc.wait(timeout=3)
        except Exception:
            proc.kill()
        sys.exit(0)
    else:
        print(f"FAIL: DevSyncStudio exited prematurely with code {poll}")
        sys.exit(1)

if __name__ == "__main__":
    verify_desktop_app()
