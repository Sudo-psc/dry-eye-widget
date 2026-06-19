# Live Task Queues

## now

- [x] Inspect repository and infer runtime constraints.
- [x] Create local operating summary and implementation contract.
- [x] Confirm `site/` as the official `/app/` landing.
- [x] Verify build and local render.
- [x] Apply priority fixes from repository review.
- [x] Run static smoke check and Flutter checks.

## next

- [x] Capture or replace carousel with real app screenshots when available.
- [ ] Add Windows-specific installer/tray screenshots when available.
- [ ] Run production-like Lighthouse after deployment.
- [ ] Prepare VPS deploy notes.
- [ ] Decide whether landing should live in this repo or a separate GitHub repo.

## blocked

- VPS deployment is blocked until server access and deployment path are provided.
- DNS configuration is blocked until DNS provider access is provided.
- Separate landing repo creation is blocked until the desired GitHub organization/name is confirmed.

## improve

- [x] Add an automated landing smoke test that checks canonical route, script safety, and i18n coverage.
- [x] Add CI coverage for the static site smoke check.
- Track Flutter macOS Swift Package Manager warnings for `screen_retriever_macos`, `tray_manager`, and `local_notifier`.
- Add real app screenshots from macOS and Windows release runs.
- Add structured article metadata for future blog expansion.

## recurring

- Review release download URLs after each GitHub release.
- Review scientific references when adding clinical claims.
- Re-run performance checks before each public launch.
