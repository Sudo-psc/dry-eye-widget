# Decisions

## 2026-07-29 — Release fan-in and retry safety

- Keep platform workflows and the `workflow_run` fan-in read-only. The fan-in
  only reconciles macOS, Windows and MSIX for the same source SHA and uploads a
  validated evidence bundle.
- Never expose signing secrets to workflows loaded from an arbitrary tag.
- Checkout and execute release-control scripts only from the default branch;
  validate annotated tag, source SHA, metadata and main ancestry without a
  privileged follow-up job.
- Keep GitHub Release publication outside Actions until remote rulesets,
  protected refs and protected environments are explicitly authorized. The
  manual publisher requires approval bound to the exact reviewed tag, commit
  and canonical digest of the four artifacts plus three manifests before any
  remote call.
- Treat a matching published release as an idempotent success, with no upload
  or edit. Remove unexpected assets only from a draft.
- After publication, reconcile `latest` to the greatest published stable
  SemVer; opposite publication orders must converge to the same result.
- Accept exactly four release binaries and three manifests. Reject extra files,
  including the unrelated local video, before any release mutation.
- Reconcile local and remote assets by both byte size and SHA-256 digest.

## 2026-07-27 — PDF, startup and release reliability

- Treat packaged PDF fonts as required inputs, not optional fallbacks. Cache
  them only after the complete family is available so one failed load cannot
  degrade later reports silently.
- Keep native screen/window APIs behind an injectable startup-restoration
  boundary; geometry and failure behavior must be testable without a desktop.
- Separate release readiness into local metadata, tag-at-HEAD and public
  artifact gates. Passing an earlier gate never implies a later one passed.
- Keep commit, push, tag and publication as separately authorized actions.

## 2026-06-09

- Keep download links on GitHub Releases for open-source transparency and simple update behavior.
- Treat deployment, DNS, and separate GitHub repo creation as post-local-build tasks because they need external access/confirmation.

## 2026-06-19

- Use `site/` as the official static landing implementation inside the existing Flutter repository.
- Use `olhossecos.com.br/app/` as the single canonical landing route.
- Keep PT/EN support as a client-side language toggle instead of separate landing routes.
- Keep GitHub Pages publishing from `site/` as the current deployment path.

## 2026-07-10 — Science page

- Keep the main landing static and isolated; author the more complex Science page in `web/science/` and prerender it into the same `site/` deployment artifact.
- Use relative generated assets so the artifact works at both GitHub Pages `/science/` and the canonical custom-domain `/app/science/`.
- Treat `/app/science/` as an English scientific subpage rather than a second language variant of the main landing.
- Prioritize TFOS DEWS III as current consensus while retaining foundational TFOS DEWS II citations.
- Label OVPP export, biomarkers, AI and multicenter studies as research roadmap items, not current product functionality.
- Inline the generated Tailwind stylesheet and defer React/Framer hydration until idle because the page is already fully prerendered; this preserves interactivity while keeping Lighthouse at 100.

## 2026-07-16 — App reliability audit

- Resolve screen-sensitive widget layout against the display containing the
  current window center, with nearest-display and primary-display fallbacks.
- Keep one canonical compact coordinate and never derive it from temporary
  menu, reminder, break, settings, dashboard or questionnaire layouts.
- Treat local activity and screen-time persistence as part of graceful shutdown;
  flush it before closing the native window even if collection already stopped.
- Implement launch-at-login with Apple's ServiceManagement API on macOS 13 or
  later, while retaining the existing package implementation for Windows.

## 2026-07-16 — Expanded menu anchoring

- Preserve the orb's visual screen coordinate, not its fixed local position,
  when the larger menu window must move to remain inside visible screen bounds.
- Treat the menu orb as a close control with no drag recognizers; compact-mode
  dragging remains unchanged.
