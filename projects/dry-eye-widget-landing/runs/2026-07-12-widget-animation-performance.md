# Widget animation performance

Date: 2026-07-12

Objective: reduce continuous rendering work while preserving interaction quality.

Changes:

- Quantized the liquid-orb visual phase to 64 idle steps per 3.2 seconds and 45 active steps per 1.8 seconds.
- Quantized the urgent ring phase to 52 steps per 2.6 seconds.
- Disabled the continuous ring ticker below 90% progress.
- Kept hover, press, drag and release controllers unthrottled.

Expected impact:

- Idle liquid updates are capped near 20 fps, about 67% fewer visual notifications on 60 Hz and 83% fewer on 120 Hz displays.
- Most of the break cycle no longer keeps the ring ticker active.

Evidence:

- Focused widget suite: 10 tests passed.
- Deterministic regression test confirms at most 65 idle and 46 active visual phases per cycle.
- Widget test confirms no transient callbacks remain after settling at 68% progress and continuous activity begins at 94%.

Final verification:

- Full analysis passed with no issues.
- All 238 tests passed.
- macOS release build passed; app bundle size 59.3 MB.
- Diff whitespace validation passed.
