// SwooshArena/GameCLIStarterFactoryTemplates.swift — Cartridge generated CLI templates (0.1A)

extension GameCLIStarterFactory {
    static let commonPrelude = #"""
from __future__ import annotations

import argparse
import json
from dataclasses import asdict, dataclass
from typing import Any


AGENT_NAME = "Cartridge"
TITLE = "__TITLE__"
KIND = "__KIND__"


@dataclass
class Result:
    agent: str
    kind: str
    command: str
    title: str
    payload: dict[str, Any]


def emit(result: Result, json_output: bool) -> int:
    if json_output:
        print(json.dumps(asdict(result), indent=2, sort_keys=True))
    else:
        print(f"{result.agent} {result.command}: {result.payload}")
    return 0


def prompt_payload(args: argparse.Namespace) -> dict[str, Any]:
    return {
        "text": args.text,
        "voiceTranscript": args.voice_transcript,
        "visionSummary": args.vision_summary,
        "policy": args.policy,
    }

"""#

    static let gameCLI = commonPrelude + #"""

def run(args: argparse.Namespace) -> int:
    payload = vars(args).copy()
    payload.pop("func", None)
    payload.pop("json", None)
    if args.command == "prompt":
        payload = prompt_payload(args)
    return emit(Result(AGENT_NAME, KIND, args.command, TITLE, payload), args.json)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="__EXECUTABLE__", description="Cartridge game starter CLI.")
    parser.add_argument("--json", action="store_true")
    sub = parser.add_subparsers(dest="command", required=True)
    for name in ["init", "load-url", "playbook", "test-run", "manifest"]:
        item = sub.add_parser(name)
        item.add_argument("--title", default=TITLE)
        item.add_argument("--url")
        item.add_argument("--engine", default="threejs")
        item.add_argument("--policy", default="nitrogen")
        item.set_defaults(func=run)
    prompt = sub.add_parser("prompt")
    prompt.add_argument("--text")
    prompt.add_argument("--voice-transcript")
    prompt.add_argument("--vision-summary")
    prompt.add_argument("--policy", default="nitrogen")
    prompt.set_defaults(func=run)
    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    raise SystemExit(args.func(args))

"""#

    static let agentCLI = commonPrelude + #"""

def run(args: argparse.Namespace) -> int:
    payload = vars(args).copy()
    payload.pop("func", None)
    payload.pop("json", None)
    if args.command == "policy":
        payload["usesNitroGen"] = args.mode in {"nitrogen", "hybrid"}
    return emit(Result(AGENT_NAME, KIND, args.command, TITLE, payload), args.json)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="__EXECUTABLE__", description="Cartridge agent starter CLI.")
    parser.add_argument("--json", action="store_true")
    sub = parser.add_subparsers(dest="command", required=True)
    for name in ["init", "observe", "act", "evaluate", "manifest"]:
        item = sub.add_parser(name)
        item.add_argument("--session")
        item.add_argument("--text")
        item.add_argument("--voice-transcript")
        item.add_argument("--vision-summary")
        item.add_argument("--policy", default="hybrid")
        item.set_defaults(func=run)
    policy = sub.add_parser("policy")
    policy.add_argument("--mode", choices=["nitrogen", "provider-llm", "hybrid", "scripted"], default="hybrid")
    policy.add_argument("--provider")
    policy.add_argument("--model")
    policy.set_defaults(func=run)
    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    raise SystemExit(args.func(args))

"""#

    static let characterCLI = commonPrelude + #"""

def run(args: argparse.Namespace) -> int:
    payload = vars(args).copy()
    payload.pop("func", None)
    payload.pop("json", None)
    if args.command == "create":
        payload.update(prompt_payload(args))
    return emit(Result(AGENT_NAME, KIND, args.command, TITLE, payload), args.json)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="__EXECUTABLE__", description="Cartridge character starter CLI.")
    parser.add_argument("--json", action="store_true")
    sub = parser.add_subparsers(dest="command", required=True)
    create = sub.add_parser("create")
    create.add_argument("--name", default=TITLE)
    create.add_argument("--text")
    create.add_argument("--voice-transcript")
    create.add_argument("--vision-summary")
    create.add_argument("--policy", default="hybrid")
    create.set_defaults(func=run)
    for name in ["voice", "sprite", "model3d", "persona", "export"]:
        item = sub.add_parser(name)
        item.add_argument("--name", default=TITLE)
        item.add_argument("--provider")
        item.add_argument("--format", default="json")
        item.set_defaults(func=run)
    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    raise SystemExit(args.func(args))

"""#
    static let laptopCLI = commonPrelude + #"""
import platform
import subprocess
import tempfile
from pathlib import Path


