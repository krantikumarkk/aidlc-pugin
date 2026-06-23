---
name: track-b-product
description: Make the company's product agent-accessible (MCP), agent-safe (auth + AX), and agent-embedded (in-app copilot). Use when the goal is "make our product agent-ready", expose our API to agents, add an in-app assistant, or build an MCP server. Track B only.
---

# Track B — Product Agentification

The method is server-served. Call `consult` with `aidlc_stage: "track_b_product"` and follow the
returned sequence (foundations → expose → secure → embed → retrofit AX). Auth is table stakes — ship
the MCP server and the auth layer together, and enforce tenant isolation server-side.
