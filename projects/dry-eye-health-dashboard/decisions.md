# Decisions

## 2026-06-19

- Start with a data-contract branch instead of direct native HealthKit wiring.
- Treat HealthKit as the preferred source only for sleep and average heart rate in the MVP.
- Treat screen time as an app metric, not a HealthKit metric.
- Keep medications and free symptoms user-reported until a permitted source is explicitly selected.
- Keep click and keystroke metrics future-only, aggregate-only, opt-in, and privacy-gated.
- Represent missing data explicitly with availability states instead of dropping empty metrics.
