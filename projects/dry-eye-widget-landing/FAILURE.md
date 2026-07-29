# Failure Log

## 2026-07-29 — Fresh macOS bundle needed local ad-hoc reseal

- The fresh universal build completed, but the first deep/strict verification
  after DMG generation reported `App.framework` as modified or invalid.
- The DMG checksum itself was valid, so this was not accepted as a release PASS.
- Recovery: reseal the built app locally with an ad-hoc deep signature, rebuild
  the DMG, mount it read-only and verify the app inside the mounted image.
- Final result: mounted app valid, 1.26.0+76, universal x86_64/arm64; DMG valid
  at 29,159,487 bytes with SHA-256
  `5a4f72da8822b8de3c2833302de0db1e418b39227961845b29ffb83e32d5eef6`.
- This does not provide Developer ID notarization and does not remove the need
  for the documented Gatekeeper flow.
- Resolution after the second remediation: a new Flutter build passed
  deep/strict verification directly, without resealing. Its mounted app has
  CDHash `cf52c730050fa5b835068c9e60bc7c78865daa49`; the replacement DMG is valid
  at 29,167,333 bytes with SHA-256
  `b5669182a1fb5e54a842c207ed0776043fa62788d5df467f00b0d1310a8ef1e9`.

## 2026-07-27 — macOS release build stalls in Xcode SDK probe

- Attempt 1: `rtk flutter build macos --release`.
- Attempt 2, after stopping the first cleanly: `flutter build macos --release`.
- Diagnostic change: the equivalent arm64 clang probe completed successfully
  in isolation under a 15-second bound.
- Attempt 3, after that successful preflight: a 10-minute-bounded direct build.
- All build attempts reached `xcodebuild` and then stopped making progress in
  parallel child processes
  equivalent to `clang -v -E -dM ... -x c -c /dev/null`.
- The clang probes remained sleeping at 0% CPU. All build attempts were
  stopped; no installed app or external artifact was changed.
- Static analysis and all 340 tests pass, so the failure is classified as an
  environment/toolchain blocker rather than a demonstrated code regression.
- Recovery: run a bounded Xcode/SDK health preflight, clear only validated
  project-local build state if necessary, then retry once and inspect the fresh
  bundle before any release action.
- Resolution on 2026-07-29: a fresh 1.26.0+76 universal release build completed.
  Deep/strict ad-hoc signature verification and DMG integrity passed. The
  historical stall is no longer a current release blocker.
