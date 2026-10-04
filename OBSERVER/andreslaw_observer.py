from __future__ import annotations

import csv
import json
import re
import subprocess
import sys
from collections import Counter
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OBSERVER = Path(__file__).resolve().parent
DOCS = ROOT / "docs"

STATE_JSON = OBSERVER / "STATE.json"
QUICK_START = OBSERVER / "QUICK_START.md"

TEST_REGISTRY = DOCS / "TEST_REGISTRY.csv"
CURRENT_STATE = DOCS / "CURRENT_STATE_RU.md"
AS_ARCHITECTURE = DOCS / "AS_CANONICAL_ARCHITECTURE_RU.md"
AS_REQUIREMENTS = DOCS / "AS_REQUIREMENTS.csv"
AS_TREND_SPEC = DOCS / "AS_TREND_4_8_SPEC_RU.md"
AS_TREND_MATRIX = DOCS / "AS_TREND_4_8_TEST_MATRIX.csv"

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
    "docs/AS_CANONICAL_ARCHITECTURE_RU.md",
    "docs/AS_REQUIREMENTS.csv",
    "docs/AS_TREND_4_8_SPEC_RU.md",
    "docs/AS_TREND_4_8_TEST_MATRIX.csv",
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


def stage_rank(value):
    m = re.match(r"^(\d+)(?:_FIX(\d+))?$", str(value or "").strip())
    if not m:
        return (-1, -1)
    return (int(m.group(1)), int(m.group(2) or 0))


def load_tests():
    if not TEST_REGISTRY.is_file():
        return []
    with TEST_REGISTRY.open("r", encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))


def _latest_stage_rows(rows):
    if not rows:
        return []
    best = max(stage_rank(r.get("stage")) for r in rows)
    return [r for r in rows if stage_rank(r.get("stage")) == best]


def _status_for_latest_stage(rows):
    current = _latest_stage_rows(rows)
    if not current:
        return "UNKNOWN"
    results = [r.get("result") for r in current]
    if any(x == "FAIL" for x in results):
        return "FAIL"
    if any(x in ("NOT_RUN", "PENDING") for x in results):
        return "PENDING"
    if all(x == "PASS" for x in results):
        return "PASS"
    return "UNKNOWN"


def tests_status():
    rows = load_tests()
    passed = [r for r in rows if r.get("result") == "PASS"]
    failed = [r for r in rows if r.get("result") == "FAIL"]
    pending = [r for r in rows if r.get("result") in ("NOT_RUN", "PENDING")]

    compile_rows = [r for r in rows if r.get("test") == "COMPILE"]
    runtime_rows = [
        r for r in rows
        if (
            str(r.get("test", "")).startswith("RUNTIME")
            or "PIPELINE" in str(r.get("test", ""))
            or "SMOKE" in str(r.get("test", ""))
        )
    ]

    ranked = [r for r in rows if stage_rank(r.get("stage")) != (-1, -1)]
    latest_stage = max((stage_rank(r.get("stage")) for r in ranked), default=None)
    latest_stage_name = None
    if latest_stage is not None:
        for r in reversed(rows):
            if stage_rank(r.get("stage")) == latest_stage:
                latest_stage_name = r.get("stage")
                break

    return {
        "total": len(rows),
        "pass": len(passed),
        "fail_historical": len(failed),
        "pending": len(pending),
        "last_pass": passed[-1] if passed else None,
        "pending_checks": pending,
        "latest_stage": latest_stage_name,
        "compile_status": _status_for_latest_stage(compile_rows),
        "runtime_status": _status_for_latest_stage(runtime_rows),
    }


def load_requirements():
    if not AS_REQUIREMENTS.is_file():
        return []
    with AS_REQUIREMENTS.open("r", encoding="utf-8-sig", newline="") as f:
        return list(csv.DictReader(f))


def requirements_status():
    rows = load_requirements()
    impl = Counter((r.get("IMPLEMENTATION_STATUS") or "UNKNOWN") for r in rows)
    tests = Counter((r.get("TEST_STATUS") or "UNKNOWN") for r in rows)
    trend_rows = [r for r in rows if str(r.get("ID", "")).startswith("AS-TREND-")]

    next_requirement = None
    for r in rows:
        if r.get("IMPLEMENTATION_STATUS") in ("PARTIAL", "MISSING", "IN_TEST"):
            next_requirement = {
                "id": r.get("ID"),
                "domain": r.get("DOMAIN"),
                "status": r.get("IMPLEMENTATION_STATUS"),
                "test_id": r.get("TEST_ID"),
                "test_status": r.get("TEST_STATUS"),
            }
            break

    trend_spec_ready = AS_TREND_SPEC.is_file() and AS_TREND_MATRIX.is_file()

    return {
        "total": len(rows),
        "implementation": dict(impl),
        "tests": dict(tests),
        "trend_requirements": len(trend_rows),
        "trend_4_8_spec": "PASS" if trend_spec_ready else "FAIL",
        "next_requirement": next_requirement,
    }


