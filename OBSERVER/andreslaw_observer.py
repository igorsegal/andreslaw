from __future__ import annotations

import csv
import json
import subprocess
import sys
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OBSERVER_DIR = Path(__file__).resolve().parent
DOCS = ROOT / "docs"

STATE_JSON = OBSERVER_DIR / "STATE.json"
QUICK_START_MD = OBSERVER_DIR / "QUICK_START.md"
CURRENT_STATE = DOCS / "CURRENT_STATE_RU.md"
RECOVERY_PROTOCOL = DOCS / "RECOVERY_PROTOCOL_RU.md"
TEST_REGISTRY = DOCS / "TEST_REGISTRY.csv"

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

WRITE_ALLOWLIST = {STATE_JSON.resolve(), QUICK_START_MD.resolve()}


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
        return 1, f"{type(exc).__name__}: {exc}"


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
    missing = [rel for rel in CANONICAL_FILES if not (ROOT / rel).is_file()]
    return {
        "status": "PASS" if not missing else "FAIL",
        "required": len(CANONICAL_FILES),
        "present": len(CANONICAL_FILES) - len(missing),
        "missing": missing,
    }


def read_text(path):
    try:
        return path.read_text(encoding="utf-8-sig")
    except Exception:
        return ""


def section(text, heading):
    marker = "## " + heading
    pos = text.find(marker)
    if pos < 0:
        return ""
    body = text[pos + len(marker):].lstrip("\r\n")
    nxt = body.find("\n## ")
    return (body if nxt < 0 else body[:nxt]).strip()


def checkpoint(text):
    for line in text.splitlines():
        if line.startswith("Ð¡Ñ‚Ð°Ñ‚ÑƒÑ:"):
            return line.split(":", 1)[1].strip().strip("*")
    return None


def test_status():
    rows = []
    if TEST_REGISTRY.exists():
        with TEST_REGISTRY.open("r", encoding="utf-8-sig", newline="") as f:
            rows = list(csv.DictReader(f))
    passed = [r for r in rows if r.get("result") == "PASS"]
    failed = [r for r in rows if r.get("result") == "FAIL"]
    pending = [r for r in rows if r.get("result") in ("NOT_RUN", "PENDING")]
    compile_rows = [r for r in rows if r.get("test") == "COMPILE"]
    compile_failed = [r for r in compile_rows if r.get("result") != "PASS"]
    runtime_rows = [r for r in rows if str(r.get("test", "")).startswith("RUNTIME")]
    runtime_failed = [r for r in runtime_rows if r.get("result") == "FAIL"]
    return {
        "total": len(rows),
        "pass": len(passed),
        "fail": len(failed),
        "pending": len(pending),
        "last_record": rows[-1] if rows else None,
        "last_pass": passed[-1] if passed else None,
        "compile_status": "PASS" if compile_rows and not compile_failed else ("FAIL" if compile_failed else "UNKNOWN"),
        "runtime_status": "PASS" if runtime_rows and not runtime_failed else ("FAIL" if runtime_failed else "UNKNOWN"),
        "pending_checks": pending,
    }


