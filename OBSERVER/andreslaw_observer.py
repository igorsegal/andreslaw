from __future__ import annotations

import csv
import json
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OBSERVER = Path(__file__).resolve().parent
DOCS = ROOT / "docs"
STATE_JSON = OBSERVER / "STATE.json"
QUICK_START = OBSERVER / "QUICK_START.md"
TEST_REGISTRY = DOCS / "TEST_REGISTRY.csv"
CURRENT_STATE = DOCS / "CURRENT_STATE_RU.md"

CANONICAL_FILES = [
    "MQL4/Experts/Andreslav_AS.mq4",
    "MQL4/Experts/AS_ModulesCompileTest.mq4",
    "MQL4/Indicators/AS/AS_Waves.mq4",
    "MQL4/Indicators/AS/AS_Targets.mq4",
    "MQL4/Include/AS/wave_provider.mqh",
    "MQL4/Include/AS/as_integration.mqh",
    "docs/CURRENT_STATE_RU.md",
    "docs/RECOVERY_PROTOCOL_RU.md",
    "docs/TEST_REGISTRY.csv",
]

WRITE_ALLOWLIST = {STATE_JSON.resolve(), QUICK_START.resolve()}


def run_git(*args):
    try:
        p = subprocess.run(
            ["git", "-C", str(ROOT), *args],
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=15,
            check=False,
        )
        out = (p.stdout or "").strip()
        if p.returncode and p.stderr:
            out = p.stderr.strip()
        return p.returncode, out
    except Exception as exc:
        return 1, type(exc).__name__ + ": " + str(exc)


def git_status():
    rb, branch = run_git("branch", "--show-current")
    rh, head = run_git("rev-parse", "HEAD")
    rs, short = run_git("rev-parse", "--short=8", "HEAD")
    rt, porcelain = run_git("status", "--porcelain")
    changed = [x for x in porcelain.splitlines() if x.strip()] if rt == 0 else []
    return {
        "available": all(x == 0 for x in (rb, rh, rs, rt)),
        "branch": branch if rb == 0 else None,
        "head": head if rh == 0 else None,
        "short_head": short if rs == 0 else None,
        "clean": len(changed) == 0 if rt == 0 else None,
        "changed_files": changed,
    }


def source_status():
    missing = [x for x in CANONICAL_FILES if not (ROOT / x).is_file()]
    return {
        "status": "PASS" if not missing else "FAIL",
        "required": len(CANONICAL_FILES),
        "present": len(CANONICAL_FILES) - len(missing),
        "missing": missing,
    }


def load_tests():
    if not TEST_REGISTRY.is_file():
        return []
    with TEST_REGISTRY.open("r", encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))


def tests_status():
    rows = load_tests()
    passed = [r for r in rows if r.get("result") == "PASS"]
    failed = [r for r in rows if r.get("result") == "FAIL"]
    pending = [r for r in rows if r.get("result") in ("NOT_RUN", "PENDING")]
    compile_rows = [r for r in rows if r.get("test") == "COMPILE"]
    runtime_rows = [r for r in rows if str(r.get("test", "")).startswith("RUNTIME")]
    compile_fail = [r for r in compile_rows if r.get("result") != "PASS"]
    runtime_fail = [r for r in runtime_rows if r.get("result") == "FAIL"]
    stages = []
    for r in passed:
        try:
            stages.append(int(r.get("stage", "0")))
        except ValueError:
            pass
    return {
        "total": len(rows),
        "pass": len(passed),
        "fail": len(failed),
        "pending": len(pending),
        "last_pass": passed[-1] if passed else None,
        "pending_checks": pending,
        "max_pass_stage": max(stages) if stages else None,
        "compile_status": "FAIL" if compile_fail else ("PENDING" if compile_pending else ("PASS" if compile_rows else "UNKNOWN")),
        "runtime_status": "PASS" if runtime_rows and not runtime_fail else ("FAIL" if runtime_fail else "UNKNOWN"),
    }


def doc_facts():
    try:
        text = CURRENT_STATE.read_text(encoding="utf-8-sig")
    except Exception:
        text = ""
    m = re.search(r"RECOVERY STAGE\s+\d+[^\r\n]*", text)
    return {
        "checkpoint": m.group(0).strip("* ") if m else None,
        "trading_lock": "trading_lock=1" in text,
        "cfg_disabled": "cfg.enabled=false" in text,
    }


def next_action(tests):
    pending = tests.get("pending_checks") or []
    if not pending:
        return {"status": "NONE", "text": "No pending test in TEST_REGISTRY.csv"}
    r = pending[0]
    return {
        "status": r.get("result"),
        "stage": r.get("stage"),
        "test": r.get("test"),
        "target": r.get("target"),
        "evidence": r.get("evidence"),
        "notes": r.get("notes"),
        "text": "Run " + str(r.get("test")) + " for " + str(r.get("target")),
    }


