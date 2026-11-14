# Preparation verification

## Managed-worker initialization follow-up — November 14, 2026

After the systemd PATH repair, card `t_853513ad` spawned managed workers, but both exited during agent construction. The Developer managed-worker log identifies the cause: the local scheduled-routing adapter read session_db.db_path unconditionally, while the pinned RuntimeSessionStore exposes an RPC-backed interface without db_path. The later unknown admission receipt is a consequence of that initialization crash, not evidence by itself of incorrect profile RPC routing.

The adapter now uses the database directory for direct SQLite sessions and the owner-provided effective Hermes profile home for RPC-backed managed workers. The pinned gateway explicitly sets the child HERMES_HOME for its owning profile; no home directory or environment is hardcoded by this repair. A regression test constructs the real RuntimeSessionStore in a temporary outbox, forbids owner RPC and provider networking, and verifies Developer profile selection. It reproduces the exact AttributeError on the original adapter. All 17 routing tests pass with the correction. Existing direct-session home coverage remains intact.

This change is packaged by the existing declarative Nix source-copy mechanism. It is not active until owner rebuild. No live card, admission, session or service was changed. Activation and a successful Developer/reviewer run remain required before claiming end-to-end Kanban readiness.

## Live worker launch follow-up — November 14, 2026

After rebuild, live configuration enabled dispatch and the declared roster; installed documentation contained actual Markdown. The first Lignum commission, `t_853513ad`, reached a native claim but failed before a worker started because the restart-safe scope probe could not find a usable systemd-run.

Inspection of the installed user service found no systemd-run on its explicitly constructed PATH, while the interactive shell resolved it through the system profile. The pinned upstream probe calls shutil.which before testing the bus, so a shell-only success does not establish service availability. No bus or linger change is justified by this evidence.

The home module now appends pkgs.systemd to the effective service extraPackages on Linux, including when user-selected extras replace the desktop defaults. Upstream derives the gateway PATH from that package list. A regression check inspects the rendered production and custom-extra service environments for the systemd bin directory. This is a declarative dependency repair; no live service, environment file, card or dispatcher was modified. Full evaluation and owner activation with nhs remain required for this follow-up. The existing card must retain its identity; do not commission a duplicate.

## Local repair — November 14, 2026

The owner authorised implementation and local verification, with publication and system activation reserved for a separate step.

- Fixed shared directory skill installation: nested source-path strings were written literally into installed files. The initial text-reading correction failed full evaluation on a curated PNG asset. The corrected module preserves Nix path values so the upstream installer copies both text and binary files. Inline skills and explicit overrides retain their existing interfaces.
- Enabled the declared six-profile Kanban team in the user API and removed raw paused-dispatch overrides. The typed module derives Coordinator orchestration, Developer fallback, concurrency one and disabled decomposition. Existing independent review, eight-run/two-correction budgets and passive completion subscriptions remain enabled.
- Removed the obsolete permanent-pause instruction. Receptionist can commission a native Coordinator card from CLI, Desktop or Telegram without depending on named-bot messaging; live transport availability remains a separate check.
- Strengthened the Nix suite to inspect documentation and curated skill contents and the enabled bounded-dispatch configuration.
- Five isolated shared-module checks passed. Running the content checks against the original module reproduced four failures (documentation, nested reference, provenance and curated content), while inline text remained intact. Six isolated API/dispatcher checks passed, including assertions. These checks use minimal dependencies, not the complete Home Manager module graph.
- After the owner reported the PNG evaluation failure, seven revised isolated shared-module checks passed with the real curated skill directory, including its binary asset and copyable path type. Regression checks now read only known text files and separately verify the PNG remains a path. The previous five-check text-only fixture did not cover binary assets.
- The next full evaluation exposed dependency context on generated store-directory strings. Conversion now discards that string context before constructing a Nix path; the upstream copy derivation tracks the resulting source path. Seven isolated module checks passed again using context-bearing source strings (with filesystem reads isolated from daemon realization). A direct conversion check also confirmed that a context-bearing PNG source becomes an existing Nix path. Full Home Manager evaluation still requires the owner's daemon-enabled session.
- The owner's subsequent full evaluation completed: documentation, curated contents, binary assets and bounded dispatch passed. Three checks returned false: baseline, schemaEmptySelections and coordinatorDelegation. The Coordinator expectation was stale relative to the existing process-tooling change; it now checks the declared four toolsets on CLI, Telegram and API. Disabled handoff configuration was leaving an empty gateway settings entry; the condition now wraps the entire settings contribution. Two real Nix module-system checks confirm that disabled handoff contributes no settings and enabled handoff retains its guard. All 15 offline handoff tests passed again. Full-suite confirmation of these last changes remains pending.
- The owner reran the full suite after those corrections: every reported check is true. Read-only Lignum inspection found the current checkout at `8f64fc4` on main, one commit behind its existing origin/main reference, with unrelated uncommitted work. The queued attendance cards reference the removed views crate and older revisions. The three existing commissions should be blocked pending reconciliation before dispatch activation; they have not been modified or declared complete by this repair.
- Existing offline tests passed: 12 bounded-workflow, 15 named-team handoff and 16 scheduled-routing tests. No provider requests were made.
- Alejandra checks and diff whitespace checks passed. Full Nix evaluation could not run: the session cannot connect to the Nix daemon socket; direct local-store access is also denied. Full suite and host evaluation remain required before activation.
- Read-only live inspection found dispatch disabled, an empty dispatch roster and three ready default-board cards (`t_6dc183d6`, `t_8eb4ec53`, `t_7d30a068`). No additional board databases were found under the root's board directory. No live configuration, card, session or service was changed. Reconcile those cards and inspect all boards again before activation.