def collect_state():
    current = read_text(CURRENT_STATE)
    protocol = read_text(RECOVERY_PROTOCOL)
    g = git_status()
    s = source_status()
    t = test_status()
    ready = s["status"] == "PASS" and t["fail"] == 0 and g["available"]
    return {
        "schema": "andreslaw-observer-state-v1",
        "generated_at_local": datetime.now().astimezone().isoformat(timespec="seconds"),
        "project": {
            "name": "ANDRESLAW",
            "root": str(ROOT),
            "status": "READY" if ready else "ATTENTION",
            "checkpoint": checkpoint(current),
            "trading": "LOCKED",
        },
        "git": g,
        "source": s,
        "tests": t,
        "continuation": {
            "next_required_test": section(protocol, "Ð¡Ð»ÐµÐ´ÑƒÑŽÑ‰Ð¸Ð¹ Ð¾Ð±ÑÐ·Ð°Ñ‚ÐµÐ»ÑŒÐ½Ñ‹Ð¹ Ñ‚ÐµÑÑ‚"),
            "not_confirmed": section(current, "Ð§Ñ‚Ð¾ Ð¿Ð¾ÐºÐ° ÐÐ• Ð¿Ð¾Ð´Ñ‚Ð²ÐµÑ€Ð¶Ð´ÐµÐ½Ð¾"),
            "not_restored": section(current, "Ð§Ñ‚Ð¾ ÐµÑ‰Ñ‘ Ð½Ðµ ÑÑ‡Ð¸Ñ‚Ð°ÐµÑ‚ÑÑ Ð´Ð¾ÑÑ‚Ð¾Ð²ÐµÑ€Ð½Ð¾ Ð²Ð¾ÑÑÑÑ‚Ð°Ð½Ð¾Ð²Ð»ÐµÐ½Ð½Ñ‹Ð¼"),
        },
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
    c = state["continuation"]
    lines = [
        "# ANDRESLAW FAST START",
        "",
        "Generated: " + state["generated_at_local"],
        "",
        "## PROJECT",
        "- root: " + p["root"],
        "- status: " + p["status"],
        "- checkpoint: " + str(p.get("checkpoint") or "UNKNOWN"),
        "- trading: LOCKED",
        "",
        "## GIT",
        "- branch: " + str(g.get("branch") or "UNKNOWN"),
        "- head: " + str(g.get("short_head") or "UNKNOWN"),
        "- working tree: " + ("CLEAN" if g.get("clean") is True else "DIRTY/UNKNOWN"),
        "",
        "## SOURCE",
        f"- canonical files: {s['status']} ({s['present']}/{s['required']})",
        "",
        "## TESTS",
        f"- PASS={t['pass']} FAIL={t['fail']} PENDING={t['pending']}",
        "- compile: " + t["compile_status"],
        "- runtime evidence: " + t["runtime_status"],
        "",
        "## NEXT REQUIRED TEST",
        c["next_required_test"] or "UNKNOWN",
        "",
        "## DO NOT ASSUME RESTORED",
        c["not_restored"] or "No explicit list found.",
        "",
        "## NOT YET CONFIRMED",
        c["not_confirmed"] or "No explicit list found.",
        "",
        "## HANDOFF RULES",
        "1. Do not enable trading.",
        "2. Read docs/CURRENT_STATE_RU.md and docs/RECOVERY_PROTOCOL_RU.md before changing recovered logic.",
        "3. Execute NEXT REQUIRED TEST before declaring further recovery progress.",
        "4. Observer may write only OBSERVER/STATE.json and OBSERVER/QUICK_START.md.",
        "",
    ]
    return "\n".join(lines)


def write_snapshot(state):
    safe_write(STATE_JSON, json.dumps(state, ensure_ascii=False, indent=2) + "\n")
    safe_write(QUICK_START_MD, render_quick_start(state))


def print_status(state):
    p = state["project"]
    g = state["git"]
    s = state["source"]
    t = state["tests"]
    print("ANDRESLAW OBSERVER")
    print("==================")
    print("PROJECT=" + p["status"])
    print("CHECKPOINT=" + str(p.get("checkpoint") or "UNKNOWN"))
    print("GITÐ”SÒHˆ
ÈÝŠË™Ù]
˜œ˜[˜ÚŠHÜˆ•S’Ó“ÕÓˆŠJBˆš[
‘ÒUÒPQHˆ
ÈÝŠË™Ù]
œÚÜÚXYŠHÜˆ•S’Ó“ÕÓˆŠJBˆš[
‘ÒUÐÓPSHˆ
ÈÝŠË™Ù]
˜ÛX[ˆŠJJBˆš[
”ÓÕTÑOHˆ
ÈÖÈœÝ]\È—JBˆš[
ˆ•TÕÔTÔÏ^ÝÉÜ\ÜÉ×_HTÕÑRS^ÝÉÙ˜Z[	×_HTÕÔS‘S‘Ï^ÝÉÜ[™[™É×_HŠBˆš[
ÓÓTSOHˆ
ÈÈ˜ÛÛ\[WÜÝ]\È—JBˆš[
”•S•SQOHˆ
ÈÈœ[[YWÜÝ]\È—JBˆš[
•QS‘ÏSÐÒÑQŠBˆš[
ˆŠBˆš[
“‘V‘TURT‘QTÕˆŠBˆš[
Ý]VÈ˜ÛÛ[X][Ûˆ—VÈ›™^Ü™\]Z\™YÝ\Ý—HÜˆ•S’Ó“ÕÓˆŠB‚‚™YˆXZ[Š
N‚ˆÛYHÞ\Ë˜\™Ý–ÌWK›ÝÙ\Š
HYˆ[ŠÞ\Ë˜\™ÝŠHˆH[ÙHœÝ]\È‚ˆÝ]HHÛÛXÝÜÝ]J
BˆYˆÛY[ˆ
œÝ]\È‹™˜\Ý\Ý\‹™˜\ÝÜÝ\ŠN‚ˆÜš]WÜÛ˜\ÚÝ
Ý]JBˆš[ÜÝ]\ÊÝ]JBˆš[
ˆŠBˆš[
•Ô“ÕOHˆ
ÈÝŠÕUWÒ”ÓÓŠJBˆš[
•Ô“ÕOHˆ
ÈÝŠURPÒ×ÔÕT•ÓQ
JBˆ™]\›ˆˆYˆÛYOHšœÛÛˆŽ‚ˆš[
œÛÛ‹™[\ÊÝ]K[œÝ\™WØ\ØÚZOQ˜[ÙK[™[LŠJBˆ™]\›ˆˆYˆÛYOHœ]ZXÚË\Ý\Ž‚ˆš[
™[™\—Ü]ZXÚ×ÜÝ\
Ý]JJBˆ™]\›ˆˆš[
•\ØYÙNˆ[™™\Û]×ÛØœÙ\™\‹œHÜÝ]\ß˜\Ý\Ý\œÛÛŸ]ZXÚË\Ý\H‹š[O\Þ\ËœÝ\œŠBˆ™]\›ˆ‚‚‚šYˆ×Û˜[YW×ÈOH—×ÛXZ[—×ÈŽ‚ˆ˜Z\ÙHÞ\Ý[Q^]
XZ[Š
JB