def collect_state():
    g = git_status()
    s = source_status()
    t = tests_status()
    d = doc_facts()
    ready = g["available"] and s["status"] == "PASS" and t["fail"] == 0
    return {
        "schema": "andreslaw-observer-state-v1",
        "generated_at_local": datetime.now().astimezone().isoformat(timespec="seconds"),
        "project": {
            "name": "ANDRESLAW",
            "root": str(ROOT),
            "status": "READY" if ready else "ATTENTION",
            "checkpoint": d["checkpoint"] or ("RECOVERY STAGE " + str(t["max_pass_stage"]) if t["max_pass_stage"] else "UNKNOWN"),
        },
        "safety": {
            "trading_lock": d["trading_lock"],
            "cfg_disabled": d["cfg_disabled"],
            "trading": "LOCKED" if d["trading_lock"] and d["cfg_disabled"] else "VERIFY",
        },
        "git": g,
        "source": s,
        "tests": t,
        "next_action": next_action(t),
        "canonical_docs": [
            "docs/CURRENT_STATE_RU.md",
            "docs/RECOVERY_PROTOCOL_RU.md",
            "docs/TEST_REGISTRY.csv",
        ],
    }


def safe_write(path, text):
    if path.resolve() not in WRITE_ALLOWLIST:
        raise RuntimeError("Write blocked outside OBSERVER")
    path.write_text(text, encoding="utf-8")


def render_quick_start(state):
    p = state["project"]
    g = state["git"]
    s = state["source"]
    t = state["tests"]
    a = state["next_action"]
    z = state["safety"]
    lines = [
        "# ANDRESLAW FAST START",
        "",
        "Generated: " + state["generated_at_local"],
        "",
        "## PROJECT",
        "- root: " + p["root"],
        "- status: " + p["status"],
        "- checkpoint: " + str(p["checkpoint"]),
        "- trading: " + z["trading"],
        "",
        "## GIT",
        "- branch: " + str(g.get("branch") or "UNKNOWN"),
        "- head: " + str(g.get("short_head") or "UNKNOWN"),
        "- working tree: " + ("CLEAN" if g.get("clean") is True else "DIRTY/UNKNOWN"),
        "",
        "## SOURCE",
        "- canonical files: " + s["status"] + " (" + str(s["present"]) + "/" + str(s["required"]) + ")",
        "",
        "## TESTS",
        "- PASS=" + str(t["pass"]) + " FAIL=" + str(t["fail"]) + " PENDING=" + str(t["pending"]),
        "- compile: " + t["compile_status"],
        "- runtime evidence: " + t["runtime_status"],
        "",
        "## NEXT ACTION",
        "- status: " + str(a.get("status")),
        "- stage: " + str(a.get("stage")),
        "- test: " + str(a.get("test")),
        "- target: " + str(a.get("target")),
        "- notes: " + str(a.get("notes")),
        "",
        "## HANDOFF",
        "1. Keep trading disabled.",
        "2. Read canonical docs before changing recovered logic.",
        "3. Complete NEXT ACTION before advancing recovery stage.",
        "4. Observer writes only STATE.json and QUICK_START.md inside OBSERVER.",
        "",
    ]
    return "\n".join(lines)


def write_snapshot(state):
    safe_write(STATE_JSON, json.dumps(state, ensure_ascii=False, indent=2) + "\n")
    safe_write(QUICK_START, render_quick_start(state))


def print_status(state):
    p = state["project"]
    g = state["git"]
    s = state["source"]
    t = state["tests"]
    a = state["next_action"]
    z = state["safety"]
    print("ASO Lilit")
    print("=========")
    print("PROJECT=" + p["status"])
    print("CHECKPOINT=" + str(p["checkpoint"]))
    print("GIT_BRANCH=" + str(g.get("branch") or "UNKNOWN"))
    print("GIT_HEAD=" + str(g.get("short_head") or "UNKNOWN"))
    print("GIT_CLEAN=" + str(g.get("clean")))
    print("SOURCE=" + s["status"])
    print("TEST_PASS=" + str(t["pass"]) + " TEST_FAIL=" + str(t["fail"]) + " TEST_PENDING=" + str(t["pending"]))
    print("COMPILE=" + t["compile_status"])
    print("RUNTIME=" + t["runtime_status"])
    print("TRADING=" + z["trading"])
    print("")
    print("NEXT_ACTION=" + a["text"])


def main():
    cmd = sys.argv[1].lower() if len(sys.argv) > 1 else "status"
    state = collect_state()
    if cmd in ("status", "fast-start", "fast_start"):
        write_snapshot(state)
        print_status(state)
        print("WROTE=" + str(STATE_JSON))
        print("WROTE=" + str(QUICK_START))
        return 0
    if cmd == "json":
        print(json.dumps(state, ensure_ascii=False, indent=2))
        return 0
    if cmd == "quick-start":
        print(render_quick_start(state))
        return 0
    print("Usage: andreslaw_observer.py [status|fast-start|json|quick-start]", file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
