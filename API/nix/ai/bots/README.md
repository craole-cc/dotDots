# Hermes team

The `receptionist` catalog bot ports TheOracle's conversational gateway role.
Downstream Hermes selection maps it to root/default with runtime identity Hermes;
no named `receptionist` or `hermes` profile is created.
Nine named profiles port Coordinator, Developer, Librarian, Anthropologist,
Assistant, Architect, Scribe, Intern and Auditor. Each owns a `default.nix`
and SOUL.md plus a local AGENTS.md for operating instructions. POLICY.md holds
the team operating contract once. Named profiles compose that contract with their
local AGENTS.md; the default Hermes adapter appends both through shared.rules.instructions,
preserving the generated shared command policy. SOUL.md contains identity and
role responsibilities. A bot-local skills/ tree is discovered and installed recursively, including
scripts and references. Explicit home.file entries take precedence. Add such
a folder only for actual bot-specific skills;
reusable skills remain in the shared catalog.

Source: read-only inspection of TheOracle's `/home/craole-cc/.hermes` root and
named profile definitions. Role ownership and tool restrictions were retained;
Receptionist references were renamed Hermes. Initial models came from the inspected configuration; local model policy is now: Architect, Anthropologist, Auditor and Developer normally use gpt-6.1-sol; the
other roles normally use gpt-6-luna through openai-codex. Developer uses medium
reasoning effort and default Hermes medium effort. Intern's stale local-Qwen description
was corrected. Endpoint overrides were omitted. Scheduled routing is configured separately in
`API/nix/ai/routing`: Intern, Scribe and Developer use DeepSeek Flash off-peak;
Architect uses DeepSeek V4 Pro.

Host/user selection explicitly enables these central definitions. Multiplexing exposes named
profiles; automatic Kanban dispatch remains disabled. Each profile references
the effective root's skills and explicitly seeds its writable authentication
from the local root auth.json, without forcing later credential replacement.
No remote auth files, histories, mail records or broker state were copied.

TheOracle's contributor broker is not installed by this profile port. Restricted
native named-team handoff and return from Telegram are selected separately by
`handoff.enable`; see the Hermes module README for activation and acceptance.
CCKI is installed separately when `knowledge.enable` is selected;
see the Hermes module README for checkout setup and verification. The scheduled
selector is installed through the Nix package adapter; see ../routing/README.md. Native
handoff and return behavior must be verified before commissioning team work;
a visible profile is not evidence of a working coordinated workflow. Keep role
restrictions intact and report missing capabilities instead of impersonating
another role. The owner activates the generation, verifies each model, then
validates a bounded handoff and return before enabling automatic dispatch.

## Current technical operating model

Hermes routes coordinated work through Coordinator. Developer owns technical
guidance, interfaces, integration and validation; Scribe authors the substantive
code, tests, configuration and documentation. Intern supplies bounded evidence
and checks; Architect provides specialist planning when needed. Coordinator
routes completed packages to Auditor, who may autonomously accept them or
require scoped corrections within the owner's authorised objective. Corrections
return through the same Developer to Scribe and then through independent review.
Explicit owner-reserved approvals still stop execution. Acceptance permits only
continuation and publication already covered by the owner's authorisation.

Normal model selection remains Developer on gpt-6.1-sol and Scribe on gpt-6-luna.
The owner explicitly retains DeepSeek Flash for both during off-peak periods.
Developer requests medium effort on Flash and gpt-6.1-sol; Scribe requests low
on Flash and high on gpt-6-luna through native per-model overrides. There is no
distinct per-token model tier between them on the Flash route; effort and the
amount of assigned work control their usage. DeepSeek documents medium as a
compatibility alias for high; the configuration retains the owner-requested
medium value. See https://api-docs.deepseek.com/api/create-chat-completion/. Avoid
duplicate authorship and repeated context to control overall use. Librarian,
Anthropologist and Assistant workflows and cron ownership are deferred. Their
profiles and existing scheduled work are retained without new commissioning.
