# Dry Eye Health Dashboard

## Mission

Build an integrative clinical dashboard that combines Dry Eye Widget data with permitted HealthKit data to support longitudinal review of dry-eye symptoms, screen habits, breaks, sleep, and heart-rate context.

## Branch

`codex/healthkit-dashboard`

## First Milestone

Define the data contract before native integration:

- metric catalog;
- HealthKit import boundaries;
- app versus HealthKit source mapping;
- missing-data behavior;
- extensible Dart model;
- tests for source and availability semantics.

## Non-goals for this milestone

- No HealthKit permission prompt yet.
- No native Swift bridge yet.
- No clinical diagnosis or treatment recommendation.
- No collection of click coordinates, key contents, cursor history, or typed text.
