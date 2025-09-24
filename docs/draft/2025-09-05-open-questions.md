# YATA Migration — Open Questions (Interview Checklist)

Use this as the live checklist to capture decisions before finalizing standards.

## End-state & Build
- Final target: keep `_lib/` permanently, or is `_lib/` a staging area before moving back to `lib/`?
- Code generation (build_runner, json_serializable, riverpod_generator):
  - Do we plan to customize `build.yaml` to include `_lib/` as inputs, or keep generator-annotated sources under `lib/` until late phase?
- Import policy:
  - Do we standardize on `package:yata/...` imports only? Any exceptions?
  - Are relative imports across `lib/` ↔ `_lib/` acceptable during migration?

## Layer boundaries & Allowed deps
- Allowed import directions (proposed, please confirm or amend):
  - app → {core, features, infra}
  - features → {core, infra?} (prefer depending on abstractions from core?)
  - infra → core (no infra → features)
  - shared → core (UI-only; no infra)
- Do we enforce “features do not import other features” (cross-feature communication via core abstractions or app wiring)?

## DI & Providers (Riverpod)
- Preferred DI style: top-level providers in `app/wiring/provider.dart` vs per-feature provider entrypoints?
- Riverpod generator usage: where to place generated code and how to name providers?
- Naming convention: keep `presentation/providers` or rename to `presentation/controllers`?

## Routing (go_router)
- Central routing (`app/router/app_router.dart`) vs per-feature routers composed at app layer?
- Guards placement (e.g., `app/router/guards` vs feature-level guards)?
- Route naming/path conventions (kebab-case, snake_case, etc.)

## Logging
- Consolidation plan: keep existing infra logging under `_lib/infra/logging` and move abstractions to `_lib/core/logging`?
- Do we keep `LoggerMixin` and “YataLogger”-like facade? Any deprecations planned?
- PII masking policy and default levels (dev vs prod)?

## Error handling
- Global error handler behavior: warn vs fail-fast on invalid env (current code warns). Change for prod?
- Reporting path: log-only vs Sentry/remote sink (future)?

## Supabase & Realtime boundaries
- Supabase client lives in `_lib/infra/supabase`. Is feature code allowed to depend on it directly, or only via repositories/services?
- Realtime: shared mixins in `core` or `infra`? (current: infra)

## Data & repositories
- `data/` split policy: abstractions (interfaces) in `core`, implementations in `infra`? Or keep all repositories under `features/<domain>/repositories`?
- Base repository location: `_lib/infra/repositories/base_repository.dart` acceptable?

## UI/Design system
- `shared/` scope: components, foundations, patterns, themes. Anything else to include (icons, illustrations already present)?
- Naming conventions for components and folders (plural vs singular; suffixes)?

## Naming & conventions
- File/folder naming: snake_case for files, plural folders (`models`, `services`, etc.)?
- Suffix policy: `*_repository.dart`, `*_service.dart`, `*_controller.dart`?
- Barrel files policy: where to allow barrels, and where to avoid them?

## Tests
- Test placement (mirroring folder structure under `test/`)?
- Preferred test style and mocking framework (mocktail is present). Any golden tests for UI?

## Migration mechanics
- Keep `lib/main.dart` as thin wrapper calling `_lib/app/main.dart`?
- Phase order preferences (infra → core → features → app → utils), or adjust?
- Timeline or checkpoints where we must keep the app runnable?

## Anything else to capture?
- Coding standards beyond VGV lints?
- Commit/message conventions and ADR format (if any)?

