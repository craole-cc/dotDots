# Hermes workflow audit

Read-only inspection on November 10, 2026. The repository was clean and synchronized before preparation.

## Observations

The active gateway uses Projects/hermes, while the older desktop home is .hermes. Both default task stores are empty, without additional boards. Dispatch is disabled. Current direct chats and all histories remain in place.

The catalog has 56 skills; shared external directories expose their indexes to named profiles. This is not proof that all skill bodies load. Root plugin settings contain Advanced Delegation in both enabled and disabled lists. Coordinator enables it explicitly. The pinned plugin configuration code gives the disabled list precedence; the conflicting lists do not prove that root Advanced Delegation was active. Installed directories are not proof that hooks executed.

Persistent Bot Chat session counters are Coordinator 340, Developer 416, Scribe 259 and Auditor 92 calls. These span multiple requests and routes and cannot be treated as the cost of one planning job.

## Bounded historical reconstruction

Phase-related incoming records include multiple Phase 1 corrections, Phase 2 reviews and targeted wording corrections. Developer records 1032, 1065 and 1083 show successive requests narrowing the remaining Phase 2 defects; these are evidence of review cycles, not proof that every cycle was unnecessary. Coordinator record 915 and Developer record 1104 concern a later read-only readiness reconciliation and dependent plan before implementation. Compaction and shared persistent sessions prevent reliable per-request billing attribution from these counters.

The policy requires Developer/Scribe/Coordinator relays even for planning. Native Kanban provides a durable alternative with run provenance, same-card correction routing and declared artifacts. Native failure limits do not alone cap successful review/correction loops. The rebuild must enforce aggregate admission limits independently.

## Decisions

Use one gateway-owned queue, curate role capabilities, restore Intern/Scribe peak gating, retain automatic independent review and eliminate manual review-package preparation. Keep dispatch disabled pending bounded live acceptance. Trace remaining uncertainty through task-level records going forward rather than adding another broad retrospective investigation.

Owner: Codex prepares and verifies the declarative implementation. User approval remains required for activation, board creation and paid acceptance.
