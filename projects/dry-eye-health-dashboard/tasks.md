# Live Task Queues

## now

- [x] Create branch `codex/healthkit-dashboard`.
- [x] Define dashboard data model.
- [x] Specify metric sources, units, and HealthKit boundaries.
- [x] Add tests for source mapping and missing-data behavior.

## next

- [ ] Add native HealthKit capability investigation for Apple platforms.
- [ ] Create HealthKit service interface and platform adapter.
- [ ] Persist local dashboard events for pauses, colirio confirmations, and blink suggestions.
- [ ] Design the dashboard UI.

## blocked

- Native HealthKit import depends on choosing supported Apple targets and entitlements.
- Screen Time import from Apple APIs is not part of HealthKit and requires a separate capability decision.

## improve

- Add privacy copy before collecting any new behavioral aggregate.
- Add fixture-based tests for day/week/month aggregation.

## recurring

- Re-check Apple HealthKit and Screen Time API availability before native implementation.
