---
name: workspace-detection
description: >
  Reverse-engineer the current repository into an ObservedFacts payload for AIDLC bootstrap
  (M_AIDLC v2 §9.3). Use when aidlc_status reports the workspace is not bootstrapped
  (stage: aidlc_bootstrap). Detects languages, frameworks, CI, protected branches, test layout,
  deploy config, and package managers, then POSTs the facts to the submit_bootstrap_facts MCP
  tool so the server can pre-fill draft constitution objects for the engineering lead to ratify.
  Read-only on the repo — writes nothing.
---

# Workspace detection (AIDLC bootstrap)

The bootstrap method is served live — call `consult` with `aidlc_stage: "aidlc_bootstrap"` for the
full generate-then-ratify procedure. This skill only does the read-only fact-gathering the server
cannot (the server has no access to your local repo):

1. Run the detector (read-only — writes nothing):
   ```bash
   python3 "${CLAUDE_PLUGIN_ROOT}/skills/workspace-detection/scripts/detect.py"
   ```
   It emits an `ObservedFacts` JSON object (v2 §9.3 schema): `git_remote`, `languages`,
   `frameworks`, `repo_host`, `ci`, `protected_branches`, `test`, `deploy`, `package_managers`,
   `monorepo`.
2. Review the detected facts with the user; correct anything wrong (the detector is heuristic).
3. Call the **`submit_bootstrap_facts`** MCP tool with the (corrected) `ObservedFacts`, then follow
   the `consult aidlc_stage=aidlc_bootstrap` procedure (the server pre-fills draft objects; the
   engineering lead ratifies them in the Builder UI; implementation proceeds in parallel).

**This skill never writes into the repo.** It only reads to produce the facts payload.
