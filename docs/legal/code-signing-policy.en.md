# Code Signing Policy

> Free code signing provided by [SignPath.io](https://about.signpath.io),
> certificate by [SignPath Foundation](https://signpath.org)

This document describes how **Dry Eye Widget** releases are built, reviewed,
approved and signed — in compliance with the
[SignPath Foundation terms](https://signpath.org/terms).

## Project

- **Name:** Dry Eye Widget
- **Repository:** <https://github.com/Sudo-psc/dry-eye-widget> (public)
- **License:** [MIT](../../LICENSE) — OSI-approved, **no** commercial
  dual-licensing.
- **Purpose:** a free eye-health tool (the 20-20-20 rule). It contains no
  malware, no potentially unwanted programs, and no vulnerability-exploitation
  tooling.

## Team roles

Maintained by a single owner, with assisted review and CI gates:

| Role | Person |
|---|---|
| **Author / Maintainer** | Dr. Philipe Saraiva Cruz — GitHub [@Sudo-psc](https://github.com/Sudo-psc) |
| **Reviewer** | [@Sudo-psc](https://github.com/Sudo-psc), with automated review (GitHub Copilot, Gemini Code Assist) and CI gates (`flutter analyze`, tests, macOS + Windows builds) |
| **Approver** | [@Sudo-psc](https://github.com/Sudo-psc) — the only person authorized to create release tags and approve signing |

## Release approval process

1. Every change lands via **Pull Request** and must pass CI
   (`flutter analyze`, `flutter test`, macOS and Windows builds).
2. A release is cut by creating the tag `vX.Y.Z` on the `main` branch.
3. GitHub Actions builds the artifacts and **submits the Windows installer to
   SignPath** for signing (trusted build, bound to this repository).
4. **Only** binaries built from **this public repository's source** are signed.
   We do not sign third-party or modified upstream software.

## Binary metadata

All published binaries carry mandatory **product name and version** metadata
(configured in Inno Setup and `windows/runner/Runner.rc`). Technical details in
[`win_version/CODE_SIGNING.md`](../../win_version/CODE_SIGNING.md).

## Privacy

- The application processes **everything locally**. The inactivity-learning
  model is stored **encrypted at rest** (Keychain on macOS, DPAPI on Windows),
  with no history and no remote access. The optional camera presence check runs
  **on-device** and discards the image immediately.
- The **only** network access is an **optional update check** that contacts the
  GitHub releases API to see whether a newer version exists — no personal or
  activity data is transmitted.
- Full policy: [Privacy Policy](../PRIVACY.md).

## Liability disclaimer

Per the SignPath Foundation terms, **SignPath Foundation cannot accept any
liability for damages resulting from software signed with its certificates**.
The software is provided "as is" under the MIT License, without warranty.
Responsibility for the content and behavior of the binaries lies with the
project maintainer.

---

🇧🇷 Versão em português: [code-signing-policy.md](code-signing-policy.md)
