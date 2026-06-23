---
description: Audit a spec for completeness and ambiguity before implementation (M_AIDLC spec-driven development, phase 2).
argument-hint: [spec-path]
---

# /spec-review [spec-path]

Read-only spec audit. The method is server-served; this command points the agent at the same live
procedure the `spec-reviewer` sub-agent uses.

Spec to audit: **$ARGUMENTS** (or the most recently edited file under `specs/` if no path is given).

Call `consult` with `aidlc_stage: "sdd_spec_review"` and follow the returned audit checklist and the
READY / NOT READY verdict. Do not edit code or the spec — the human approves the spec before any
implementation begins.
