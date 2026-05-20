#!/usr/bin/env python3
"""Render a meta-project brief as a polished single-file HTML plan.

Usage:
  python3 render_html.py <brief.md path>           # prints HTML to stdout
  python3 render_html.py <brief.md path> -o <out>  # writes to out
"""

import argparse
import datetime
import html
import json
import re
import sys
from pathlib import Path
from string import Template

STATUS_LABELS = {
    "todo": "Todo",
    "doing": "In Progress",
    "blocked": "Blocked",
    "needs-decision": "Needs Decision",
    "done": "Done",
    "cancelled": "Cancelled",
}


def esc(s):
    return html.escape("" if s is None else str(s))


def read_brief(path):
    """Extract machine state JSON and ## Notes section from a brief.md file."""
    text = Path(path).read_text()
    lines = text.splitlines()

    state_lines = []
    in_state = False
    for line in lines:
        if line.strip() == "```project-state":
            in_state = True
            continue
        if in_state and line.strip() == "```":
            break
        if in_state:
            state_lines.append(line)
    state = json.loads("\n".join(state_lines)) if state_lines else {}

    notes_lines = []
    in_notes = False
    for line in lines:
        if line.strip() == "## Notes":
            in_notes = True
            continue
        if line.strip() == "```project-state":
            break
        if in_notes:
            notes_lines.append(line)
    notes = "\n".join(notes_lines).strip()

    return state, notes


def render_lede(goal):
    if not goal:
        return ""
    text = goal.strip()
    first = text.split(". ", 1)[0]
    if not first.endswith("."):
        first += "."
    return esc(first)


def render_meta(state):
    meta = state.get("metadata") or {}
    if not meta:
        created = (state.get("created") or "")[:10] or "—"
        meta = {
            "Tier": state.get("tier", "standard").title(),
            "Status": state.get("project_status", "active").title(),
            "Phases": str(len(state.get("phases", []))),
            "Created": created,
        }
    if not meta:
        return ""
    cells = "\n    ".join(
        f'<div class="meta-cell"><p class="meta-label">{esc(k)}</p>'
        f'<p class="meta-value">{esc(v)}</p></div>'
        for k, v in meta.items()
    )
    return f'<div class="meta">\n    {cells}\n  </div>'


def render_progress(phases):
    total = len(phases)
    done = sum(1 for p in phases if p.get("status") == "done")
    pct = (done / total * 100) if total else 0
    return (
        '<h2 class="section">Progress</h2>\n'
        '  <div class="progress-row">\n'
        f'    <div class="progress-bar"><div class="progress-fill" style="width:{pct:.0f}%"></div></div>\n'
        f'    <div class="progress-count"><strong>{done}</strong> of <strong>{total}</strong> phases complete</div>\n'
        '  </div>'
    )


def render_dod(dod):
    if not dod:
        return ""
    items = "\n    ".join(f"<li>{esc(d)}</li>" for d in dod)
    return (
        '<h2 class="section">Definition of done</h2>\n'
        '  <ul class="dod-list">\n'
        f'    {items}\n'
        '  </ul>'
    )


