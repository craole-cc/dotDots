# Hermes rebuild plan

Prepared November 10, 2026. Status: proposal for owner approval; no configuration, board or routing changes made by this audit.

## Outcome

Turn one authorised request into a durable task, useful artifact, independent review when needed, and a delivered result. The owner must not relay messages, prepare review files, or manage model switches. Preserve multiple specialised models, peak-hours economics, current sessions and existing approval gates. Efficiency must be demonstrated rather than assumed.

## Verified starting state

- Repository /home/craole/.dots is clean and synchronized with origin/main.
- Active gateway home is /home/craole/Projects/hermes; the desktop also has /home/craole/.hermes. These are distinct state stores.
- Both default Kanban databases contain zero tasks; neither home has additional board databases under kanban/boards. Native task storage exists, but no operational board workflow has been configured.
- Declarative Kanban dispatch is disabled. A gateway service and two desktop scopes are active; desktop scopes alone do not establish competing dispatchers.
- The active shared catalog contains 56 SKILL.md entries. Named roles scan the root catalog through skills.external_dirs; upstream documents that external skills appear in the system prompt index. Catalog presence is not full skill-body loading or proof of excessive token cost.
- Coordinator enables Advanced Delegation. Root configuration lists advanced-delegation in both enabled and disabled lists, alongside disk-cleanup and memory-wiki in enabled. Root plugin directory contains Advanced Delegation and memory-wiki. Effective plugin loading still needs validation; installation and configuration are not proof of execution.
- Policy requires Scribe authorship under Developer, with Coordinator relaying the package for Auditor acceptance. It does not yet integrate this policy with native task ownership and same-card review.
- Recent persistent Bot Chat counters: Coordinator 340 API calls; Developer 416; Scribe 259; Auditor 92. Counters span their sessions and routes. They cannot attribute a specific failed request, prove waste, reproduce provider billing, or measure Plus allowance.
- The already activated change makes Receptionist, Coordinator, Intern and Scribe Flash-only throughout the day. This bypasses the former Intern/Scribe off-peak gate. Developer/Architect retain scheduled routes; other specialist profiles retain Codex. The pending fallback proposal was never implemented.
- Backup /home/craole/Backups/hermes-sessions/20261110-144237 contains 43 session databases and transcripts; all 226 backed-up session IDs were verified present after activation.

## Evidence and implementation boundaries

Version-matched documentation provenance is in /home/craole/.codex/skills/hermes-agent-docs/references/SOURCE.json, pinned revision 8a5a7ace84ca34e655a73f328701e1e9e1eb555c. The installed environment was also inspected at /nix/store/83yjk5kzys5cdyjihfh26k084gvqjfyx-hermes-agent-env. Resolve any discrepancy against the flake-owned source before implementation.

Native Kanban provides board isolation, atomic claims, task dependencies, managed workers, same-card review/request-changes, durable declared attachments, retry controls, notifications and restart recovery. Use these rather than inventing another queue or broker. A notifier wake can trigger a model turn; a subscription is not proof of successful model delivery. Scratch workspaces are ephemeral unless declared artifacts are attached; repository tasks must use persistent workspaces or worktrees.

No production task is commissioned during implementation or offline testing. Limited live acceptance is a separate approval gate after the reviewable implementation and activation instructions are ready.

## Proposed workflow

1. Hermes receives the objective and existing approvals. Answer trivial questions directly. For substantial work, create one durable task or use one bounded Coordinator turn to define its contract and assignee.
2. The contract records repository/revision, scope and exclusions, output path, acceptance criteria, required skills, route class, allowed spend/attempt limits, originating chat and approval state. Reuse an idempotency identity when delivery is uncertain.
3. Dispatcher launches only the assigned worker when dependencies, route policy and execution limits permit it. State transitions and waiting are handled by code, not repeated Coordinator reasoning turns.
4. Worker creates the artifact and records paths/revision, checks, limitations and unresolved decisions. It calls native request-review with attached evidence. The owner never prepares a review file.
5. Auditor reviews the same card against the identified revision. Request-changes returns it to the original implementer with precise defects. Done requires an artifact and supported acceptance evidence; a plan request produces a plan, not an unapproved implementation.
6. The originating chat receives the accepted artifact or a concrete blocker automatically. Intermediate status pings must not wake a chain of models. Test both Desktop and Telegram delivery; choose one presentation event per outcome where supported.

