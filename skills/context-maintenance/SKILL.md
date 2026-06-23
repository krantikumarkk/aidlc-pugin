---
name: context-maintenance
description: Keep standing context true and capture human corrections as reusable rules. Use after merging a non-trivial change, whenever a human corrects your output in review, after an incident or revert, or when asked to update docs/context.
---

# Context Maintenance

The method is server-served. Call `consult` with `aidlc_stage: "context_maintenance"` and follow the
returned procedure: update any constitution fact the change invalidated **in the same PR**, append
each human correction or incident to the failure log, and graduate a rule once the same failure
recurs. Never silently absorb a correction — that is how the same mistake ships twice.
