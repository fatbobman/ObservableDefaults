# Macro Refactor Summary

This document started as the execution plan for the macro refactor series.
It now records what was completed, what intentionally changed after the pure
refactor phase, and what remains optional.

## Outcome

- The pure refactor phase is complete.
- Macro guardrail tests are now part of the repository and should be kept.
- Several follow-up semantic fixes were completed after the refactor because
  the new guardrails exposed real behavior drift.

## Completed Refactor Work

### Phase 0: Baseline and Safety Rails

Completed:

- established a dedicated refactor branch
- verified baseline builds and full test runs
- added a dedicated macro test target
- added fixture-based macro expansion snapshots
- added formatted snapshot comparisons
- added `SwiftSyntax`-based structure assertions
- added macro diagnostic coverage for high-risk parsing paths

Repository artifacts now in use:

- `Tests/ObservableDefaultsMacroTests/MacroExpansionSnapshotTests.swift`
- `Tests/ObservableDefaultsMacroTests/MacroStructureTests.swift`
- `Tests/ObservableDefaultsMacroTests/MacroDiagnosticTests.swift`
- `Tests/ObservableDefaultsMacroTests/Fixtures/`
- `Tests/ObservableDefaultsMacroTests/__Snapshots__/`

### Phase 1: Low-Risk Shared Helpers

Completed:

- extracted shared `MainActor` host detection
- extracted shared observation boilerplate
- extracted shared backing/default storage generation
- extracted shared property validation and key-resolution helpers
- split overly broad syntax helpers by responsibility

### Phase 2: Internal Modeling Cleanup

Completed:

- introduced shared persisted-property metadata handling
- extracted external change generation helpers as complete logic units
- extracted complete cloud observer helper
- extracted complete defaults observer helper
- added navigation comments in main macro/helper files

Notes:

- a fragment-based observer helper attempt was reverted
- the final observer extraction keeps complete units only

## Completed Post-Refactor Fixes

The following changes were intentionally handled after the pure refactor phase.
These are not "helper extraction" work; they are behavior or diagnostic fixes.

Completed:

- fixed `CloudBacked` diagnostics to use the correct macro type
- diagnosed invalid cloud custom-key expressions
- fixed `@ObservableCloud(observeFirst: true)` so observable-only properties do
  not participate in external cloud notification handling
- preserved `syncImmediately` macro defaults in generated initializers
- diagnosed invalid top-level `prefix` arguments
- diagnosed invalid top-level boolean arguments
- rejected interpolated string arguments for macro string parameters
- preserved escaped plain string literals for whitespace-related parameters
- fixed observer lifetime by weakening observer-to-host references
- stored and removed actual notification tokens instead of calling
  `removeObserver(self)` in block-observer paths
- added runtime regression tests for deallocation and post-release
  notification behavior

## Intentionally Deferred Work

These items are optional and were not required to finish the refactor safely.

### 1. Further Stage-Splitting of Top-Level `expansion`

Current state:

- `ObservableDefaultsMacro.expansion` and `ObservableCloudMacro.expansion`
  are still large, but much clearer than before
- further splitting is optional, not urgent

Only continue if the result is still a complete logic unit, for example:

1. parse config
2. collect property metadata
3. build shared boilerplate
4. build backend-specific observer members
5. build backend-specific initializer members

Do not continue if the extraction would produce template fragments.

### 2. Formatting-Only Cleanup

Current state:

- formatting cleanup was intentionally not pursued aggressively
- some hand-managed indentation remains, especially in
  `ExternalChangeSyntax.swift`

This can be done later, but only in formatting-only commits with snapshot review.

Targets that remain optional:

- remove `caseIndent`
- normalize switch-case template shape across backends
- simplify multi-line string formatting where it improves readability

## Maintenance Rules Going Forward

- Treat macro snapshot diffs as generated-code behavior changes unless the diff
  is clearly formatting-only.
- Prefer complete helper boundaries over string-fragment extraction.
- Keep observer generation as whole units, not preamble/body/deinit fragments.
- Use `swift-testing` by default for new tests; keep `XCTest` only where macro
  testing APIs still require it.
- Run `swift test --filter ObservableDefaultsMacroTests` for macro-generation,
  macro-diagnostic, or generated-format changes.

## Recommended Close-Out

The refactor series does not require more mandatory code changes.

Reasonable next steps are:

1. merge the branch after one final review
2. optionally do a small formatting-only follow-up later
3. optionally revisit top-level `expansion` stage-splitting only if a future
   change makes those files hard to maintain again
