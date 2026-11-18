#!/usr/bin/env python3
"""Summarize an exec run (orchestrator + its subagents) from the OpenCode API.

usage: stats.py <session-id> [default-branch] [progress-file]

The main tables are the run itself. Everything after them is best-effort: each
optional section fails on its own and never aborts the report, so this script
cannot block plan completion.
"""

import json
import re
import subprocess
import sys
from urllib.parse import quote

# canonical run order, keyword -> phase. Order matters: a title such as
# "Fix smells findings" is the fixer, not the smells reviewer.
PHASES = (
    ("task loop", ("task",)),
    ("fixer", ("fix",)),
    ("smells", ("smell",)),
    ("critical re-check", ("critical",)),
    ("review", ("review",)),
    ("finalize", ("rebase", "finalize", "squash")),
)
OTHER = "other"


def api(path):
    """Run `opencode api get` and return the decoded JSON response."""
    proc = subprocess.run(
        ["opencode", "api", "get", path],
        capture_output=True,
        text=True,
        timeout=120,
    )
    if proc.returncode != 0:
        raise RuntimeError((proc.stderr or proc.stdout).strip() or "api call failed")
    return json.loads(proc.stdout)


def fetch_subagents(session_id):
    """Page through the child-session list until the cursor is exhausted."""
    subs, cursor = [], None
    while True:
        path = f"/api/session?parentID={session_id}&limit=100"
        if cursor:
            path += "&cursor=" + quote(cursor, safe="")
        page = api(path)
        subs.extend(page.get("data") or [])
        cursor = (page.get("cursor") or {}).get("next")
        if not cursor:
            return subs


def classify(title):
    lowered = (title or "").lower()
    for name, keywords in PHASES:
        if any(keyword in lowered for keyword in keywords):
            return name
    return OTHER


def tokens_of(session):
    tokens = session.get("tokens") or {}
    cache = tokens.get("cache") or {}
    return (
        int(tokens.get("input") or 0),
        int(tokens.get("output") or 0),
        int(tokens.get("reasoning") or 0),
        int(cache.get("read") or 0),
    )


def wall_ms(session):
    timing = session.get("time") or {}
    created = timing.get("created") or 0
    end = timing.get("idle") or timing.get("updated") or created
    return max(0, int(end) - int(created))


def model_label(session):
    model = session.get("model") or {}
    provider = model.get("providerID") or "unknown"
    name = model.get("id") or "unknown"
    variant = model.get("variant")
    return f"{provider}/{name}" + (f"#{variant}" if variant else "")


def empty_bucket():
    return {"n": 0, "wall": 0, "in": 0, "out": 0, "reasoning": 0, "cache": 0}


def add(bucket, session):
    tin, tout, treason, tcache = tokens_of(session)
    bucket["n"] += 1
    bucket["wall"] += wall_ms(session)
    bucket["in"] += tin
    bucket["out"] += tout
    bucket["reasoning"] += treason
    bucket["cache"] += tcache


def fmt_tokens(value):
    if value >= 1_000_000:
        return f"{value / 1_000_000:.2f}M"
    if value >= 1_000:
        return f"{value / 1_000:.0f}K"
    return str(value)


