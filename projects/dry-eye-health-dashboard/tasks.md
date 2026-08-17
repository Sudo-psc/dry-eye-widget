# Live Task Queues

## completed

- [x] Create branch `codex/healthkit-dashboard` (historical spike).
- [x] Define dashboard data model.
- [x] Specify metric sources, units, and HealthKit boundaries.
- [x] Add tests for source mapping and missing-data behavior in branch spike.
- [x] Audit code vs checklist: HealthKit implementation isolated in historical spike branch; `main` retains independent Visual Health Hub (`Resumo do dia`, `Estatísticas de Pausas`, `Tempo de Tela`, `DVRS`).

## future / roadmap (backlog)

- [ ] Add native HealthKit capability investigation for Apple platforms when signed build / entitlements pipeline is ready (#55, #58).
- [ ] Create HealthKit service interface and platform adapter.
- [ ] Persist local dashboard events for pauses, colirio confirmations, and blink suggestions.
- [ ] Integrate HealthKit dashboard UI into the main visual health hub.

## blocked

- Native HealthKit import depends on choosing supported Apple targets and entitlements (#55, #58).
- Screen Time import from Apple APIs is not part of HealthKit and requires a separate capability decision.

## improve

- Add privacy copy before collecting any new behavioral aggregate.
- Add fixture-based tests for day/week/month aggregation.