def render_phase(idx, phase):
    status = phase.get("status", "todo")
    if status not in STATUS_LABELS:
        status = "todo"
    pill_label = STATUS_LABELS[status]
    num = f"{idx + 1:02d}"
    title = esc(phase.get("title", phase.get("id", "")))
    deps = phase.get("depends_on") or []
    deps_str = ", ".join(deps) if deps else "—"
    executor = phase.get("executor", "me")
    owner = phase.get("owner", "Max")
    executor_label = owner if executor == "me" else executor
    outcome = esc(phase.get("outcome", ""))
    accept = phase.get("acceptance_criteria") or []
    accept_html = ""
    if accept:
        items = "\n        ".join(f"<li>{esc(a)}</li>" for a in accept)
        accept_html = (
            '\n      <p class="field-label">Acceptance</p>\n'
            '      <ul class="accept">\n'
            f'        {items}\n'
            '      </ul>'
        )

    return (
        f'  <article class="phase {status}">\n'
        '    <div class="phase-head">\n'
        '      <div style="display:flex;align-items:flex-start;flex:1;">\n'
        '        <div class="phase-num-wrap">\n'
        '          <span class="phase-num-label">Phase</span>\n'
        f'          <span class="phase-num">{num}</span>\n'
        '        </div>\n'
        '        <div class="phase-title-wrap">\n'
        f'          <h3 class="phase-title">{title}</h3>\n'
        '        </div>\n'
        '      </div>\n'
        f'      <span class="pill {status}">{pill_label}</span>\n'
        '    </div>\n'
        '    <div class="phase-chips">\n'
        f'      <span class="chip"><strong>Executor</strong>{esc(executor_label)}</span>\n'
        f'      <span class="chip"><strong>Depends on</strong>{esc(deps_str)}</span>\n'
        '    </div>\n'
        '    <div class="phase-body">\n'
        '      <p class="field-label">Outcome</p>\n'
        f'      <p class="outcome">{outcome}</p>'
        f'{accept_html}\n'
        '    </div>\n'
        '  </article>'
    )


def render_notes(notes_md):
    """Convert simple markdown notes to HTML. Supports paragraphs, **bold**, *em*,
    _italic_, `code`, and leading-italic emphasis (lines starting with '*Stress…:*')."""
    if not notes_md or not notes_md.strip():
        return ""

    paragraphs = [p.strip() for p in re.split(r"\n\s*\n", notes_md) if p.strip()]
    rendered = []
    for p in paragraphs:
        p_html = esc(p)
        p_html = re.sub(r"`([^`]+)`", r'<code class="inline">\1</code>', p_html)
        p_html = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", p_html)
        p_html = re.sub(r"(?<!\w)\*([^*\n]+)\*(?!\w)", r"<em>\1</em>", p_html)
        p_html = re.sub(r"(?<!\w)_([^_\n]+)_(?!\w)", r"<em>\1</em>", p_html)
        p_html = p_html.replace("\n", "<br>")
        rendered.append(f"<p>{p_html}</p>")

    body = "\n    ".join(rendered)
    return (
        '<h2 class="section">Notes</h2>\n'
        f'  <div class="notes">\n    {body}\n  </div>'
    )


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("brief", help="Path to brief.md")
    ap.add_argument("-o", "--output", help="Output HTML path (default: stdout)")
    args = ap.parse_args()

    brief_path = Path(args.brief).resolve()
    if not brief_path.exists():
        sys.stderr.write(f"render_html: not found: {brief_path}\n")
        sys.exit(2)

    state, notes_md = read_brief(brief_path)

    tmpl_path = Path(__file__).parent.parent / "templates" / "plan.html.tmpl"
    tmpl = Template(tmpl_path.read_text())

    tier = state.get("tier", "standard").title()
    slug = state.get("slug", brief_path.parent.name)
    source_rel = f"briefs/{slug}/brief.md"

    phases = state.get("phases", [])
    phases_html = "\n\n".join(render_phase(i, p) for i, p in enumerate(phases))

    html_out = tmpl.substitute(
        title=esc(state.get("title", slug)),
        eyebrow=f"Project Plan · {esc(tier)} tier",
        lede=render_lede(state.get("goal", "")),
        meta_html=render_meta(state),
        progress_html=render_progress(phases),
        dod_html=render_dod(state.get("definition_of_done", [])),
        phases_html=phases_html,
        notes_html=render_notes(notes_md),
        source_path=esc(source_rel),
        rendered_date=datetime.date.today().isoformat(),
    )

    if args.output:
        Path(args.output).write_text(html_out)
    else:
        sys.stdout.write(html_out)


if __name__ == "__main__":
    main()
