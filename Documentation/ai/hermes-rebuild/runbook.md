# Bounded Hermes acceptance runbook

Status: prepared, dispatch off. The owner approves activation and the exact paid acceptance commission separately. No existing chat is reset, deleted or migrated.

## Prepared capability matrix

| Role | Skills | Tools | Run ceiling |
| --- | --- | --- | ---: |
| Receptionist | Hermes docs and concise writing | File, terminal, skills, Kanban | 12 |
| Coordinator | Task contracts and common conventions | Read-only repository, skills, Kanban | 12 |
| Intern | Evidence, inventory and attribution | File, terminal, skills, Kanban | 30 |
| Scribe | Implementation and applicable checks | File, terminal, skills, Kanban | 60 |
| Developer | Investigation, integration and validation | File, terminal, skills, Kanban | 60 |
| Architect | Planning, architecture and attribution | Read-only repository, skills, Kanban | 30 |
| Auditor | Independent SDLC review and evidence | File, terminal, skills, Kanban | 30 |

These are tool surfaces, not OS filesystem sandboxes. Relevant task contracts still constrain writes and commands. Shared/project skill names can shadow one another; allowlists constrain names, not the trustworthiness of replacement contents. Direct histories stay available. Unrelated personal roles and cron ownership remain unchanged.

Managed role plugins explicitly disable Advanced Delegation, disk-cleanup and memory-wiki without uninstalling or deleting plugin data. This removes their automatic participation on the prepared engineering path. No claim is made about unrelated plugin hooks outside these roles.

## Routing

Receptionist/Coordinator use Flash for bounded control at all hours. Intern/Scribe restore scheduled Flash off-peak / Codex Luna peak. Developer keeps Flash/Codex Sol; Architect keeps DeepSeek Pro/Codex Sol. Auditor stays Codex. Specialist Flash fallback is accepted only by the existing UTC calendar, including its holiday exceptions. During peak or unknown coverage, an unavailable primary stops or defers work. There is no unconditional Flash fallback.

## Limits and delivery

Dispatch is explicitly false and its active allowlist empty. The intended worker roster is Coordinator, Developer, Architect, Scribe, Intern and Auditor, with concurrency one. Automatic decomposition and goal-judge loops are disabled. Native consecutive-failure limit is two. The atomic claim guard also blocks a task after eight lifetime runs or a third correction request; reopening does not erase the history. Two correction passes and a final review fit within this budget, assuming no additional failures. Higher per-task retry settings do not defeat the lifetime cap. No hard dollar or Plus allowance cap is claimed.

Developer/Architect/Scribe deliverables cannot complete without an independent same-card reviewer run. Bounded Intern evidence and Coordinator control cards do not force an extra review. A native owner worker requests same-card review with the full plan or an attached artifact plus checks. Request-changes returns to the recorded implementer. Architect's full textual plan is stored as the durable review summary; it cannot write a separate file. An authorised author may export it when a file is needed. Review tools, attachments, dependency and restart semantics remain native.

Root auto-subscribes the origin to outcomes. Telegram subscriptions use passive notify delivery, avoiding a paid wake/relay. TUI keeps its native mode. Passive delivery carries the worker's summary, so that summary must be the actual deliverable or artifact reference. Desktop visibility and Telegram attachment delivery require live acceptance; neither is established by a unit test. Native notification semantics are not exactly-once delivery.

## Before activation

1. Review the final diff and check report. Save fresh SQLite-consistent backups of both Hermes homes and board state, and record session IDs. Preserve the current chats and model overrides.
2. After owner approval, run nhs. Verify root and named profile settings, active service and the session IDs. This preparation still leaves dispatch off.
3. Use the newly built Hermes environment for helper commands. Obtain its path by evaluating `pythonDrv` from Tests/nix/hermes with exportFixture=true and realising that derivation; do not use a stale venv lacking the adapter.
4. Preview board preparation by invoking kanban/prepare_acceptance.py with --home /home/craole/Projects/hermes --repo /home/craole/.dots. Only after approval add --create. This is idempotent for an existing matching board, does not change the active board selection and does not enable dispatch. A differing or archived board requires inspection.

## Exact proposed paid acceptance contract

Board: hermes-acceptance. Repository: /home/craole/.dots, read-only. Scope: analyse API/nix/ai/bots and API/nix/ai/routing only, plus directly referenced instructions. Output: a complete plan describing the role/route boundaries, evidence paths/revision, dependencies, risks and acceptance criteria; no implementation or repository writes. Assignee: Architect. Reviewer: Auditor. Single card, native same-card review, no contributing workers, no goal mode. Per-run ceilings 30; eight total runs; at most two correction passes. Use a persistent directory workspace, not disposable scratch. Record the owner-approved origin subscription and provider window before starting.

Verify automatic initial review and one bounded correction without claiming done early. If a forced correction is needed, use a clearly identified test finding; do not invent a defect in a correct plan. The owner receives the accepted plan or explicit blocker automatically. Provider failure and restart recovery use separate controlled fixtures first; do not duplicate a real commission to test recovery. Compare with a direct Flash run only after approval of that additional paid comparison.

## Enabling acceptance dispatch

Only after approval, change the user API's kanban.enable to true, remove the staged false/empty settings overrides for dispatch_in_gateway and dispatch_profiles, and let the existing typed Kanban module derive the intended roster. Do not start a second CLI dispatcher. Keep auto_decompose=false and concurrency one. Preview/evaluate that exact change, publish, activate and verify the actual dispatcher owner before promoting the acceptance card. Board selection is not an authorization boundary; other boards must be empty or paused before enabling the gateway's all-board sweep.

This enablement diff is deliberately absent from preparation. It must be reviewed with the actual card and origin before any model runs.

## Usage report

Invoke kanban/report.py with --home /home/craole/Projects/hermes --board hermes-acceptance. It opens SQLite read-only, reports runs and correction count, and uses worker_session_id metadata to retrieve local counters where available. Missing usage remains null. Reused session IDs must not be summed twice; mixed routes and auxiliary calls are not fully attributed. Provider billing and the ChatGPT allowance display remain separate evidence.

## Rollback

Pause dispatch before another task claim. Preserve the board, run rows, session databases, attachments and partial outputs. Restore the last reviewed declarative configuration or previous Nix generation, then verify service state and session IDs. Do not restore an older database over newer conversation/work merely to undo configuration. The earlier backup is recovery material, not a routine rollback command.

Owner: Codex prepares the bounded acceptance diff after the user reviews this evidence; the user authorises activation and paid execution. No action is required on current sessions.
