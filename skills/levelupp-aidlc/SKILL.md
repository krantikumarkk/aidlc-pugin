---
name: levelupp-aidlc
description: >
  Levelupp AIDLC entry point. ALWAYS use this on any request to start, resume, implement,
  enhance, or fix a Business Objective, or to set up / update the workspace constitution. On
  such a request, call the aidlc_status MCP tool FIRST (pass the repo's git remote). Treat the
  workspace constitution injected at session start as the always-on rules in place of any
  installed AGENTS.md. Never begin Business Objective implementation while bo_readiness.can_start
  is false.
---

# Levelupp AIDLC — start here

The method is served live by the Levelupp MCP server, not stored in this file. On any
"start/resume/implement/enhance/fix a BO" or "set up/update the constitution" request:

1. **Call `aidlc_status` first** with the repository's git remote URL, then follow its
   `next_actions`. It reports the setup stage, the constitution manifest, any release riders on the
   named BO, and whether `bo_readiness.can_start` is true. (If `repo_registered` is false, call
   `register_repo` and re-run `aidlc_status`.)
2. **Treat the injected constitution as the rules.** There is no installed AGENTS.md — it arrives as
   session context (Plane 2) and is always current.
3. **For each phase, call `consult`** with the relevant `aidlc_stage` (e.g. `aidlc_bootstrap`,
   `aidlc_bo_implementation`, or an `sdd_*` agent phase) and follow the returned procedure.
   Implement against `get_bo_summary` (the contract).
4. **Never begin implementation while `bo_readiness.can_start` is false.** Address the listed
   blockers first; missing constitution items are riders (a production release is blocked until the
   release riders clear), not a blanket block.

If Levelupp is unreachable or the repo is unregistered, the session-start hook says so and the gate
is inactive — run `aidlc_status` to re-establish guidance.
