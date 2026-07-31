---
name: lightdash-setup-worktree
description: Set up or tear down an isolated Lightdash Git worktree with Herdr, dedicated ports and PostgreSQL, copied local credentials, scoped cookies, and verified pnpm dev.
disable-model-invocation: true
---

# Lightdash worktree

Use a **sealed delegation**: the primary agent carries only the delegation contract and result; one sub-agent owns the full worktree operation and its proof.

## Primary agent

Spawn exactly one sub-agent with no inherited conversation context (`fork_turns: "none"`). Give it a self-contained prompt:

```text
Use $lightdash-setup-worktree from <absolute-checkout-path>. You are the delegated worktree agent.
Operation: <setup|teardown>.
Task: <task-code> — <short-description>.
Read the delegated procedure, complete the operation, and return its proof.
```

Include the checkout path and operation. Include the task code, such as a Linear ID, and short description when available so the sub-agent can choose a friendly Herdr label; omit the `Task` line when unavailable. For teardown, state explicitly whether the user requested deletion of the instance's PostgreSQL volume.

Keep live-machine inspection, linked-reference reads, commands, and troubleshooting inside the sub-agent. Wait for its final result, relay the proof, then resume the user's main task when setup was a prerequisite.

Completion: one sub-agent completed the requested operation, and the primary agent's setup activity was limited to spawning, waiting, and relaying the result.

## Delegated agent

Read [procedure.md](references/procedure.md) and execute the requested setup or teardown branch completely. Return the proof required by that branch.

Completion: every completion criterion in the requested branch is satisfied, or the result names the exact blocker and preserves all existing environments.