The November 10 results below describe the earlier prepared generation and are retained as historical evidence.

November 10, 2026. Approved preparation phases implemented; activation, real board creation, paid acceptance and normal dispatch remain pending.

## Results

- Sealed Hermes environment built successfully with exact patches against the pinned source. Final tested environment: /nix/store/z4k8c8w5f7q6j0bbc6c4rwamywgcvgp9-hermes-agent-env.
- 12 isolated bounded-workflow tests passed: actual catalog filtering, essential skill preservation, read-only Architect toolset, native atomic claims, lifetime run admission, correction/goal limits, independent completion rejection and acceptance, support evidence exemption, original-implementer correction routing, passive notification selection, preview-first idempotent empty-board preparation and startup fallback filtering.
- 16 schedule/fallback tests passed, including UTC boundaries, holidays/calendar expiry, malformed policy, unavailable binding, disabled schedule and startup fallback crossing into peak.
- Installed runtime hook/native binder check passed with network forbidden.
- Hermes Nix suite: 98 of 100 checks passed. baseline and schemaEmptySelections remain the two pre-existing failures previously observed on unchanged HEAD; they are not hidden or treated as passing.
- Victus configuration evaluation succeeded. Effective root home is /home/craole/Projects/hermes; dispatch false, active worker list empty, concurrency one, no automatic decomposition, failure limit two, lifetime run limit eight, correction limit two, independent review gate for Developer/Architect/Scribe, passive notification delivery. Intern/Scribe configured safe model is Codex Luna; their primary schedule selects Flash off-peak. Architect CLI toolsets are repository_read/skills/kanban.
- Nix formatting and diff whitespace checks passed. The source patch was also applied to an isolated pinned-source fixture and compiled before its runtime build.
- All 226 session IDs from the earlier backup are still present. The live gateway task database remains empty. No live board was created, no task commissioned, no activation or paid provider call run.

## Limits

Offline tests do not prove that a model follows a task contract, produces a usable plan, or successfully delivers through Desktop/Telegram. The native state machine remains responsible for attachments, dependencies, notification cursors and recovery; the small adapter adds skill filtering, fallback windows, toolset definition and execution/acceptance gates. Restart and final-delivery acceptance still require the proposed bounded live exercise.

The read-only usage report uses worker_session_id in native run metadata. Missing data remains null; shared sessions must not be double-counted. It is not a complete per-request bill or Plus allowance monitor. There is no claim of a measured efficiency improvement yet.

## Next gate

The owner reviews the runbook and published diff. After approval, the owner runs nhs to activate the paused configuration; fresh session/board backups and ID checks precede activation. Empty acceptance-board creation and the exact live commission require approval. Dispatch enablement is a separate small reviewed change after confirming that other boards cannot accidentally run. Do not delete/reset existing chats or restore an older database over newer work.
