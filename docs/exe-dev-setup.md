# exe.dev agent environment

Use this runbook to set up a headless VM for T3 Code, Claude, Codex, and Executor. Resume at the relevant section when extending an existing VM.

Examples use `VM_NAME`, `TEMPLATE_NAME`, and repository placeholders. Resolve them from the user's account; keep credentials and account-specific configuration outside this public repo.

## VM and T3 Connect

1. Read [exe.dev's agent docs](https://exe.dev/llms.txt) and inspect the team's available templates. A development template can provide Docker and language runtimes, but inspect its running services and occupied ports before reusing it.
2. Create a separate VM, preserving the shared template. For example:
   ```sh
   ssh exe.dev cp TEMPLATE_NAME VM_NAME --copy-tags=false --disk=100GB
   ssh -T vm+VM_NAME@vm.exe.xyz
   ```
   Choose disk and compute from the intended workload. Multiple Lightdash worktrees share the VM's resources.
3. Install the current T3 CLI from its official distribution. Run `t3 connect --headless`, complete its browser authentication, then run `t3 service install`.
4. Verify the service is enabled and running, and that the environment appears connected in the user's T3 client. A running process alone does not prove the tunnel connected.

For Linux user services over SSH, the session may need:

```sh
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
```

Check `loginctl show-user "$USER" -p Linger`; enable lingering when the user service must run after logout and at boot. Use the installed CLI's help and generated service definition for current commands and paths.

## Repositories and providers

- Authenticate GitHub CLI on the VM with `gh auth login --web`, complete its device flow in the user's browser, then run `gh auth setup-git`.
- Clone repositories fresh into one parent directory, for example `~/develop/{lightdash,lightdash-desktop,lightdash-cloud,analytics}`. This preserves sibling paths such as `../lightdash-cloud`. A template's existing checkout is separate from these clones.
- Verify each clone's remote, branch, and clean status. Discover each project's runtime and infrastructure requirements from that checkout.
- Install current Claude and Codex releases through their official installers. Complete Claude's login and `codex login --device-auth`; verify with `claude auth status` and `codex login status`.
- Check `claude --version` and `codex --version` using the PATH of the running T3 service. Installing into `~/.local/bin` can leave older `/usr/local/bin` binaries selected by T3. Adjust the service PATH or managed symlinks, retaining a rollback path.

Provider credentials stay on the VM. Browser authentication must finish before reporting the provider ready.

For browser automation on the VM, install `agent-browser` and its browser dependencies:

```sh
npm install --global --prefix "$HOME/.local" agent-browser@latest
export PATH="$HOME/.local/bin:$PATH"
agent-browser install --with-deps
agent-browser --version
```

Check the package's current Node requirement and verify the binary resolves in T3's service PATH. Installing the npm package alone does not install the browser. Linux dependency installation may need sudo.

## Commit signing

Configure the user's Git name and email from their supplied identity. Generate a dedicated Ed25519 signing key on the VM; register only its public key in GitHub as a **Signing Key**. Keep the private key on the VM with mode `0600`.

```sh
git config --global gpg.format ssh
git config --global user.signingkey "$HOME/.ssh/commit-signing"
git config --global commit.gpgsign true
git config --global gpg.ssh.allowedSignersFile "$HOME/.ssh/allowed_signers"
```

Use an agent or a passphrase-free dedicated key according to the user's unattended signing needs. Populate `allowed_signers` with the Git email and public key. Verify an empty signed commit in a temporary repository with `git verify-commit HEAD`; registration on GitHub and local signature verification are separate checks. A pushed commit's GitHub verification is a further check, requiring an authorized push.

## Skills

Clone this repo fresh beside the projects. `install.sh` owns the external skill list and global instruction links; inspect it before replaying it on a new machine. Upstream skill names can disappear, so check installation output and resolve missing skills from their upstream history rather than reporting partial installation as complete.

For selected skills or local changes, install from the checkout:

```sh
npx skills add . -g --agent claude-code --agent codex --skill SKILL_NAME -y
```

Canonical skills live in `~/.agents/skills`; preserve the default agent links. Codex can discover this universal directory without a second copy in `~/.codex/skills`. Preserve provider system skills and existing configuration.

Install only the requested skills. Lightdash's existing `/docker-dev` workflow may be sufficient; `lightdash-setup-worktree` is optional. Verify the installed files and global instruction links, then use a new provider session for discovery.

## Executor

Read [Executor's CLI docs](https://executor.sh/docs/local/cli.md) for the current release. The CLI suits a single-user headless VM; the [self-hosted Docker form](https://executor.sh/docs/hosted/docker.md) has a separate account and hosted-auth model.

On the VM:

```sh
npm install --global --prefix "$HOME/.local" executor@latest
export PATH="$HOME/.local/bin:$PATH"
executor install
executor service status
claude mcp add -s user executor -- "$HOME/.local/bin/executor" mcp
codex mcp add executor -- "$HOME/.local/bin/executor" mcp
```

Read the actual service port from `executor service status`. The supervised service used 4789 during this setup; the standalone daemon defaults to 4788. `executor daemon status` can therefore report nothing while the supervised service is healthy.

Verify service persistence, Claude's MCP connection, and the stdio MCP tool list. New T3 threads/provider sessions load the updated MCP config. Connections configured in this VM's Executor are separate from those in a developer's local Executor.

### UI and OAuth

The CLI gates its API and MCP endpoint with a stable bearer token stored in `~/.executor/server-control/auth.json`. `executor open` creates a browser sign-in URL. Transfer the token privately to the intended browser; keep it out of logs, committed files, screenshots, and shared URLs.

For ports supported by exe.dev's private proxy, `https://VM_NAME.exe.xyz:PORT/` can serve the configuration UI behind exe.dev login. Verify the UI locally and unauthenticated MCP rejection separately. Public sharing is unnecessary for ordinary configuration.

**Local OAuth can require a localhost browser origin.** Executor's [Local client metadata](https://executor.sh/api/oauth/client-id-metadata/local.json) lists loopback callbacks. A Linear authorization URL using that client ID and an `https://VM_NAME.exe.xyz:PORT/api/oauth/callback` redirect is incompatible with that metadata. Removing the port or making the route public does not correct the mismatch. Recheck the metadata if behavior changes.

For this flow, forward an unused loopback port on the browser's machine to the VM's actual Executor port:

```sh
ssh -NT -o ExitOnForwardFailure=yes \
  -o ServerAliveInterval=30 -o ServerAliveCountMax=3 \
  -L 127.0.0.1:4790:127.0.0.1:4789 vm+VM_NAME@vm.exe.xyz
```

Open `http://localhost:4790/`, sign in with the **VM's** Executor token, and initiate a fresh OAuth flow there. Use the forwarded origin throughout the flow. The example assumes the VM service is on 4789; substitute its discovered port.

Keep the tunnel alive until OAuth completes and an authenticated read tool succeeds. A one-shot tool invocation can clean up a background SSH child, so verify the listener and HTTP response before handing over the URL. For a persistent tunnel, use the browser machine's service manager and verify SSH authentication in that service's context.

After authorization, stop the tracked tunnel process or its service; remove any temporary auto-start configuration. Saved connection credentials remain on the VM. Future interactive authorization needs the tunnel again. Do not claim OAuth completion from a reachable UI alone.

## Lightdash previews

Use `$exe-dev-preview` from [its skill](../skills/exe-dev-preview/SKILL.md) when explicitly requested. It discovers the active worktree's ports and returns a private app URL. Preserve existing template services and the VM's primary route when adding another worktree.

Setup is complete when T3 is connected, requested providers are authenticated, fresh clones and requested skills are present, signing checks pass if requested, and Executor's MCP connection works. Report any integration still awaiting OAuth separately.
