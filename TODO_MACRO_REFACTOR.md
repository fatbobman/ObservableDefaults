# Macro Refactor TODO

This document defines the safety rails for refactoring macro generation code without changing user-visible behavior.

## Goals

- Keep runtime behavior unchanged.
- Keep generated code structure unchanged unless a step explicitly targets formatting.
- Make every refactor step independently verifiable and reversible.
- Add dedicated tests for macro expansion and formatting so future cleanups are cheaper.

## Non-Goals

- No feature changes during the refactor series.
- No semantic cleanup mixed into helper extraction.
- No README or public API changes unless a real behavior change is intentionally introduced later.

## Ground Rules

- Work on a dedicated branch only.
- Each commit should contain one refactor step or one test-only step.
- Every refactor step must pass full `swift test`.
- If a refactor step changes generated code text unexpectedly, stop and inspect before continuing.
- Formatting-only changes must happen in dedicated commits after semantic-preserving helper extraction is complete.

## Safety Layers

Each step should be validated by all applicable layers below:

1. Existing behavioral tests
2. Full compile check
3. Macro expansion snapshot comparison
4. Formatted expansion snapshot comparison
5. Targeted structure assertions for generated declarations

## Phase 0: Baseline

1. Confirm clean worktree.
2. Run `swift build`.
3. Run full `swift test`.
4. Capture a baseline set of macro expansions for representative fixtures.
5. Format the captured expansions with repository `.swift-format`.
6. Save the formatted output as the initial snapshot baseline.

## Phase 1: Add Refactor Guardrails

### 1.1 Expansion Fixtures

Create a small but representative fixture set covering:

- `@ObservableDefaults` basic usage
- `@ObservableDefaults(observeFirst: true)`
- `@ObservableDefaults` with `suiteName`, `prefix`, `limitToInstance`
- `@DefaultsBacked(userDefaultsKey:)`
- `@DefaultsKey(userDefaultsKey:)`
- optional defaults-backed property
- `@ObservableCloud` basic usage
- `@ObservableCloud(observeFirst: true)`
- `@ObservableCloud(developmentMode: true)`
- `@CloudBacked(keyValueStoreKey:)`
- `@CloudKey(keyValueStoreKey:)`
- `@ObservableOnly`
- `@MainActor` host class

### 1.2 Expansion Snapshot Test

Preferred approach:

- Create a test target dedicated to macro expansion snapshots.
- Use a fixture source file per scenario.
- Invoke macro expansion through a deterministic compiler command.
- Normalize the output before diffing.

Suggested normalization pipeline:

1. Dump macro expansions.
2. Strip irrelevant environment-specific paths if present.
3. Run `swift-format --configuration .swift-format`.
4. Compare against checked-in snapshots.

Acceptance rule:

- Helper extraction commits should produce zero snapshot diffs.
- If a diff appears, treat it as a blocker until explained.

### 1.3 Structure Tests

Add focused assertions by parsing expanded output with `SwiftSyntax`.

Assert only high-value invariants, for example:

- `_$observationRegistrar` exists
- `access` exists
- `withMutation` exists
- `_defaultsKeyPathMap` exists only for defaults-backed host macros
- observe-first defaults fixtures only map explicitly backed properties
- cloud fixtures keep `_developmentMode_` behavior branches
- backed properties still generate storage and declaration-time default storage

These tests should be resilient to whitespace-only changes.

### 1.4 Diagnostic Tests

Add dedicated coverage for macro diagnostics relevant to refactor risk:

- non-string literal key parameters
- invalid `suiteName` expression
- `willSet` and `didSet` warning behavior
- missing initializer on non-optional backed properties

## Phase 2: Low-Risk Shared Helpers

Apply one step per commit.

### 2.1 Extract class actor-detection helper

Target examples:

- detect `@MainActor` on containing class
- unify repeated host-class scanning logic

Validation:

- `swift test`
- expansion snapshots unchanged
- formatted snapshots unchanged

### 2.2 Extract shared observation boilerplate builder

Target examples:

- `_$observationRegistrar`
- `access`
- `withMutation`
- shared `shouldSetValue` declarations

Validation:

- `swift test`
- expansion snapshots unchanged
- formatted snapshots unchanged

### 2.3 Extract shared backing storage/default storage builder

Target examples:

- `_property` storage
- `_default_value_of_<property>` storage
- optional `= nil` handling
- explicit type-annotation preservation

Validation:

- `swift test`
- expansion snapshots unchanged
- formatted snapshots unchanged
- targeted fixtures for optional and inferred-type defaults unchanged

### 2.4 Extract shared key-resolution helper

Target examples:

- property-name fallback
- backed-attribute priority over key-marker attribute
- consistent non-string-literal handling

Validation:

- `swift test`
- diagnostic tests
- expansion snapshots unchanged

## Phase 3: Internal Modeling Cleanup

Only start this phase after Phase 2 is stable.

### 3.1 Introduce shared metadata types

Possible candidates:

- macro configuration structs
- persisted-property metadata struct
- observer-generation input model

Goal:

- Replace anonymous tuples and repeated string assembly with typed intermediate data.

Validation:

- `swift test`
- expansion snapshots unchanged
- structure tests unchanged

### 3.2 Split large `MemberMacro.expansion` functions into stages

Suggested stages:

1. parse config
2. collect property metadata
3. build shared boilerplate
4. build backend-specific observer code
5. build backend-specific initializer code

Validation:

- `swift test`
- expansion snapshots unchanged
- structure tests unchanged

## Phase 4: Formatting Cleanup

Formatting changes must be isolated in their own commits after semantic refactor work is done.

Targets:

- remove hand-managed indentation tricks such as `caseIndent`
- make switch-case templates consistent across backends
- normalize multi-line string formatting style
- fix internal naming inconsistencies and typos only when they do not affect generated API

Validation:

- `swift test`
- structure tests unchanged
- snapshot updates reviewed as formatting-only diffs

## Command Checklist Per Step

Run this minimum sequence after every refactor commit:

```bash
swift build
swift test
```

Run this full sequence once expansion tests exist:

```bash
swift build
swift test
swift test --filter MacroExpansion
swift test --filter MacroStructure
swift test --filter MacroDiagnostics
```

## Suggested Repository Additions

These can be added in later commits:

- `Tests/ObservableDefaultsMacroExpansionTests/`
- `Tests/ObservableDefaultsMacroExpansionTests/Fixtures/`
- `Tests/ObservableDefaultsMacroExpansionTests/__Snapshots__/`
- `Scripts/` helper for expansion capture if the compiler invocation becomes too verbose

If a script is added, keep it deterministic and side-effect free.

## Review Checklist Per Commit

- Does the commit change runtime semantics?
- Does the commit change generated declaration names?
- Does the commit change snapshot text?
- If snapshot text changed, is it formatting-only?
- Is there a dedicated test covering the helper or branch being extracted?
- Can the commit be reverted independently?

## Stop Conditions

Stop the series and inspect immediately if any of the following happen:

- full `swift test` fails
- expansion snapshots change during a helper-only commit
- diagnostics change unexpectedly
- generated code for observe-first behavior changes
- generated code for declaration-time default capture changes

## First Execution Order

1. Add expansion fixtures.
2. Add expansion snapshot tests.
3. Add structure tests.
4. Add diagnostic tests missing for refactor risk.
5. Extract `@MainActor` detection helper.
6. Extract shared observation boilerplate.
7. Extract shared backing/default storage builder.
8. Extract shared key/config helpers.
9. Perform formatting-only cleanup at the end.
