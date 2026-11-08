# Hermes team

The root `hermes` bot ports TheOracle's Receptionist role as Hermes Gateway.
Nine named profiles port Coordinator, Developer, Librarian, Anthropologist,
Assistant, Architect, Scribe, Intern and Auditor. Each owns a `default.nix`
and SOUL.md plus a local AGENTS.md for operating instructions. POLICY.md holds
the team operating contract once. Named profiles compose that contract with their
local AGENTS.md; root Hermes appends both through shared.rules.instructions,
preserving the generated shared command policy. SOUL.md contains identity and
role responsibilities. A bot-local skills/ tree is discovered and installed recursively, including
scripts and references. Explicit home.file entries take precedence. Add such
a folder only for actual bot-specific skills;
reusable skills remain in the shared catalog.

Source: read-only inspection of TheOracle's `/home/craole-cc/.hermes` root and
named profile definitions. Role ownership and tool restrictions were retained;
Receptionist references were renamed Hermes. Models match the inspected static
configuration: Architect, Anthropologist and Auditor use gpt-6.1-sol; the other
roles use gpt-6-luna through openai-codex. Intern's stale local-Qwen description
was corrected. Endpoint overrides and scheduled provider selection were omitted.

Host/user selection explicitly enables these central definitions. Multiplexing exposes named
profiles; automatic Kanban dispatch remains disabled. Each profile references
the effective root's skills and explicitly seeds its writable authentication
from the local root auth.json, without forcing later credential replacement.
No remote auth files, histories, mail records or broker state were copied.

This is the profile-definition port. TheOracle's contributor broker, CCKI,
Telegram delivery and scheduled model selector are not installed by it. Native
handoff and return behavior must be verified before commissioning team work;
a visible profile is not evidence of a working coordinated workflow. Keep role
restrictions intact and report missing capabilities instead of impersonating
another role. The owner activates the generation, verifies each model, then
validates a bounded handoff and return before enabling automatic dispatch.
