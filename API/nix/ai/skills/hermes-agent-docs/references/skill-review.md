# Skill inventory and native Kanban direction

Observed 2026-11-08. The root Hermes home contains 52 SKILL.md entrypoints,
including the bundled hermes-agent hub, six local shared conventions and the
two selected curated GitHub skills. installed-skills.json records the full
inventory and descriptions. Presence establishes discovery, not dependency,
account, tool or model readiness. Named profiles reference the root skill tree.

## Documentation ownership

The hermes-agent hub is already installed at
skills/autonomous-ai-agents/hermes-agent/SKILL.md. Keep it as the general entry.
The hermes-agent-docs skill adds the complete website/docs tree from the exact
Hermes flake input, its MIT license and SOURCE.json provenance. No live website
content is silently treated as installed capability. The docs rebuild with the
pinned input. Official current navigation is at
https://hermes-agent.nousresearch.com/docs/llms.txt.

## Skills worth using for tasks now

| Skill | Role/use | Scope and readiness |
| --- | --- | --- |
| hermes-agent | Hermes/Coordinator: native features and configuration | Installed hub; read its matching references |
| hermes-agent-docs | Any role: version-matched offline feature reference | Added declaratively by this change |
| sdlc-review | Auditor: the native Kanban review lane | Installed; requires an actual review worker and Kanban tools |
| document-to-action-items | Hermes/Coordinator: turn supplied documents into cited task candidates | Installed; proposed tasks are not automatically authorized work |
| weekly-review-planning | Coordinator: review stalled work and propose priorities | Installed; proposals do not change the board by themselves |
| systematic-debugging | Developer: investigate root causes before corrections | Installed; use for actual defects |
| requesting-code-review | Developer: prepare a review handoff | Installed; its fix/preparation behavior does not replace an independent Auditor |
| grounded-citations | Anthropologist/Librarian: attributed findings and evidence | Installed; actual sources must be inspected |
| github and curated gh-* skills | Developer/Auditor: issues, checks, PRs and review comments | Installed; account access and repository permissions still need verification |
| spike | Developer/Architect: resolve a bounded technical uncertainty | Installed; distinguish throwaway experiment from accepted implementation |
| test-driven-development | Developer/Scribe: testable behavioral changes | Installed; apply where appropriate, not as a requirement for every trivial edit |
| plan-first, nix-style, nix-inspect, sh-utils, commit-messages, writing-style | Repository work and user conventions | Installed shared sources under API/nix/ai/skills |

codebase-inspection specifically uses pygount for quantitative inventories; it is
not a prerequisite for ordinary rg/git inspection. Obsidian is installed as a
skill but a vault is not configured by its presence. Google Workspace, email,
Apple, creative and media skills can remain available without becoming part of
the first Kanban workflow. Memory/Hindsight/vault design and any additional
key-backed decision service are deferred. No key is requested or stored here.

## Build on the native task system

Use the pinned Kanban reference and tutorial before enabling dispatch. Native
Kanban already has durable SQLite tasks, per-attempt runs, dependencies, worker
claims, persisted handoff evidence, review/change-request transitions, bounded
retries and progress events. We do not need to recreate TheOracle's custom
broker merely to store tasks and run a basic reviewed workflow.

Use the native review lane for review of the same deliverable. sdlc-review is
specifically scoped to that lane; a separate downstream review card is a
different workflow. Preserve original implementer/reviewer provenance through
corrections. A genuinely new follow-up is a dependent task; do not confuse it
with correction of an unfinished acceptance contract. Complete only after
checking the declared criteria and preserving the artifact/revision evidence.

Proposed first configuration, not activated by this documentation work:

1. One board for a bounded project, an explicit allowed-worker list and one
   dispatcher owner. Keep automatic decomposition disabled initially.
2. Coordinator owns routing and dependencies; Hermes remains the default
   conversational gateway. Use only native tools actually available in each
   execution context. Native Kanban task tools and bot messaging are different
   capabilities; verify them independently.
3. Start with one worker at a time. Give a harmless task a concrete artifact and
   acceptance criterion. Exercise review, request-changes, correction and pass.
4. Verify durable task/run state across restart, original ownership, no duplicate
   claims and delivery of an actual result to the originating conversation.
5. Exercise blocked input, provider failure and retry limits. A queued/assigned
   card is not evidence of a running worker; a completed worker is not evidence
   of user-facing delivery. Verify those return paths before unattended work.

The current role instructions came from a more elaborate ownership/contributor
workflow. Before enabling execution, reconcile those instructions with the
native card lifecycle so Developer is not forced to use an unavailable Scribe
transport, Architect's tool restrictions remain intact, and Auditor gets an
actual independently reviewable package. Skill text alone does not create tools.

## Next action

The user activates the documentation/skill update with nhs. Then review and agree
on the concrete native Kanban configuration and bounded acceptance exercise.
This change does not enable dispatch, create a board/task, commission a worker,
start a provider request or configure memory. No additional runtime action is
required to retain this reference in the repository and Nix generation.
