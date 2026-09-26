"""Run the complete HardSync local development stack with one command."""

from __future__ import annotations

import argparse
import os
import signal
import shutil
import subprocess
import sys
import time
from pathlib import Path
from urllib.request import urlopen


ROOT = Path(__file__).resolve().parents[1]


def server_python() -> str:
    """Use this project's own .venv (server/requirements.txt) when it exists,
    so the backend's dependencies (e.g. google-genai) stay isolated from
    whatever else is installed on the machine's global Python."""
    suffix = "Scripts" if os.name == "nt" else "bin"
    name = "python.exe" if os.name == "nt" else "python"
    venv_python = ROOT / ".venv" / suffix / name
    return str(venv_python) if venv_python.exists() else sys.executable


def flutter_command(device: str) -> list[str]:
    executable = shutil.which("flutter")
    if not executable:
        raise RuntimeError(
            "Flutter was not found on PATH. Add C:\\flutter\\bin to PATH and reopen PowerShell."
        )
    arguments = [executable, "run", "-d", device]
    if os.name == "nt" and Path(executable).suffix.lower() in (".bat", ".cmd"):
        # CreateProcess cannot launch batch files directly on Windows.
        command = subprocess.list2cmdline(arguments)
        return [os.environ.get("COMSPEC", "cmd.exe"), "/d", "/s", "/c", command]
    return arguments


def wait_for_http(url: str, process: subprocess.Popen, timeout: float = 30) -> None:
    deadline = time.time() + timeout
    while time.time() < deadline:
        if process.poll() is not None:
            raise RuntimeError(f"Service stopped before becoming ready: {url}")
        try:
            with urlopen(url, timeout=1):
                return
        except Exception:
            time.sleep(0.25)
    raise RuntimeError(f"Timed out waiting for {url}")


def http_ready(url: str) -> bool:
    try:
        with urlopen(url, timeout=1) as response:
            return 200 <= response.status < 400
    except Exception:
        return False


def stop(process: subprocess.Popen | None) -> None:
    if process is None or process.poll() is not None:
        return
    process.terminate()
    try:
        process.wait(timeout=5)
    except subprocess.TimeoutExpired:
        process.kill()
        process.wait(timeout=5)


def main() -> int:
    parser = argparse.ArgumentParser(description="Run HardSync locally.")
    parser.add_argument("--device", default="chrome", help="Flutter device ID")
    parser.add_argument("--no-flutter", action="store_true")
    args = parser.parse_args()

    creationflags = (
        subprocess.CREATE_NEW_PROCESS_GROUP if os.name == "nt" else 0
    )
    backend = bridge = flutter = None
    try:
        print("Starting HardSync backend on http://127.0.0.1:8082 â€¦", flush=True)
        backend = subprocess.Popen(
            [server_python(), "server/app.py", "--port", "8082"],
            cwd=ROOT,
            creationflags=creationflags,
        )
        wait_for_http("http://127.0.0.1:8082/api/config", backend)

        print("Starting Gemini Live bridge on ws://127.0.0.1:8000 â€¦", flush=True)
        bridge_docs = "http://127.0.0.1:8000/docs"
        if http_ready(bridge_docs):
            print(
                "Gemini Live bridge is already running; reusing port 8000.",
                flush=True,
            )
        else:
            bridge = subprocess.Popen(
                [
                    server_python(),
                    "-m",
                    "uvicorn",
                    "server.gemini_live_bridge:app",
                    "--host",
                    "127.0.0.1",
                    "--port",
                    "8000",
                ],
                cwd=ROOT,
                creationflags=creationflags,
            )
            wait_for_http(bridge_docs, bridge)
            time.sleep(0.2)
            if bridge.poll() is not None:
                raise RuntimeError(
                    "Port 8000 is already in use by another application. Stop it and retry."
                )

        print("Local services are ready.", flush=True)
        if args.no_flutter:
            print("Press Ctrl+C to stop.", flush=True)
            while True:
                if backend.poll() is not None or (
                    bridge is not None and bridge.poll() is not None
                ):
                    raise RuntimeError("A local service stopped unexpectedly.")
                time.sleep(1)

        print(f"Starting Flutter on {args.device} â€¦", flush=True)
        flutter = subprocess.Popen(
            flutter_command(args.device),
            cwd=ROOT,
            creationflags=creationflags,
        )
        return flutter.wait()
    except KeyboardInterrupt:
        return 130
    except (OSError, RuntimeError) as error:
        print(f"Development stack failed: {error}", file=sys.stderr, flush=True)
        return 1
    finally:
        print("Stopping HardSync local services â€¦", flush=True)
        stop(flutter)
        stop(bridge)
        stop(backend)


if __name__ == "__main__":
    raise SystemExit(main())
