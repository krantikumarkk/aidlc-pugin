# AIDLC — Claude Code plugin

AIDLC plugin serves your team's **certified engineering constitution** and **domain knowledge** to
Claude Code, and gates risky actions to the named human owners. Guidance is **live** from the
Levelupp server — there are no methodology files to hand-edit or keep in sync.

Install it once and it works in every repo you open.

## Requirements

- [Claude Code](https://claude.com/claude-code)
- A Levelupp **builder API key** (`lup_…`) for your workspace. Ask your Levelupp workspace admin.

## Install (user scope)

```bash
/plugin marketplace add krantikumarkk/levelupp-aidlc
/plugin install levelupp-aidlc@levelupp
```

Then set your key in the environment (e.g. in your shell profile):

```bash
export LEVELUPP_API_KEY=lup_<workspace>_<builder>_<secret>   # your builder key
# Optional — point at staging instead of prod:
# export LEVELUPP_BASE_URL=https://levelupp-staging.up.railway.app
```

That's it. Open any repo and start working — the plugin resolves your workspace from the key.
The first time you work in a new repo, run `aidlc_status` (or just ask Claude to "start AIDLC")
to register the repo to your workspace.

## What you get

- **Live constitution.** At the start of each session the plugin fetches your workspace's current
  constitution (project facts, allowed actions, gate owners, risk tiers) and gives it to Claude as
  context. It is always current — nothing is written into your repo.
- **Runtime gate.** Before risky shell actions (pushing to a protected branch, deploying, touching
  secrets/infra), the plugin checks the action against your constitution and names the human owner
  who must sign off. The dangerous "MUST-NEVER" classes (protected-branch push, committing secrets,
  hard data-deletes) are blocked **locally and offline**, with no dependence on the network.
- **Commands** — `/assess` (maturity assessment + repo bootstrap), `/spec-review`, `/deploy-check`,
  and `/graduate <workflow>` (lower a workflow's oversight on a passing eval). Each runs the live
  procedure from the server.
- **Sub-agents** for spec-driven development (spec-author, spec-reviewer, implementer, qa, security,
  deploy), each following the live method.
- **In-repo enforcement.** When instructed, the plugin writes only what GitHub itself must read:
  `.github/CODEOWNERS` (compiled from your certified handoff map) and a CI eval-gate (with a starter
  eval set so a required check works on day one). Levelupp's servers never write into your repo —
  the connected agent does, and you review the PR.

## Enforcement honesty

At **user scope** the gate is **soft** — you installed the plugin, so you can remove it. The
MUST-NEVER floor still denies offline; softer classes **fail open with a visible warning** if the
Levelupp server is unreachable (so a transient outage never wedges you). The plugin never silently
pretends to gate when it can't.

For **non-bypassable** enforcement, your org deploys the plugin via Claude Code **managed settings**
(`enabledPlugins` + `allowManagedHooksOnly`) with `LEVELUPP_FAIL_CLOSED=1`. Ask Levelupp about the
scale tier.

## Privacy

Your API key is read from the environment — never written into your repo or committed. The plugin
caches only non-secret session context under `$XDG_CACHE_HOME/levelupp` (or `~/.cache/levelupp`).

## Updating

`/plugin update levelupp-aidlc`. `aidlc_status` nudges you when a newer bundle is available.

---

Questions or a key request → your Levelupp workspace admin, or https://github.com/krantikumarkk/levelupp-aidlc.