For code work, Developer retains technical ownership and Scribe authors the bounded change; express substantial authorship as durable supporting work only when it merits a separate worker. For analysis/planning, assign Architect or Developer to produce the plan directly, with Intern supporting a specific evidence gap only when necessary. Remove the mandatory Scribe stage for every planning request. Architect currently has file, terminal and Kanban tools disabled; either provide a narrowly scoped read-only tool setup with tested terminal outcome access, or supply a bounded evidence artifact and enable only the native task tools needed. Do not assume its current profile can inspect a repository or close a card.

Coordinator remains responsible for cross-task decisions and escalation. It does not re-investigate every artifact. Kanban replaces durable work commissions through message_agent; retain named-bot conversation for clarification and user-facing routing. Disable Advanced Delegation on the board path initially to avoid a parallel execution tree. Re-enable bounded supporting delegation only after a separate measured need.

## Model and peak policy for approval

Keep the existing calendar and schedule as the authoritative source; test UTC and Jamaica boundaries, weekends, make-up workdays and calendar expiry. Do not introduce another handwritten clock.

- Receptionist and Coordinator: Flash all day for bounded conversational/control work. This is an explicit peak-price exception with strict limits, not permission for long repository investigation.
- Intern and Scribe: restore their former scheduled policy, Flash off-peak and Codex Luna during peak. The recently introduced all-day Flash labour route is removed.
- Developer: retain Flash off-peak / Codex Sol peak.
- Architect: retain DeepSeek Pro off-peak / Codex Sol peak.
- Auditor: retain independent Codex Sol review initially, budgeted and invoked only for an identified package.
- Librarian, Anthropologist and Assistant: retain current routes; do not commission unrelated workflows or cron changes under this rebuild.
- Flash fallback for a Codex specialist is permitted only off-peak. During peak, exhausted/unavailable Codex blocks or defers the task; it does not silently buy peak Flash labour. A Flash-only control role has no redundant Flash fallback.
- Provider route changes must not increase authority, bypass an approval gate or trigger a second copy of the task. Unknown/expired calendar disallows discount-dependent Flash fallback; report the condition rather than guessing.

This policy is proposed, not activated. If preserving Plus at any price is preferred, that requires a different explicit peak policy.

## Skills, plugins and tools

Build a declarative role capability matrix. Keep the original catalog available for recovery and intentional direct chats; expose a curated catalog to managed workers. Use supported skills.disabled where sufficient or separate generated skill directories where stronger isolation is required. Check local/project shadowing and installed bundled skills so external_dirs alone is not mistaken for an allowlist.

- Common engineering conventions: sh-utils, repository plan/approval rules, writing-style; nix-style/nix-inspect only for Nix tasks; commit-messages only for publication.
- Coordinator: native Kanban lifecycle and task-contract guidance, not broad research/creative/media toolsets.
- Intern: bounded repository evidence and attribution; no delegation or unrelated integrations.
- Scribe: task-relevant implementation/document skills and proportionate checks.
- Developer: investigation, integration and validation skills; avoid redundant requirements that recreate contributor relays.
- Architect: planning and architectural evidence; deliberately limited capabilities verified against the assigned work.
- Auditor: sdlc-review and independent evidence/acceptance guidance; do not preload generic workflows that create another review commission.

Inventory effective tools, MCP servers, plugin hooks and skills per role, not merely installed manifests. Resolve enabled/disabled conflicts. Preserve memory-wiki data; remove it from managed worker paths if it adds irrelevant work after inspection. Do not uninstall unrelated user plugins globally. Do not add plugins merely because they sound useful. Native Kanban is the first implementation choice; validate its installed UI rather than assuming a new plugin is required.

## Execution limits and accounting

Initial targets: one active board worker globally and per profile; automatic fan-out/decomposition and goal-judge loops disabled. Coordinator may create a small explicit dependency graph when the request genuinely needs one; this does not require the owner to operate the board.