def doc_facts():
    try:
        text = CURRENT_STATE.read_text(encoding="utf-8-sig")
    except Exception:
        text = ""

    m = re.search(r"Статус:\s*\*\*(.+?)\*\*", text)
    return {
        "checkpoint": m.group(1).strip() if m else None,
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
    q = requirements_status()
    d = doc_facts()

    ready = (
        g["available"]
        and s["status"] == "PASS"
        and t["compile_status"] != "FAIL"
        and t["runtime_status"] != "FAIL"
        and d["trading_lock"]
        and d["cfg_disabled"]
    )

    return {
        "schema": "andreslaw-observer-state-v2",
        "generated_at_local": datetime.now().astimezone().isoformat(timespec="seconds"),
        "project": {
            "name": "ANDRESLAW",
            "root": str(ROOT),
            "status": "READY" if ready else "ATTENTION",
            "checkpoint": d["checkpoint"] or "UNKNOWN",
        },
        "safety": {
            "trading_lock": d["trading_lock"],
            "cfg_disabled": d["cfg_disabled"],
            "trading": "LOCKED" if d["trading_lock"] and d["cfg_disabled"] else "VERIFY",
        },
        "git": g,
        "source": s,
        "tests": t,
        "requirements": q,
        "next_action": next_action(t),
        "canonical_docs": [
            "docs/CURRENT_STATE_RU.md",
            "docs/RECOVERY_PROTOCOL_RU.md",
            "docs/TEST_REGISTRY.csv",
            "docs/AS_CANONICAL_ARCHITECTURE_RU.md",
            "docs/AS_REQUIREMENTS.csv",
            "docs/AS_TREND_4_8_SPEC_RU.md",
            "docs/AS_TREND_4_8_TEST_MATRIX.csv",
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
    q = state["requirements"]
    a = state["next_action"]
    z = state["safety"]

    impl = q.get("implementation") or {}

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
        "- PASS=" + str(t["pass"]) + " HISTORICAL_FAIL=" + str(t["fail_historical"]) + " PENDING=" + str(t["pending"]),
        "- latest stage: " + str(t.get("latest_stage")),
        "- compile: " + t["compile_status"],
        "- runtime: " + t["runtime_status"],
        "",
        "## SPECIFICATION",
        "- requirements: " + str(q["total"]),
        "- implemented: " + str(impl.get("IMPLEMENTED", 0)),
        "- partial: " + str(impl.get("PARTIAL", 0)),
        "- missing: " + str(impl.get("MISSING", 0)),
        "- quarantine: " + str(impl.get("QUARANTINE", 0)),
        "- AS Trend 4..8 source spec: " + q["trend_4_8_spec"],
        "- next requirement: " + str(q.get("next_requirement")),
        "",
        "## NEXT RUNTIME ACTION",
        "- status: " + str(a.get("status")),
        "- stage: " + str(a.get("stage")),
        "- test: " + str(a.get("test")),
        "- target: " + str(a.get("target")),
        "- notes: " + str(a.get("notes")),
        "",
        "## HANDOFF",
        "1. Keep trading disabled.",
        "2. Read AS canonical architecture and requirements before changing recovered logic.",
        "3. Stage 6 FIX1 current-TF runtime remains pending until a new M5 tick/bar is observed.",
        "4. Independent research path: implement AS Trend 4..8 self-test from the frozen matrix before editing sig_trend.mqh.",
        "5. Observer writes only STATE.json and QUICK_START.md inside OBSERVER.",
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
    q = state["requirements"]
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
    print("TEST_PASS=" + str(t["pass"]) + " HISTORICAL_FAIL=" + str(t["fail_historical"]) + " TEST_PENDING=" + str(t["pending"]))
    print("LATEST_STAGE=" + str(t.get("latest_stage")))
    print("COMPILE=" + t["compile_status"])
    print("RUNTIME=" + t["runtime_status"])
    print("REQUIREMENTS=" + str(q["total"]))
    print("AS_TREND_4_8_SPEC=" + q["trend_4_8_spec"])
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

    if cmd == "requirements":
        print(json.dumps(requirements_status(), ensure_ascii=False, indent=2))
        return 0

    print(
        "Usage: andreslaw_observer.py [status|fast-start|json|quick-start|requirements]",
        file=sys.stderr,
    )
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
