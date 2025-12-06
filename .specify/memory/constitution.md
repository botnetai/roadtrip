<!--
SYNC IMPACT REPORT
==================
Version Change: (new) → 1.0.0
Bump Rationale: Initial constitution creation (MAJOR)

Added Principles:
- I. UX Clarity & Delight
- II. Visual Polish & Beauty
- III. Modular Architecture
- IV. Simplicity First
- V. Maintainability by Design

Added Sections:
- Quality Standards (solo dev pragmatism)
- Development Workflow (efficient solo process)
- Governance

Templates Requiring Updates:
- .specify/templates/plan-template.md ✅ (no changes needed - Constitution Check section is generic)
- .specify/templates/spec-template.md ✅ (no changes needed - priority-based stories align with principles)
- .specify/templates/tasks-template.md ✅ (no changes needed - phase structure supports incremental polish)

Deferred Items: None
==================
-->

# AI Voice Copilot Constitution

## Core Principles

### I. UX Clarity & Delight

Every interaction MUST be immediately understandable. Users should never wonder "what just happened?" or "what do I do next?"

- **Clarity over cleverness**: Prefer obvious UI patterns over novel interactions
- **Feedback is mandatory**: Every user action MUST have visible/audible acknowledgment within 100ms
- **Delight through thoughtfulness**: Add micro-interactions, smooth transitions, and haptics where they reduce cognitive load—not as decoration
- **Error states are UX**: Error messages MUST explain what went wrong AND what the user can do about it
- **Accessibility is non-negotiable**: Support VoiceOver, Dynamic Type, and reduced motion from day one

**Rationale**: A solo dev cannot afford support burden from confused users. Investing in clarity upfront reduces maintenance and improves retention.

### II. Visual Polish & Beauty

The app MUST feel premium and intentionally designed. Visual quality directly impacts perceived value and user trust.

- **Consistent design language**: Use a defined color palette, typography scale, and spacing system across all screens
- **Animation with purpose**: Every animation MUST serve a functional purpose (orientation, feedback, state change)—remove gratuitous motion
- **Pixel-perfect alignment**: Elements MUST align to a consistent grid; misalignments erode trust
- **Platform conventions**: Follow Human Interface Guidelines; deviate only with clear justification
- **Dark mode parity**: Both modes MUST receive equal design attention—dark mode is not an afterthought

**Rationale**: Beauty creates emotional connection. Users forgive minor bugs in apps that feel crafted; they abandon ugly apps at the first friction.

### III. Modular Architecture

Code MUST be organized into self-contained, reusable modules with clear boundaries and single responsibilities.

- **Feature isolation**: Each feature lives in its own module with explicit public interface
- **Dependency injection**: Services MUST be injected, never instantiated internally—enables testing and reuse
- **Protocol-first design**: Define protocols before implementations; depend on abstractions
- **No circular dependencies**: Module dependency graph MUST be acyclic
- **Package-ready**: Any module should be extractable to a separate package with minimal effort

**Rationale**: Solo devs need to work on one thing at a time without breaking others. Modularity enables fearless refactoring and component reuse across projects.

### IV. Simplicity First

Solve today's problem with today's simplest solution. Complexity MUST be earned, not anticipated.

- **YAGNI enforced**: Do not add functionality until it's demonstrably needed
- **Three uses rule**: Extract abstractions only after three concrete uses—not before
- **Minimal dependencies**: Each external dependency MUST justify its weight; prefer built-in APIs
- **Delete over deprecate**: Remove unused code immediately; version control remembers
- **One way to do things**: Avoid multiple patterns for the same problem within the codebase

**Rationale**: Solo devs cannot maintain complexity they don't need. Every abstraction is future maintenance burden. Simplicity is sustainable.

### V. Maintainability by Design

Code MUST be written for the future developer (yourself in 6 months) who has forgotten all context.

- **Self-documenting naming**: Names MUST reveal intent; if a comment explains "what," rename instead
- **Small functions**: Functions longer than 20 lines SHOULD be split; longer than 40 MUST be split
- **Obvious data flow**: State changes MUST be traceable; avoid action-at-a-distance
- **Test critical paths**: Core user journeys MUST have integration tests; edge cases get unit tests
- **Consistent patterns**: Use the same patterns throughout—predictability reduces cognitive load

**Rationale**: A solo dev is the entire team across time. Code that's hard to return to becomes code that doesn't get maintained.

## Quality Standards

Solo development demands pragmatic quality gates that maximize impact with limited time.

### Must Have (Every PR)

- App launches without crash on supported iOS versions
- Core user journey (start call → converse → end call) works end-to-end
- No compiler warnings in production code
- UI renders correctly in both light and dark mode
- Accessibility audit passes for new/changed screens

### Should Have (Before Release)

- All public APIs have documentation comments
- Unit tests cover business logic and edge cases
- Integration tests cover critical paths
- Performance profiled on oldest supported device
- Memory leaks checked with Instruments

### Nice to Have (Continuous Improvement)

- Code coverage above 70% for business logic
- UI snapshot tests for complex screens
- Automated accessibility testing
- Performance regression tests

## Development Workflow

Efficient process for a solo developer shipping quality software.

### Feature Development

1. **Spec first**: Write a brief spec before coding—clarifies thinking
2. **Vertical slices**: Implement features as complete user journeys, not horizontal layers
3. **Ship early**: Get to a working state quickly; polish iteratively
4. **Dogfood daily**: Use the app yourself every day during development

### Code Quality

1. **Small commits**: Each commit SHOULD be a single logical change
2. **PR self-review**: Review your own diff before merging—catches obvious issues
3. **Refactor in separate PRs**: Keep feature work and refactoring separate

### Release Cadence

1. **Weekly builds**: TestFlight build at least weekly during active development
2. **Changelog discipline**: Document user-facing changes as you go
3. **Staged rollouts**: Use phased releases for App Store updates

## Governance

This constitution guides all development decisions for AI Voice Copilot.

### Authority

- Constitution principles override convenience or "quick fixes"
- Violations require explicit justification in PR description
- Justified violations MUST include plan to address technical debt

### Amendments

- **Process**: Document change rationale, update constitution, update affected templates
- **Versioning**: MAJOR for principle changes, MINOR for new guidance, PATCH for clarifications
- **Review**: Re-read constitution quarterly; remove rules that aren't helping

### Compliance

- PR reviews (self-review for solo) MUST check constitution alignment
- Complexity additions require justification per Principle IV
- Design decisions document which principles guided them

**Version**: 1.0.0 | **Ratified**: 2025-12-06 | **Last Amended**: 2025-12-06