Proposed initial per-run API iteration ceilings: control 12, evidence/planning 30, implementation 60, review 30. These are starting limits, not measured optima. Native budget warnings must leave time to save a partial artifact and report remaining work.

At most two execution attempts before blocking and two correction rounds per package. Verify the installed meaning of max_retries/failure_limit; do not claim that a per-run turn limit bounds an entire multi-run task. If native configuration does not enforce the aggregate review/attempt guard, add a narrow tested guard at the existing task transition boundary. Do not build a second scheduler. Never reset counters by creating replacement cards.

Record task/run/profile/provider/model, call count, input/output/cache/reasoning usage where available, elapsed time, retries, review rounds, artifact revision and final state. Attribute auxiliary calls and route switches where technically observable. Mark estimates and missing data. Do not claim a dollar cap from partial counters or infer Plus allowance from API pricing.

Compare a bounded repository-analysis task against a comparable direct Flash task using the same scope and output acceptance criteria. Report useful artifact delivery, quality, calls, elapsed time and known costs; one comparison is an acceptance signal, not universal proof of superiority.

## Implementation phases and evidence gates

A. Forensic baseline: identify the exact last-night request and its deliverable in the existing session records. Read bounded request/handoff windows, attribute repeated investigations and review rounds, and report what cannot be reconstructed. Inspect effective plugin hooks and skill/tool indexes. Preserve direct-session behaviour until the capability matrix is reviewed.

B. Declarative preparation: reconcile the role policy; curate worker capabilities; implement schedule-aware fallback; add explicit budget and notification settings. Extend the existing Nix module only for missing supported controls. Keep dispatch off while preparing and evaluating.

C. Native board preparation: configure one project-scoped acceptance board in the gateway home, explicit worker allowlist and one dispatcher owner. Runtime board/task data belongs in SQLite, not Nix source. Keep the setup idempotent and do not import a backlog or infer new commissions. Verify Desktop opens that same board/home.

D. Offline verification: role settings and skill visibility; peak/calendar and credential failures; claims/dependencies; same-card review and return to original implementer; artifact preservation; retry and review bounds; notification deduplication; interrupted-run recovery. The existing baseline and schemaEmptySelections Nix checks failed on unchanged HEAD during the earlier change; recheck and report independently, without hiding new failures.

E. Reviewable publication: show final diff, capability matrix, route matrix, exact activation/rollback instructions and all check results. Commit and push the approved scope. No session reset, home migration, credential rotation or unrelated cron edits.

F. Limited live acceptance after owner approval: refresh session/board backups and integrity checks; activate; run one harmless scoped repository-analysis-and-plan card. It must produce a durable usable Markdown plan, route automatically to independent review, handle a forced correction, and deliver the final artifact without manual relaying. Test provider failure and controlled restart/recovery separately without commissioning duplicate real work. Record actual observed usage; stop at the agreed limits. Live acceptance consumes provider usage and needs explicit approval of that bounded commission.

G. Operational enablement: enable normal dispatch only after the acceptance evidence is reviewed. Keep concurrency one until there is measured benefit to widening it. A failure pauses dispatch and leaves tasks/results visible; it does not erase sessions or task history.

## Files and publication

Expected scope: API/nix/ai/bots/{POLICY.md, role AGENTS.md/SOUL.md/default.nix}, API/nix/ai/{routing,skills,plugins}, API/nix/users/craole/ai/default.nix, Modules/nix/home/ai/agents/hermes/{kanban,bots,connection}, focused Tests/nix/hermes and Tests/python checks, and a durable repository plan/report. Actual runtime adapter changes require demonstrated gaps from phase A/D, not speculative replacements.

No starting-state commit is required. Proposed separate commits: docs(hermes): define bounded native Kanban workflow; feat(hermes): scope worker capabilities and peak-aware routes; feat(hermes): configure bounded Kanban execution and delivery. Push completed checked phases; do not rewrite existing commits. A material scope or policy change returns to the owner.

## Approval boundary

Owner approval is needed for the proposed role/peak matrix, workflow changes and implementation/publication phases A-E. Board mutations, activation and paid live acceptance F are presented concretely after preparation; normal dispatch G stays disabled until acceptance. This split follows the local plan-first rule and keeps approval attached to reviewable results. No current session must be deleted, reset or migrated.