def require_macos() -> None:
    if platform.system() != "Darwin":
        raise SystemExit("local execution is currently implemented for macOS")


def run_process(args: list[str]) -> dict[str, Any]:
    completed = subprocess.run(args, text=True, capture_output=True, check=False)
    return {
        "argv": args,
        "exitCode": completed.returncode,
        "stdout": completed.stdout,
        "stderr": completed.stderr,
    }


def osascript(script: str) -> dict[str, Any]:
    return run_process(["/usr/bin/osascript", "-e", script])


def maybe_execute(args: argparse.Namespace, payload: dict[str, Any]) -> dict[str, Any]:
    if not getattr(args, "execute", False):
        return payload
    require_macos()
    command = args.command
    if command == "screenshot":
        path = Path(args.path or Path(tempfile.gettempdir()) / "cartridge-screenshot.png")
        payload["execution"] = run_process(["/usr/sbin/screencapture", "-x", str(path)])
        payload["path"] = str(path)
    elif command == "open-app":
        payload["execution"] = run_process(["/usr/bin/open", "-a", args.app])
    elif command == "focus-app":
        payload["execution"] = osascript(f'tell application "{args.app}" to activate')
    elif command == "open-url":
        payload["execution"] = run_process(["/usr/bin/open", args.url])
    elif command == "click":
        payload["execution"] = osascript(f'tell application "System Events" to click at {{{args.x}, {args.y}}}')
    elif command == "type":
        escaped = args.text.replace("\\", "\\\\").replace('"', '\\"')
        payload["execution"] = osascript(f'tell application "System Events" to keystroke "{escaped}"')
    elif command == "hotkey":
        escaped = args.key.replace("\\", "\\\\").replace('"', '\\"')
        modifiers = ", ".join(f"{item.strip()} down" for item in args.modifier if item.strip())
        suffix = f" using {{{modifiers}}}" if modifiers else ""
        payload["execution"] = osascript(f'tell application "System Events" to keystroke "{escaped}"{suffix}')
    return payload


def run(args: argparse.Namespace) -> int:
    if args.command == "prompt":
        payload = {
            "voiceTranscript": args.voice_transcript,
            "text": args.text,
            "visionSummary": args.vision_summary,
            "plan": [
                {"command": "screenshot"},
                {"command": "focus-app", "app": args.app},
                {"command": "click", "target": args.target},
            ],
        }
    else:
        payload = vars(args).copy()
        payload.pop("func", None)
        payload.pop("json", None)
        payload = maybe_execute(args, payload)
    return emit(Result(AGENT_NAME, KIND, args.command, TITLE, payload), args.json)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="__EXECUTABLE__", description="Cartridge laptop navigator CLI.")
    parser.add_argument("--json", action="store_true")
    sub = parser.add_subparsers(dest="command", required=True)

    prompt = sub.add_parser("prompt")
    prompt.add_argument("--text")
    prompt.add_argument("--voice-transcript")
    prompt.add_argument("--vision-summary")
    prompt.add_argument("--app", default="Safari")
    prompt.add_argument("--target", default="current game")
    prompt.set_defaults(func=run)

    screenshot = sub.add_parser("screenshot")
    screenshot.add_argument("--path")
    screenshot.add_argument("--execute", action="store_true")
    screenshot.set_defaults(func=run)

    open_app = sub.add_parser("open-app")
    open_app.add_argument("--app", required=True)
    open_app.add_argument("--execute", action="store_true")
    open_app.set_defaults(func=run)

    focus_app = sub.add_parser("focus-app")
    focus_app.add_argument("--app", required=True)
    focus_app.add_argument("--execute", action="store_true")
    focus_app.set_defaults(func=run)

    open_url = sub.add_parser("open-url")
    open_url.add_argument("--url", required=True)
    open_url.add_argument("--execute", action="store_true")
    open_url.set_defaults(func=run)

    click = sub.add_parser("click")
    click.add_argument("--x", type=int, required=True)
    click.add_argument("--y", type=int, required=True)
    click.add_argument("--execute", action="store_true")
    click.set_defaults(func=run)

    type_text = sub.add_parser("type")
    type_text.add_argument("--text", required=True)
    type_text.add_argument("--execute", action="store_true")
    type_text.set_defaults(func=run)

    hotkey = sub.add_parser("hotkey")
    hotkey.add_argument("--key", required=True)
    hotkey.add_argument("--modifier", action="append", default=[])
    hotkey.add_argument("--execute", action="store_true")
    hotkey.set_defaults(func=run)

    plan = sub.add_parser("plan")
    plan.add_argument("--text")
    plan.add_argument("--voice-transcript")
    plan.add_argument("--vision-summary")
    plan.set_defaults(func=run)
    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    raise SystemExit(args.func(args))

"""#
}
