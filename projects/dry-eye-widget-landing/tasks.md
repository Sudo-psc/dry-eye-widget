# Live Task Queues

## now

- [x] 2026-07-29: sincronizar a landing com a versão 1.26.0.
- [x] 2026-07-29: neutralizar claims médicos incompatíveis com o escopo educativo.
- [x] 2026-07-29: localizar textos alternativos e respeitar reduzir movimento.
- [x] 2026-07-29: passar smoke e gate de metadados.
- [x] 2026-07-29: fechar manifests, fan-in, idempotência e gates locais.
- [x] Obter revisão independente somente leitura antes de qualquer integração.
- [x] Remediar os achados P1/P2 e repetir gates sem ação remota.
- [x] Tornar o fan-in estritamente read-only e separar publicação manual.
- [x] Concluir o novo freeze após regressão e build macOS.
- [x] Submeter o freeze anterior à terceira revisão independente somente leitura.
- [x] Vincular aprovação aos sete arquivos e convergir `latest` por SemVer.
- [x] Remover texto de alerta DVRS persistido e completar localização PT/EN.
- [x] Concluir gates e novo build da quarta remediação.
- [x] Gerar o freeze da quarta remediação.
- [x] Submeter o novo freeze à quarta revisão independente somente leitura.
- [x] Concluir a quarta revisão com P0=0/P1=0/P2=0.
- [ ] Solicitar autorização explícita separada para commit/push/tag.
- [ ] Após runners/fan-in, revisar o bundle e solicitar nova aprovação
      `tag+commit+digest` para publicação manual.
- [ ] Verificar o deploy 1.26.0 no GitHub Pages após o push.

- [x] 2026-07-27: Embed deterministic Unicode-capable fonts in every PDF and
  add a regression test for accented and typographic text.
- [x] 2026-07-27: Extract startup window restoration into an injectable service
  and cover monitor/fallback behavior with five tests.
- [x] 2026-07-27: Add metadata, tag and published-asset release gates and wire
  the local/tag gates into GitHub Actions.
- [x] 2026-07-27: Pass static analysis and the complete 340-test Flutter suite.

- [x] Preserve the orb's visual origin when the expanded menu is clamped to the screen.
- [x] Position the menu panel above or below according to the available space around the orb.
- [x] Make the open-menu orb close the menu directly and remove inactive pan recognizers.
- [x] Add menu-origin and click regression tests; run analysis, full tests and macOS release build.

- [x] Audit lifecycle, layout, persistence and native-window boundaries for reproducible app defects.
- [x] Make screen-sensitive widget operations follow the current display in multi-monitor setups.
- [x] Preserve the compact anchor when an automatic break interrupts a centered panel.
- [x] Flush pending activity and screen-time state before native app shutdown.
- [x] Restore the missing macOS launch-at-login platform channel and add a source regression gate.
- [x] Add regression coverage and run analysis, full tests, release build, signature check and local launch.

- [x] Remove velocity-driven acceleration from the orb's internal material.
- [x] Preserve the exact compact widget position while opening and closing the menu.
- [x] Disable drag-position persistence while the expanded menu is visible.
- [x] Serialize native layout changes to prevent open/close races.
- [x] Add anchor and motion regression tests; run analysis, all tests and macOS build.

- [x] 2026-07-13: Replace the legacy README screenshot carousel with current v1.24 menu and daily-summary captures in PT-BR and EN.

- [x] Reduce continuous floating-orb repaint frequency without changing animation duration.
- [x] Pause progress-ring animation below the urgency threshold.
- [x] Add regression tests for bounded visual phases and adaptive ring activity.
- [x] Complete full analysis, test suite and macOS release build verification.

- [x] Inspect repository and infer runtime constraints.
- [x] Create local operating summary and implementation contract.
- [x] Confirm `site/` as the official `/app/` landing.
- [x] Verify build and local render.
- [x] Apply priority fixes from repository review.
- [x] Run static smoke check and Flutter checks.
- [x] Create HealthKit dashboard branch.
- [x] Define integrative dashboard data model.
- [x] Add native macOS HealthKit bridge for sleep and average heart rate.
- [x] Add Dart service that maps native HealthKit rows to dashboard periods.
- [x] Verify analysis, focused tests, and unsigned Xcode compile.
- [x] Connect the dashboard UI to `HealthKitDashboardService`.
- [x] Add a visible optional HealthKit permission flow.
- [x] Add menu and tray access to the Health dashboard.
- [x] Add widget tests for Health dashboard permission/data states.
- [x] Fix widget positioning bug: random position jumps when switching layouts (menu, blink reminder, ball).
- [x] Create the premium scientific foundation page at `/app/science/`.
- [x] Add React/TypeScript/Tailwind/Framer/Lucide source with static prerender output.
- [x] Integrate Science into main navigation, SEO, sitemap, CI and Pages deployment.
- [x] Validate scientific claims and expose at least 10 DOI-linked references.
- [x] Verify responsive light/dark UI and Lighthouse scores of at least 95.

