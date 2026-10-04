from __future__ import annotations

import json

import andreslaw_observer as core

try:
    from mcp.server import MCPServer
except ImportError:
    from mcp.server.fastmcp import FastMCP as MCPServer

mcp = MCPServer(
    "ANDRESLAW Observer",
)


@mcp.tool()
def andreslaw_status() -> dict:
    """Return the complete current ANDRESLAW project state."""
    return core.collect_state()


@mcp.tool()
def git_status() -> dict:
    """Return Git branch, HEAD, clean/dirty state, and changed files."""
    return core.git_status()


@mcp.tool()
def source_status() -> dict:
    """Verify that the canonical recovered source files are present."""
    return core.source_status()


@mcp.tool()
def test_status() -> dict:
    """Return compile/runtime/test registry status and pending checks."""
    return core.tests_status()


@mcp.tool()
def next_action() -> dict:
    """Return the first pending recovery action from the canonical test registry."""
    state = core.collect_state()
    return state["next_action"]


@mcp.tool()
def fast_start() -> dict:
    """Refresh STATE.json and QUICK_START.md, then return the same state."""
    state = core.collect_state()
    core.write_snapshot(state)
    return {
        "state": state,
        "quick_start": core.render_quick_start(state),
        "state_json": str(core.STATE_JSON),
        "quick_start_md": str(core.QUICK_START),
    }


if __name__ == "__main__":
    mcp.run()
