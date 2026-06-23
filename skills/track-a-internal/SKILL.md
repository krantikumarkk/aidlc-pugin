---
name: track-a-internal
description: Orchestrate the internal agentic SDLC — plan, implement, test, review, eval gate, deploy gate — sized to the change. Use when building features with agents, moving agents into the PR/CI flow, or deciding how much process a change needs.
---

# Track A — Internal Agentic SDLC

The method is server-served. Call `consult` with `aidlc_stage: "track_a_internal"` and follow the
returned procedure — including the adaptive depth selection (Quick / Standard / Comprehensive) so a
small change isn't over-processed and a risky one isn't under-gated. Hand off to the SDD sub-agents
(`spec-author` → `spec-reviewer` → `implementer` → `qa` → `security` → `deploy`) for each phase.
