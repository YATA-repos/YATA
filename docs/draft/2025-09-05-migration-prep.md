# YATA Migration Prep — Current Understanding (2025-09-05)

This note captures what we’re confident about and a first-pass mapping from `lib/` to `_lib/`.

## Intent (inferred)
- Clarify layers: `app` (boot/DI/routing), `core` (cross-cutting/domain-agnostic), `infra` (IO/externals), `features` (vertical slices), `shared` (design system/UI).
- Consolidate domain code per feature: `features/<domain>/{models,repositories,services,presentation,routing}`.
- Centralize UI assets/design under `shared/`.
- Enable phased migration using barrels/exports in `lib/` while moving implementations to `_lib/`.

## High-level mapping proposal

- lib/app → _lib/app
  - app.dart → app.dart
  - di.dart → wiring/provider.dart
  - routes.dart → router/app_router.dart (+ guards/)

- lib/infrastructure/** → _lib/infra/**
  - realtime/* → infra/realtime/*
  - supabase/* → infra/supabase/*
  - logging/* → infra/logging/* (concrete impl)

- lib/core/** → _lib/core/**
  - base/* → core/base/*
  - constants/* → core/constants/*
  - validation/* → core/validation/* (to be created)
  - logging abstractions (levels/mixins) → core/logging/*

- lib/features/<domain>/{dto,models,repositories,services,presentation} → _lib/features/<domain>/{dto,models,repositories,services,presentation}
  - presentation/providers → presentation/controllers (if approved)
  - feature-level routing → features/<domain>/routing

- lib/data/** → (split)
  - repositories/base_repository.dart → _lib/infra/repositories/base_repository.dart
  - batch/batch_processing_service.dart → _lib/infra/batch/batch_processing_service.dart

- lib/utils/** → (by concern)
  - error_handler.dart → _lib/core/utils/error_handler.dart
  - provider_logger_{new_api,old}.dart → _lib/core/logging/
  - query_utils.dart → _lib/core/utils/query_utils.dart
  - responsive_helper.dart → _lib/shared/foundations/layout/responsive_helper.dart
  - stream_manager_mixin.dart → _lib/core/utils/stream_manager_mixin.dart

- lib/main.dart → keep as thin wrapper; move actual boot logic to _lib/app/main.dart

## Build & tooling considerations (risks)
- build_runner/json_serializable/riverpod_generator typically watch `lib/` only.
  - If source lives under `_lib/`, generation may not run unless build.yaml is customized.
  - Recommendation: keep generators’ source files in `lib/` until migration policy is decided, or configure builders to include `_lib/`.
- Import policy: prefer `package:yata/...`; relative imports from `lib/` into `_lib/` are fragile and lint-unfriendly.

## Next actions
- Confirm end-state target (keep `_lib/` long-term vs. temporary staging before renaming back to `lib/`).
- Decide import/codegen policy before moving generator-annotated files.
- Write standards in `docs/standards/architecture.md` and map allowed dependencies.

