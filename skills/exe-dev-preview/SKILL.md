---
name: exe-dev-preview
description: Get a private browser URL for a running app on exe.dev.
disable-model-invocation: true
---

# exe.dev preview

Expose the requested app on demand. Discover the VM and current app port each time; worktree ports can change.

1. Identify the target VM and checkout from the request and environment. If ambiguous, ask which app to preview.
2. Inspect the running stack. For Lightdash, run `scripts/dev-ports.sh list` from the checkout and select its exact worktree entry. Confirm the frontend and `/api/v1/health` through the frontend port with `curl`. Report a stopped stack rather than starting unrelated services.
3. For ports 3000–9999, return `https://<vm>.exe.xyz:<port>/`. exe.dev proxies these ports privately; each worktree can have its own URL without changing the VM's primary route.
4. If the user requests the bare hostname, use an authenticated exe.dev control session:
   ```sh
   ssh exe.dev share show <vm>
   ssh exe.dev share port <vm> <frontend-port>
   ssh exe.dev share show <vm>
   ```
   This replaces the primary route. Preserve its visibility and existing shares. If it is public, ask before routing this app there. If control auth is unavailable, return the private port URL when supported; otherwise name the auth blocker.
5. Verify the app accepts its exe.dev hostname using a local request with that `Host` header. Check the HTTPS URL without printing page contents or credentials. An exe.dev login redirect confirms the private access gate, not the app itself. Report local health and external reachability separately.

Keep access private. Public sharing requires an explicit request. Browser verification needs the user's authorization; shell checks are sufficient to provide the URL.

Completion: give the URL, target worktree and port, verification result, and any remaining blocker. Tell the user to sign in to exe.dev if prompted.

If browser access fails, check Vite's `allowedHosts`, frontend API proxying, and browser-facing URLs such as `SITE_URL` and `S3_PUBLIC_ENDPOINT`. Change only settings needed for the reported failure; preserve backend-internal addresses. Follow the repo's restart procedure for affected processes.

Current proxy behavior: [exe.dev HTTP proxies](https://exe.dev/docs/proxy.md). Read it when port routing or authentication behaves differently.
