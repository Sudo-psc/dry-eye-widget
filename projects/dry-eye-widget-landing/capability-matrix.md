# Runtime Capability Matrix

| Capability | Status | Notes |
|---|---:|---|
| Repo read access | yes | Current repo is readable. |
| Repo write access | yes | Files can be added and edited. |
| Shell access | yes | Local commands available. |
| Filesystem search | yes | `rg` available. |
| File editing | yes | Use patch-based edits. |
| Git access | yes | Remote is `https://github.com/Sudo-psc/dry-eye-widget.git`. |
| Network access | yes | Package install and public fetches are available. |
| Package install ability | yes | Node `v25.9.0`, npm `11.12.1`. |
| Local database availability | partial | SQLite likely available, not needed for static site V1. |
| Browser control | partial | Local browser/testing can be used after dev server starts. |
| Screenshot or vision support | partial | Local image inspection available. Browser screenshot support to be verified. |
| Desktop input control | partial | Available through desktop context, not needed for V1. |
| Tool-calling support | yes | Codex tools available. |
| Sub-agent support | partial | Not required for single-agent baseline. |
| Long-running background execution | partial | Dev server can run in session. |
| Cron or scheduled execution | partial | Automation tooling exists, not needed for V1. |
| Webhook or event trigger support | no | Deferred. |
| Persistent storage | yes | Project files and git. |
| UI or dashboard rendering | partial | Static landing and file dashboards. |
| Secret management | no | Do not store deployment secrets. |
| Approval and interruption controls | yes | User can interrupt through Codex. |
| Multi-machine support | no | Deferred until hub/worker work. |

## Missing Capability Decisions

- VPS deploy: defer until server credentials and deploy target are provided.
- DNS: defer until registrar/DNS access is available.
- GitHub repo creation: defer or use existing repo unless user confirms a separate landing repo.
- Production PageSpeed: local Lighthouse/smoke checks first; production PageSpeed after deployment.

