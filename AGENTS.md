# Dry Eye Widget - Agent Operating Guide

This repository is a local-first project. Before meaningful work, read:

- `.agent/operating-summary.md`
- `projects/dry-eye-widget-landing/status.md`
- `projects/dry-eye-widget-landing/tasks.md`
- `projects/dry-eye-widget-landing/handoff.md`

Default posture:

- Prefer real artifacts over strategy-only answers.
- Keep the Flutter app and the static landing page isolated.
- Verify non-trivial changes with build, tests, or browser evidence.
- Record decisions, blockers, and next actions in project files.
- Do not touch unrelated user changes.

Current web landing lives in `site/` (static, deployed via GitHub Pages and served at olhossecos.com.br/app/).

- **Commits:** Do NOT add `Co-authored-by: Claude` or any other AI co-authorship to commit messages.
- **Communication:** Always respond to the user using plain text without markdown formatting (no bold, no italics, no lists, no code blocks, etc.).
