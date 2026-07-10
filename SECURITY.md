# Security Policy

## Supported versions

Security fixes target the **latest release** on [`main`](https://github.com/Sudo-psc/dry-eye-widget) and the current GitHub Release tag.

| Component | Support |
|-----------|---------|
| Desktop app (macOS / Windows) | Latest release |
| Landing (`site/`) | `main` branch / Pages deploy |

## Reporting a vulnerability

Please **do not** open a public issue for security problems.

1. Email **philipe.saraiva.cruz@gmail.com** with subject `[security] dry-eye-widget`, or  
2. Use [GitHub Security Advisories](https://github.com/Sudo-psc/dry-eye-widget/security/advisories/new) (private report) if available.

Include:

- Affected version / commit  
- Platform (macOS, Windows, landing)  
- Steps to reproduce  
- Impact (data exposure, RCE, XSS, etc.)  
- Optional: suggested fix  

We aim to acknowledge within **7 days** and ship a fix or mitigation for confirmed issues as soon as practical.

## Scope notes

- The app is **local-first**: no account system, no server-side user data store.  
- Optional network use: GitHub Releases API (HTTPS only) for update checks.  
- Landing is static HTML; CSP and referrer-policy are declared in page meta.  
- Unsigned binaries may trigger Gatekeeper / SmartScreen — see [`docs/CODE_SIGNING.md`](docs/CODE_SIGNING.md).

## Out of scope (examples)

- Social engineering of end users to run unsigned installers  
- Issues only present in unmaintained forks  
- Purely cosmetic UI bugs without security impact  