def fmt_wall(milliseconds):
    minutes = milliseconds / 60_000
    if minutes >= 60:
        hours = int(minutes // 60)
        return f"{hours}h{int(minutes % 60):02d}m"
    if minutes >= 10:
        return f"{minutes:.0f}m"
    return f"{minutes:.1f}m"


def bucket_row(label, bucket, bold=False):
    name = f"**{label}**" if bold else label
    return (
        f"| {name} | {bucket['n']} | {fmt_wall(bucket['wall'])} "
        f"| {fmt_tokens(bucket['in'])} | {fmt_tokens(bucket['out'])} "
        f"| {fmt_tokens(bucket['reasoning'])} | {fmt_tokens(bucket['cache'])} |"
    )


def table_header():
    return (
        "| phase | subagents | wall | tok in | tok out | reasoning | cache read |\n"
        "|---|---|---|---|---|---|---|"
    )


def optional(label, func):
    """Run one best-effort section; report its failure without aborting."""
    try:
        func()
    except Exception as exc:  # noqa: BLE001 - every optional section is isolated
        print(f"\n{label}: unavailable ({exc})")


def main():
    if len(sys.argv) < 2 or not sys.argv[1].strip():
        print("usage: stats.py <session-id> [default-branch] [progress-file]", file=sys.stderr)
        return 1

    session_id = sys.argv[1].strip()
    default_branch = sys.argv[2].strip() if len(sys.argv) > 2 and sys.argv[2].strip() else "main"
    progress_file = sys.argv[3] if len(sys.argv) > 3 and sys.argv[3].strip() else None

    try:
        subagents = fetch_subagents(session_id)
    except Exception as exc:  # noqa: BLE001 - report, then still try the extras
        print(f"# exec run stats\n\ncould not list subagents for {session_id}: {exc}")
        subagents = []

    phases = {}
    for session in subagents:
        add(phases.setdefault(classify(session.get("title")), empty_bucket()), session)

    print(f"# exec run stats — {len(subagents)} subagents")
    print()
    print(table_header())
    total = empty_bucket()
    ordered = [name for name, _ in PHASES if name in phases]
    if OTHER in phases:
        ordered.append(OTHER)
    for name in ordered:
        bucket = phases[name]
        print(bucket_row(name, bucket))
        for key in total:
            total[key] += bucket[key]
    print(bucket_row("total", total, bold=True))

    print()
    print(
        f"Summed wall time is {fmt_wall(total['wall'])} across {total['n']} subagents; "
        "review phases run in parallel, so the run's wall-clock span is shorter."
    )

    try:
        parent = (api(f"/api/session/{session_id}") or {}).get("data") or {}
        timing = parent.get("time") or {}
        created, updated = timing.get("created"), timing.get("updated")
        if created and updated:
            print(
                f"Run wall-clock span: {fmt_wall(int(updated) - int(created))} "
                f"(orchestrator session {session_id})"
            )
    except Exception as exc:  # noqa: BLE001
        print(f"Run wall-clock span: unavailable ({exc})")

    if subagents:
        print()
        print("## by model")
        print()
        print(
            "| model | subagents | wall | tok in | tok out | reasoning | cache read |\n"
            "|---|---|---|---|---|---|---|"
        )
        models = {}
        for session in subagents:
            add(models.setdefault(model_label(session), empty_bucket()), session)
        for label, bucket in sorted(models.items(), key=lambda item: -item[1]["n"]):
            print(bucket_row(label, bucket))

    project_id = None
    if subagents:
        project_id = subagents[0].get("projectID")

    def project_stats():
        if not project_id:
            raise RuntimeError("no project id on the run's subagents")
        data = (api(f"/api/experimental/session/stats?project={project_id}&tools=summary") or {}).get("data") or {}
        tools = (data.get("tools") or {}).get("totals") or {}
        calls = tools.get("calls") or 0
        failed = tools.get("failed") or 0
        succeeded = tools.get("succeeded") or 0
        reliability = f"{succeeded / calls * 100:.1f}% success" if calls else "no tool calls"
        sessions = data.get("sessions")
        subagent_count = data.get("subagents")
        print()
        print("## project totals (all sessions in this project, not just this run)")
        print()
        print(f"- sessions: {sessions}, subagents: {subagent_count}")
        print(
            f"- tokens in/out/reasoning/cache-read: {fmt_tokens(data.get('tokens', {}).get('input') or 0)} / "
            f"{fmt_tokens(data.get('tokens', {}).get('output') or 0)} / "
            f"{fmt_tokens(data.get('tokens', {}).get('reasoning') or 0)} / "
            f"{fmt_tokens((data.get('tokens', {}).get('cache') or {}).get('read') or 0)}"
        )
        print(f"- tool calls: {calls} ({reliability}, {failed} failed)")

    optional("project totals", project_stats)

    def git_summary():
        proc = subprocess.run(
            ["git", "diff", "--shortstat", f"{default_branch}...HEAD"],
            capture_output=True,
            text=True,
            timeout=60,
        )
        summary = proc.stdout.strip()
        if proc.returncode != 0:
            raise RuntimeError((proc.stderr or "git diff failed").strip())
        print(f"- git diff --shortstat {default_branch}...HEAD: {summary or 'no changes'}")

    if progress_file:
        def progress_summary():
            with open(progress_file, encoding="utf-8", errors="replace") as handle:
                lines = handle.read().splitlines()
            logged = [line for line in lines if re.search(r"\[(?:decision|deviation|finding)\]", line)]
            tasks = [
                line
                for line in lines
                if line not in logged and re.match(r"^(?:\[[^\]]*\]\s*)?task\s+\d+", line, re.IGNORECASE)
            ]
            decisions = [line for line in lines if "[decision]" in line]
            deviations = [line for line in lines if "[deviation]" in line]
            print()
            print("## progress log")
            print()
            print(f"- task entries: {len(tasks)}")
            print(f"- decisions: {len(decisions)}")
            print(f"- deviations: {len(deviations)}")
            if decisions or deviations:
                print()
                print("Decisions and deviations logged:")
                for line in decisions + deviations:
                    print(f"- {line}")

        optional("progress log", progress_summary)

    try:
        print()
        print("## git")
        git_summary()
    except Exception as exc:  # noqa: BLE001
        print(f"\n## git\ngit summary: unavailable ({exc})")

    return 0


if __name__ == "__main__":
    sys.exit(main())
