---
description: Run the AIDLC maturity assessment and reverse-engineer this repo to seed the workspace constitution (M_AIDLC v2 §9.3).
---

# /assess

The maturity-assessment + constitution-bootstrap entry point. The method is server-served; this
command only points the agent at the live procedure.

Call `consult` with `aidlc_stage: "aidlc_assess"` and follow the returned procedure: assess this
repo + organisation, present the overall level, per-dimension levels, blockers, and the top
roadmap actions, and capture the result as the `maturity-roadmap` constitution object.

For a fresh workspace, also run the `workspace-detection` skill to reverse-engineer the repo into
an `ObservedFacts` payload and POST it via `submit_bootstrap_facts` — that lets the constitution be
generate-then-ratified rather than authored from blank sessions. Then proceed per `aidlc_status`.
