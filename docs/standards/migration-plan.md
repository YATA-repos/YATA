# Migration Plan — lib → _lib (one-shot)

Status: Accepted

## Overview
Perform a one-shot migration from `lib/` to `_lib/`, update all relative imports, validate build, then remove `lib/` and rename `_lib/` to `lib/`.

## Prereqs
- Freeze feature changes during migration window.
- Ensure a clean working directory and a backup branch.

## Steps
1) Create final `_lib/` directory layout (empty dirs included).
2) Move `lib/` content into `_lib/` per architecture mapping:
   - `lib/app` → `_lib/app` (routes → router/, di → wiring/)
   - `lib/core` → `_lib/core` (base/constants/validation/logging abstractions)
   - `lib/infrastructure` → `_lib/infra` (realtime/supabase/logging impl/local)
   - `lib/features/<domain>` → `_lib/features/<domain>` (dto/models/repositories/services/presentation/routing)
   - `lib/data` → split: abstractions → core; common impl → infra; domain-bound impl → features
   - `lib/utils` → core/utils or shared/* according to concern
3) Update all relative imports to match the new layout (keep relative style).
4) Analyze and build: `flutter analyze`, `flutter build` (or `flutter test`) until clean.
5) Remove the old `lib/` directory.
6) Rename `_lib/` to `lib/`.
7) Run codegen: `flutter pub run build_runner build --delete-conflicting-outputs`.

## Post-steps
- Verify logging config and PII masking work as expected.
- Run smoke tests across critical flows (auth, inventory, order).

## Notes
- No temporary wrappers or bridging barrels are used due to the one-shot policy.
- Barrels are allowed only under: `features/`, `core/`, and `shared/{themes,widgets}`.

