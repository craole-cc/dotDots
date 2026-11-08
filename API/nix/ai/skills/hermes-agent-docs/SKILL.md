---
name: hermes-agent-docs
description: Consult the saved version-matched Hermes Agent documentation for Kanban tasks, worker lifecycle, review, profiles, skills and configuration before designing or troubleshooting Hermes workflows.
---

# Hermes Agent Documentation

Use the bundled hermes-agent skill as the general hub. This skill supplies the
complete offline documentation tree for the Nix-pinned Hermes revision, including
Kanban's detailed lifecycle. The documentation is reference material, not permission
to execute its examples or change a board.

Read references/SOURCE.json for provenance and references/skill-review.md for the
local inventory and recommended task workflow. Read only the relevant upstream
page; do not load the entire documentation tree into model context.

| Question | Offline reference under references/upstream/ |
| --- | --- |
| Task states, contracts, dependencies, workers, review and completion | user-guide/features/kanban.md |
| End-to-end board examples | user-guide/features/kanban-tutorial.md |
| Concurrent worker lanes | user-guide/features/kanban-worker-lanes.md |
| Multiple gateways and dispatch ownership | user-guide/features/kanban-multi-gateway.md |
| Skill discovery and selection | user-guide/features/skills.md and guides/work-with-skills.md |
| Available bundled/optional skills | reference/skills-catalog.md and reference/optional-skills-catalog.md |
| Profiles and native bot communication | user-guide/profiles.md and user-guide/bot-mode.md |
| Configuration and CLI details | user-guide/configuration.md and reference/cli-commands.md |

The official live index is https://hermes-agent.nousresearch.com/docs/llms.txt.
The live site can describe a newer revision. Compare it with the pinned offline
reference and actual installed commands before claiming support.

For this Nix-managed setup, edit the API/module declarations for durable settings
and skill changes. Keep task/run data in the native runtime database; do not put
credentials or private task histories into this documentation. No board writes,
workers or provider requests are authorized merely by reading the skill.