## next

- [x] Re-run the macOS release build after the local Xcode SDK-probe stall and
  repeat strict signature and DMG integrity QA on the fresh bundle.
- [ ] Independently review, then commit only with explicit authorization,
  excluding the unrelated
  `gemini_generated_video_B3916D35.mp4`.
- [x] Reconcile the published v1.25.2 release and its four remote artifacts
  with the isolated evidence run; v1.26.0 is the next release scope.
- [ ] Decidir separadamente se o protótipo histórico HealthKit deve ser
  reproposto em uma futura branch; ele não integra a `main` atual.
- [x] Capture or replace carousel with real app screenshots when available.
- [x] Add Windows-specific installer/tray screenshots when available.
- [x] 2026-07-12: Refresh the macOS carousel with the current liquid orb/menu and daily summary UI.
- [x] Add a repeatable isolated preview and desktop/mobile carousel capture path.
- [ ] Run production-like Lighthouse after deployment.
- [ ] Verify `/app/science/` on the production custom domain after Pages deploy.
- [ ] Prepare VPS deploy notes.
- [x] Decide that the landing remains in this repository under `site/`.

## blocked

- Windows/MSIX and real fan-in evidence are blocked until a reviewed commit and
  tag are separately authorized and run on GitHub Actions.
- Public v1.26.0 completeness remains blocked by independent review and explicit
  authorization for each later remote mutation.
- VPS deployment is blocked until server access and deployment path are provided.
- DNS configuration is blocked until DNS provider access is provided.
- Separate landing repo creation is blocked until the desired GitHub organization/name is confirmed.

## improve

- Add a bounded Xcode SDK-health preflight so future macOS builds fail clearly
  instead of waiting indefinitely during the clang capability probe.
- [x] Add a read-only fan-in workflow that emits a validated bundle only after
  all three platform workflows succeed for the same source SHA.
- [x] Add an automated landing smoke test that checks canonical route, script safety, and i18n coverage.
- [x] Add CI coverage for the static site smoke check.
- [x] 2026-07-10: five landing quick-win cycles (version badge, a11y, features, FAQ, sitemap/smoke version sync).
- [x] 2026-07-10: five workflow/roadmap cycles (ci.yml, dependabot, scheduled smoke, issue template, ROADMAP.md).
- [x] Add Science-specific smoke checks for prerendering, MedicalWebPage, DOI count, relative assets, social preview and bundle budget.
- Add an annual scientific-reference freshness review for TFOS/AAO updates.
- Add signed-runtime QA evidence for HealthKit permission states: unavailable, denied, authorized and no samples.
- Track Flutter macOS Swift Package Manager warnings for `screen_retriever_macos`, `tray_manager`, and `local_notifier`.
- Decide whether macOS 10.15-12 should gain a bundled legacy login helper or
  whether the documented minimum for launch-at-login should remain macOS 13.
- Add real app screenshots from macOS and Windows release runs.
- Refresh Windows captures from a real v1.24+ Windows session so the platform set matches the current menu architecture.
- Add structured article metadata for future blog expansion.
- Add a profile-mode frame-timing benchmark for the floating widget on 60 Hz and 120 Hz displays.
- Add a macOS integration test driver that clicks the frameless widget using
  display-aware coordinate conversion on multi-monitor Retina setups.
- Serialize DVRS draft and settings persistence if runtime evidence exposes
  overlapping-write loss under rapid interactions.
- [x] 2026-07-13: reposicionar DVRS como registro educativo não validado no app, site e textos legais.
- [x] Add a claims regression gate for DVRS copy in app and public landing.

## recurring

- Review release download URLs after each GitHub release.
- Review scientific references when adding clinical claims.
- Re-run performance checks before each public launch.
