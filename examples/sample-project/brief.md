---
slug: sample-project
title: Sample project , ship a personal landing page
tier: standard
status: active
created: 2026-05-19
---
## Goal
<!-- auto-projected , illustrative only -->
Ship a personal landing page at yourname.com in 2 weeks. One page, no CMS.

## Definition of done
- Domain registered and pointed at hosting
- Page deployed and live
- Analytics installed
- One outbound link from social to verify traffic flows

## Phases
- p1 Domain + hosting [me] doing
- p2 Page build [me] todo
- p3 Analytics + verification [me] todo

## Notes
This is an illustrative brief. Run `pm open sample-project` (with
`PILOT_ROOT=examples` set, or by copying this folder under your own briefs
root) to see the rendered HTML view.

```project-state
{
  "schema_version": 1,
  "slug": "sample-project",
  "title": "Sample project , ship a personal landing page",
  "tier": "standard",
  "project_status": "active",
  "goal": "Ship a personal landing page at yourname.com in 2 weeks. One page, no CMS.",
  "definition_of_done": [
    "Domain registered and pointed at hosting",
    "Page deployed and live",
    "Analytics installed",
    "One outbound link from social to verify traffic flows"
  ],
  "metadata": {
    "Owner": "you",
    "Window": "2 weeks",
    "Stack": "Static HTML / Vercel"
  },
  "phases": [
    {
      "id": "p1",
      "title": "Domain + hosting",
      "outcome": "Domain registered, DNS configured, hosting account ready to deploy.",
      "acceptance_criteria": [
        "Domain purchased and locked",
        "Nameservers pointed at hosting provider",
        "Empty page deploys successfully"
      ],
      "owner": "me",
      "executor": "me",
      "status": "doing",
      "depends_on": [],
      "dates": {},
      "note": "registrar picked, choosing between vercel and netlify",
      "last_status_change": "2026-05-19T16:00:00Z",
      "completed_at": null
    },
    {
      "id": "p2",
      "title": "Page build",
      "outcome": "Single landing page built, copy reviewed, deployed to production.",
      "acceptance_criteria": [
        "Hero, about, links, footer sections written",
        "Mobile responsive at 375px / 768px / 1280px",
        "Lighthouse score 90+ across the board"
      ],
      "owner": "me",
      "executor": "me",
      "status": "todo",
      "depends_on": ["p1"],
      "dates": {},
      "note": null,
      "last_status_change": null,
      "completed_at": null
    },
    {
      "id": "p3",
      "title": "Analytics + verification",
      "outcome": "Page tracks visits, one referral source verified.",
      "acceptance_criteria": [
        "Plausible or Fathom installed",
        "One outbound link from LinkedIn/IG points at the page",
        "First visit recorded in analytics dashboard"
      ],
      "owner": "me",
      "executor": "me",
      "status": "todo",
      "depends_on": ["p2"],
      "dates": {},
      "note": null,
      "last_status_change": null,
      "completed_at": null
    }
  ],
  "created": "2026-05-19T15:00:00Z",
  "updated": "2026-05-19T16:00:00Z"
}
```
