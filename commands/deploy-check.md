---
description: Run the pre-deploy gate — eval, checklist, canary plan, rollback — before any production deploy (Tier-2).
---

# /deploy-check

The pre-deploy gate. **Tier-2: require explicit human approval before executing the deploy itself.**
Deploy/release commands must NOT be auto-allowed — the PreToolUse hook gates them via
`authorize_action`. The method is server-served.

Call `consult` with `aidlc_stage: "sdd_deploy"` and follow the returned deploy-pack procedure (green
eval for the affected workflow, pre-flight checklist, canary + explicit rollback plan, drift+cost
monitoring). At the release step, call `authorize_action` for the production deploy — it is denied
while any `blocks:'release'` rider is open, and names the gate owner. On approval, hand off to the
`deploy` sub-agent and run the post-deploy verification runbook.
