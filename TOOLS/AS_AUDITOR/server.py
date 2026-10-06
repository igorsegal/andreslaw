from pathlib import Path
import os
import subprocess
from mcp.server import MCPServer
REPO_ROOT = Path(r"D:\AHexaTrader\2026.10.04 ANDRESLAW").resolve()
GIT = Path(r"D:\Git\cmd\git.exe")
mcp = MCPServer("AS_Auditor")
def _git(*args: str) -> str:
    env = os.environ.copy()
    # Prevent optional Git operations from refreshing/writing the index.
    env["GIT_OPTIONAL_LOCKS"] = "0"
    result = subprocess.run(
        [str(GIT), "-C", str(REPO_ROOT), *args],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        env=env,
        shell=False,
        timeout=30,
    )
    output = result.stdout
    if result.stderr:
        output += ("\n" if output else "") + result.stderr
    return output.strip()
def _safe_path(relative_path: str) -> Path:
    path = (REPO_ROOT / relative_path).resolve()
    try:
        path.relative_to(REPO_ROOT)
    except ValueError:
        raise ValueError("Path outside ANDRESLAW repository is forbidden")
    return path
@mcp.tool()
def repo_status() -> str:
    """Read Git status of ANDRESLAW. No files are modified."""
    return _git(
        "status",
        "--short",
        "--branch",
        "--untracked-files=all",
    )
@mcp.tool()
def git_diff(staged: bool = False) -> str:
    """Read the current Git diff. Set staged=true for staged changes."""
    if staged:
        return _git("diff", "--cached")
    return _git("diff")
@mcp.tool()
def recent_commits(count: int = 10) -> str:
    """Read recent commits. Count is limited to 1..50."""
    count = max(1, min(count, 50))
    return _git(
        "log",
        f"-{count}",
        "--oneline",
        "--decorate",
    )
@mcp.tool()
def read_file(
    relative_path: str,
    start_line: int = 1,
    max_lines: int = 200,
) -> str:
    """Read a UTF-8 text file inside ANDRESLAW only."""
    path = _safe_path(relative_path)
    if not path.is_file():
        raise ValueError("File does not exist")
    start_line = max(1, start_line)
    max_lines = max(1, min(max_lines, 1000))
    text = path.read_text(
        encoding="utf-8-sig",
        errors="replace",
    )
    lines = text.splitlines()
    begin = start_line - 1
    end = min(begin + max_lines, len(lines))
    result = []
    for index in range(begin, end):
        result.append(f"{index + 1}: {lines[index]}")
    return "\n".join(result)
@mcp.tool()
def search_repo(
    query: str,
    max_results: int = 50,
) -> str:
    """Search literal text in tracked and untracked repository text files."""
    if not query:
        raise ValueError("Query must not be empty")
    max_results = max(1, min(max_results, 200))
    file_list = _git(
        "ls-files",
        "--cached",
        "--others",
        "--exclude-standard",
    )
    results = []
    for relative in file_list.splitlines():
        if len(results) >= max_results:
            break
        path = _safe_path(relative)
        if not path.is_file():
            continue
        try:
            if path.stat().st_size > 2_000_000:
                continue
            text = path.read_text(
                encoding="utf-8-sig",
                errors="replace",
            )
        except OSError:
            continue
        for line_no, line in enumerate(text.splitlines(), 1):
            if query in line:
                results.append(
                    f"{relative}:{line_no}: {line.strip()}"
                )
                if len(results) >= max_results:
                    break
    if not results:
        return "NO_MATCH"
    return "\n".join(results)
@mcp.tool()
def audit_context() -> str:
    """Return the basic read-only context for an independent audit."""
    contract = REPO_ROOT / "docs" / "AS_AUDITOR_CONTRACT_RU.md"
    contract_text = "CONTRACT NOT FOUND"
    if contract.is_file():
        contract_text = contract.read_text(
            encoding="utf-8-sig",
            errors="replace",
        )
    return (
        "=== AS_AUDITOR CONTRACT ===\n"
        + contract_text
        + "\n\n=== GIT STATUS ===\n"
        + repo_status()
        + "\n\n=== UNSTAGED DIFF ===\n"
        + git_diff(False)
        + "\n\n=== STAGED DIFF ===\n"
        + git_diff(True)
    )
if __name__ == "__main__":
    mcp.run()
