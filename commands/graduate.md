---
description: Run a workflow's eval and, on green, record its graduation toward the next autonomy rung (M_AIDLC v2 §13).
argument-hint: <workflow>
---

# /graduate <workflow>

The maturity on-ramp flow (M_AIDLC v2 §13): a workflow's required human oversight is lowered by one
rung — but **only on eval evidence** (`aidlc_rule_003`: maturity = min(capability, governance)).
The method is server-served; this command only runs the eval and records the result.

Workflow to graduate: **$ARGUMENTS**

## Steps

1. **Run the workflow's eval set** repo-side using the project's own eval/test command. For the
   verify/eval procedure, call `consult` with `aidlc_stage: "sdd_qa"`. If the eval is red, **stop** —
   report the failures and the gap to close before graduating.

2. **Record the result.** Call the **`aidlc_graduate`** MCP tool with
   `{ workflow: "$ARGUMENTS", eval_passed, eval_ref }` (`eval_ref` = the eval-run PR / issue /
   result URL). The server records the graduation evidence and surfaces the next rung in
   `aidlc_status`.

3. **Surface the returned `next_action`.** Lowering a workflow's oversight is a constitution
   re-certification a human ratifies through internal review — `aidlc_graduate` records the
   evidence, it does **not** flip the autonomy register itself. Report the eval status and the next
   maturity step.

Do not lower oversight without a green eval. At user scope the gate is soft (user-removable);
non-bypassable enforcement requires managed settings.
