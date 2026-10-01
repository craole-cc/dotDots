# Swarm Operating Contract

This contract coordinates three models and the task owner/user on repository
work. The task owner/user sets intent, scope, priorities, and final product
decisions. Read `Documentation/ai/AGENTS.md` and relevant local guides before
changing code.

## Roles and phase ownership

| Model | Owns | Does not own |
| --- | --- | --- |
| Task owner/user | Desired outcome, scope, priorities, and final product decisions | Delegating those decisions implicitly to an agent |
| Sol | Architecture contract gates when needed, material-change escalation, and final milestone review/approval | Implementation |
| Terra (`gpt-5.6-terra`) | Implementation investigation, coding, and implementation checks within the approved contract | Durable project documentation, except implementation-local comments and necessary API docs |
| Luna (`gpt-6-luna`) | Task briefs, durable documentation, and concise handoff synthesis | Inventing architecture or implementing code |

The task owner may explicitly reassign a role. State the reassignment, scope,
and duration in the task handoff. Until then, role boundaries stand. Avoid
parallel edits to the same artifact.

### Routing and gates

| Work or decision | Owner / gate |
| --- | --- |
| Architecture-sensitive change (contract, schema, API, or architecture) | Terra investigates; Sol approves the architecture contract before implementation; task owner/user decides product intent |
| Bounded implementation within an approved contract | Terra investigates, codes, and checks; Sol is not a per-phase coordinator |
| Docs-only work | Luna owns the brief and documentation, then gives a concise handoff; Sol review only if the work changes an architecture contract or is the completed milestone's final review |
| Implementation-discovered design change, safety risk, or scope expansion | Terra stops at a safe boundary and re-enters Sol; task owner/user decides product or scope questions |
| Final review | Sol reviews and approves the completed milestone, or returns bounded findings to its owner |

### 1. Task brief and investigation

**Owner:** The task owner/user sets intent and scope. Luna prepares the task
brief; Terra investigates implementation tasks, while Luna investigates
documentation tasks. Sol reviews the contract before implementation when the
task changes architecture, schema, API, or another contract.

**Entry:** A concrete outcome, target area, constraints, and known context are
available. **Exit:** The owner has listed relevant files, current behavior,
unknowns, and a bounded change proposal. No implementation begins while a
blocking design choice is unresolved.

**Handoff:** Use the investigation section of the common handoff template
below. Terra or Luna records relevant files, current behavior, unknowns, and a
bounded proposal. Route product-intent questions to the task owner/user.

### 2. Implementation or documentation

**Owner:** Terra implements code; Luna writes or updates project documentation.
Each works only within the assigned scope.

**Entry:** Any required Sol architecture gate is approved and the responsible
owner has the investigation handoff. **Exit:** The change is complete, in scope, and
its behavior or documentation can be reviewed. Report checks run and their
results; do not add or run tests unless requested.

**Handoff:** Changed paths, a concise description, relevant evidence, checks,
and open risks. Terra handles routine implementation checks. Re-enter Sol
during implementation only for a material contract change, safety risk, or
scope expansion; otherwise send the completed milestone for final review.

### 3. Review and approval

**Owner:** Sol performs the final review and approval of the completed
milestone against its approved contract. Sol reports findings with file and line references where
possible, severity, and a concrete resolution. Sol does not silently repair
the work.

**Entry:** The implementation or document and its handoff are ready. **Exit:**
Sol approves it, or returns a bounded list of findings to the same owner. The
owner addresses findings and resubmits only affected evidence; Sol checks the
resolution. Approval means the reviewed scope is ready to report as complete.

## Handoffs and escalation

Use concise handoffs at ownership changes and milestone gates. Carry forward
prior decisions and artifacts instead of repeating investigation. When work is blocked, the current owner reports
what is blocked, why, the evidence, and the smallest decision needed. Sol
routes design or quality questions to the task owner; the task owner decides
scope, priority, and any role reassignment. Security, data loss, incompatible
interfaces, or broad architectural changes are immediate escalations.

### Handoff template

```text
Task and desired outcome:
Current phase and owner:
Scope and constraints:
Relevant files and current behavior:
Decisions and assumptions:
Changes or proposed changes:
Evidence and checks (include results, or “not run”):
Open risks or blockers:
Requested next action and recipient:
```

## Cost controls

- Keep one active owner per artifact and one reviewer. Do not ask multiple
  agents to independently investigate or implement the same work.
- Pass concise findings, file paths, decisions, and evidence forward. Link or
  name existing artifacts instead of restating them.
- Inspect only files needed for the current phase. Expand scope when evidence
  shows it is necessary, and record the reason before doing so.
- Prefer targeted review of changed lines and affected behavior. Reopen earlier
  phases only when a finding changes their assumptions.
- Stop when the approved acceptance criteria are met; do not polish unrelated
  code or documentation.

## Preci sandbox architecture

The agreed evaluation and configuration flow is:

```text
build -> schema/lix -> context.data -> context.presets -> context.instructions -> modules
```

- **Build** holds the source host and user inputs.
- **Schema/Lix** validates and resolves those inputs and provides the local
  Lix functions and schema contracts.
- **`context.data`** contains normalized and resolved facts. It is the
  canonical factual input to later layers, not a place for target-specific
  directives.
- **`context.presets`** derives dependency and tool bundles from intersections
  of facts, capabilities, and functionalities. A preset is a reusable result
  of those inputs, not another source of raw facts.
- **`context.instructions`** contains target-specific directives nested under
  `core` and `home`. These directives tell each target how to use the resolved
  data and presets.
- **Modules** are the configuration. They consume instructions and configure
  the system; they are instructed rather than inferring intent from facts or
  independently selecting presets.

Keep the existing Preci-local Lix, schema, and context style authoritative.
Inspect its neighboring files before choosing names or composition. Avoid
inline builtins or library calls when the codebase inherits the needed
functions. Preserve attrset-oriented naming and composition; avoid camelCase
or PascalCase where the local style prefers nested attrsets. Do not introduce
abstractions beyond what the current phase needs.

## Preci sandbox implementation plan

Terra owns code investigation, implementation, and checks within each approved
contract. Sol gates architecture-sensitive contracts before their
implementation and gives final review at the completed milestone. Luna owns
task briefs, durable documentation, and concise handoff synthesis.

1. **Preserve existing style — initial Sol architecture gate.** Read the Preci
   build, schema, Lix functions, and current `context/common` files. Record
   current behavior and boundaries. Sol approves the initial architecture
   contract before implementation. Make no structural redesign until understood.
2. **Rename and migrate `common` to `data` — Terra owns investigation,
   implementation, and checks.** Under that approved contract, move the
   existing resolved facts into `context/data`, update imports and callers, and
   preserve behavior. Compare the old and new outputs or evaluation paths
   before advancing. There is no Sol gate for this behavior-preserving
   migration; it receives only the final milestone review.
3. **Establish preset contracts — Sol architecture gate before implementation.** Define the input facts, capabilities, and
   functionalities each preset consumes and the dependency/tool bundle it
   yields. Sol reviews and approves this contract before implementation. Keep derivation in presets and factual normalization in data.
4. **Establish `instructions/core` and `instructions/home` — Sol architecture gate before implementation.** Add
   target-specific directives under these two branches. Make dependencies on
   data and presets explicit and keep intent out of the modules. Sol reviews
   and approves this instructions contract before implementation.
5. **Adapt modules — final Sol review.** Update core and home modules to consume the instructions
   they are given. Remove any module-side intent inference only where the new
   instruction contract covers it, and preserve unrelated behavior.

At each handoff, report changed paths, behavior evidence, checks, and open
questions using the template. Do not begin a later step with an unresolved
contract or behavior regression. After module adaptation, Sol performs the
final milestone review and approval.
