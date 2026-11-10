# Hermes Profiles And Kanban

Hermes is supplied by `lix.toolkit.packages.hermes`. Configuration renderers live
under `lix.toolkit.hermes`, loaded from the same resolved toolkit source. The
toolkit owns input resolution; the Hermes modules extend that contract without
accessing flake inputs directly. `flake.lock` pins the upstream revision.

The Hermes source follows upstream's default branch. `release.json` saves the
latest stable Git tag because upstream's Nix package defaults to `0.0.0`.
The package combines that label with `+unstable.<source commit>`. Evaluation
reads this tracked file rather than a mutable release API response.
`xin --update` (or `nfu`) refreshes all inputs and the saved release metadata;
`xin --update hermes` targets Hermes. Commit `release.json` with `flake.lock`,
then use `nhs` to rebuild and restart Hermes. Direct `nix flake update` changes
source inputs without refreshing the saved release label.

Our options group state and files under `home.path` and `home.file`, authentication
under `auth.file` and `auth.overwrite`, and extensions under `extra`. Environment
variables and runtime secret files use `environment.variables` and
`environment.files`; a complete YAML configuration can be supplied with
`config.file`. Backend
arguments use `backend.extra.args`. Restart behaviour uses `restart.when` and
`restart.seconds`, defaulting to `"always"` and `5`. The output adapter translates these names to
the upstream Hermes interface. Profiles use the same `home.file`, `auth` and
`extra.plugins` names within their own declarations.

The toolkit source prepares Hermes with its messaging dependency group.
`hermesProfile NAME ...` selects a profile; `hermesProfiles ...` manages profiles.
`lix.toolkit.hermes.forConfig` supplies the effective package and aliases for a
configured service, including custom dependencies. Bot launchers use its
`binaries.hermesProfile` command.

The service uses the toolkit package by default. The CLI follows the service's
effective package so its Python dependencies and plugins remain available in
both. The root `enable` controls the service and CLI, and `package` selects their
shared base package. `desktop.enable` and `desktop.package` configure the desktop
application independently.

## Defaults

The parent calls `mkConfig` once. Core configuration and its option defaults live in `default.nix`. The core
baseline is derived from those declarations; each feature returns its own `defaults`, `options`,
`resolutions` and `outputs` for that call. The report helper has no configurable
inputs and contributes only its package output. All contributions share the
Hermes context and its root enable gate.

`_.defaults.ai.agents.hermes-agent` exports the neutral baseline. Every baseline
value has a matching declared option default. The baseline has no named team,
model preference or credential files, and Kanban dispatch is disabled. Built-in
memory and user memory remain enabled with `memory.provider = ""`.
The baseline paths are `home.path = ".hermes"` and `workingDirectory = "."`;
environment-derived resolutions anchor the configured projects stem to
`config.home.homeDirectory` and append `hermes`. The working directory follows
the effective `home.path` unless explicitly overridden. The toolkit supplies the baseline package.

`_.resolved.ai.agents.hermes-agent.defined` holds typed effective inputs.
`derived` holds the emitted Home Manager outputs, which also enter `_.outputs`.
The Home contract calculates `_.updates` automatically. Schema preferences,
computed enablement and environment-derived paths are real differences from the
baseline; an empty, unchanged profile roster contributes no profile update.

`lix.schema.hermes.mkHermes` resolves `user.ai.hermes` over `host.ai.hermes`
(or `host.defaults.ai.hermes`) over the feature defaults and computed fallbacks.
Nonempty records merge by key, lists replace lists, and explicit `false`, `null`,
empty lists and empty option attrsets are retained. An absent settings record is
an empty sparse overlay. Records can be plain attrsets or functions accepting
`lix` and `homeDirectory`, so environment discovery stays outside the baseline.
Preference resolutions use module priority 1000; explicit definitions under the existing
`defined` namespace can override them while preserving sibling defaults.
Generated gateway and Kanban settings use priority 90 to preserve the existing
precedence of typed controls over conflicting raw `settings` keys.

Craig's setup uses root Hermes Gateway and nine named role profiles ported from
TheOracle, in `~/Projects/hermes`. See `API/nix/ai/bots/README.md`
for the port's ownership, model choices and runtime integration limits.
The CLI, Desktop and service share `home.path`. This is a module fallback,
not a fixed user setting. Projects stems come from the central paths contract,
with user overrides over host overrides. `host.ai.hermes.home.path` and
`user.ai.hermes.home.path` can select a different Hermes home directly; user
preferences take precedence. For example:

```nix
ai.hermes.home.path = "/srv/hermes";
# Or relocate all projects through the existing paths contract:
paths.stems.home.projects = ["Work"];
```

Bot definitions receive `homePath` from the effective typed `home.path`, so their
file and credential references follow overrides too. The old `~/.hermes` is retained
until the replacement has passed live checks; no old profiles, credentials,
skills or endpoint settings are imported. Authentication must be established
for the new home. Automatic Kanban dispatch is disabled; gateway multiplexing is enabled.

Central bot definitions live in `API/nix/ai/bots/<name>/default.nix`.
Host/user selection supplies an explicit `enabled` list and optional `definitions`
overrides to the API bot catalog.
The selected `default` entry (`receptionist` in Craig's configuration) configures the root agent; other enabled entries configure
named profiles and receive `bot.enable = true` unless overridden. Disabled
entries are not loaded. No installed runtime roster is automatically adopted.
Each definition is a function accepting `lix`, `homeDirectory` and `homePath`.
Use the existing Hermes option shape for model, files and credentials:

```nix
{lix, ...}: let
  inherit (lix.filesystem.access) readFile;
in {
  description = "Research questions and report sources.";
  settings.model = {
    provider = "openai-codex";
    default = "gpt-6-luna";
  };
  home.file = {
    "SOUL.md" = readFile ./SOUL.md;
    "skills/research/SKILL.md" = readFile ./skills/research/SKILL.md;
  };
}
```

The owner adds its name to `enabled` to activate a catalog bot. Additional
definitions can be supplied explicitly. Bot-local `skills/` trees are installed
recursively, including supporting files; `home.file` can override individual
files. Keep credentials in runtime files referenced through
`auth.file` or `environment.files`; do not embed secrets in Nix. Named bots do
not inherit the root agent's credentials. Root Hermes uses `gpt-6-luna` with
provider-managed endpoint resolution and its own adjacent `SOUL.md`.

Profile-name rules live in `lix.schema.hermes`; the compiled validator is
provided by `lix.toolkit.hermes.validator`. The parent passes both to `bots/`.

The module is split into folders:

| Folder | Responsibility |
| --- | --- |
| `bots/` | Team roster, typed profile declarations, terse output option, writable configuration activation, Desktop Bot metadata and persistent Bot Chat launchers |
| `connection/` | Shared gateway multiplexing and routes using native Hermes keys |
| `kanban/` | Kanban dispatcher, worker selection, planning model and concurrency |
| `report/` | Team report helper that checks declared profiles against the runtime roster |


## Shared Skills And Rules

Reusable sources live in `API/nix/ai`, consumed by both Codex
and Hermes. Craig's root bot enables `shared.skills.enable` and
`shared.rules.enable`; the module defaults leave both disabled for other bots.
See [the shared catalog](../../../../../../API/nix/ai/README.md) for source ownership,
curated selection and the differences between native command enforcement and
instruction guidance. Profiles and gateway identity remain agent-specific.

## Scheduled Primary Routing

The Nix package adapter installs an opt-in selector into the built Python runtime.
Intern, Scribe and Developer select DeepSeek Flash off-peak; Architect selects
DeepSeek V4 Pro. Their normal routes remain Codex; Developer normally uses Sol
with medium effort, and root Hermes uses Luna with medium effort. Other profiles
are not opted in. API/nix/ai/routing owns the schedule and calendar constructor.

The selector checks before each request and uses the native binder rather than
reusing a client from another provider. Unknown policy/calendar or unavailable
credentials selects the safe Codex route. Calendar coverage currently ends on
2026-12-31. See API/nix/ai/routing/README.md for update and verification steps.
No runtime files are patched manually.

## Terse Output

`terse.level` is a per-profile option: `"off"` (default), `"lite"` or `"full"`.
Activation prepends the matching directive to the profile's `SOUL.md`, so it sits
at the stable top of the prompt. It reduces output tokens only. Leave it off for
profiles whose reasoning or findings must stay unambiguous, such as the planner
and reviewer. Existing sessions keep their history, so test with a new chat.

## Declare A Team

Add a declaration to a Home Manager module imported for the user when you
need an explicit override. Alternatively, supply the same values through
`ai.hermes` in a user or host schema record. Hermes must also be selected through the user
package API. Declaring profiles does not select Ollama or download models;
configure the host's Ollama module separately when using a local model.

```nix
{
  _.resolved.ai.agents.hermes-agent.defined = {
    profiles = {
      receptionist = {
        description = "Collect requirements and hand work to the planner.";
        bot = {
          enable = true;
          title = "Receptionist";
        };
        settings.model = {
          provider = "openai-codex";
          default = "gpt-6-luna";
        };
        terse.level = "full";
        home.file."SOUL.md" = ''
          Keep replies brief. Clarify the request and record a task for the planner.
        '';
      };

      planner = {
        description = "Plan tasks and coordinate specialists.";
        bot.enable = true;
        settings.model = {
          provider = "openai-codex";
          default = "gpt-6.1-sol";
        };
      };

      reviewer = {
        description = "Review completed work and report concrete findings.";
        bot.enable = true;
        settings.model = {
          provider = "openai-codex";
          default = "gpt-6.1-sol";
        };
      };
    };

    gateway.routes = [
      {
        name = "reception";
        platform = "telegram";
        profile = "receptionist";
        # Add chat_id or user_id to narrow this platform-wide route.
      }
    ];

    kanban = {
      enable = true;
      profiles = ["planner" "reviewer"];
      orchestrator = "planner";
      defaultAssignee = "planner";
      concurrency = {
        total = 1;
        perProfile = 1;
      };
      # Ownership of the root task does not select the decomposer's model.
      # This auxiliary slot selects the model that actually plans the graph.
      decomposition = {
        enable = false;
        model = {
          provider = "openai-codex";
          model = "gpt-6.1-sol";
        };
      };
    };
  };
}
```

The owner must authenticate each cloud profile before assigning work to it.
Profiles do not inherit the main profile's credential files. For API keys or a
separate messaging bot, set that profile's `environment.files` to runtime string
paths, such as `"/run/secrets/hermes-planner.env"`. Use `auth.file` and
`auth.overwrite` for explicit authentication provisioning. Secrets belong in those runtime files, not `settings` or documents.

Typed gateway and Kanban settings take precedence over matching keys in
`settings`; unrelated raw upstream settings are retained. Upstream service
options such as `package`, `environment.files`, `backend` and `extra.dependencyGroups`
are declared directly alongside `profiles`, `gateway` and `kanban`. `gateway.enable`
controls the messaging service; `gateway.multiplex` and `gateway.routes` extend its
behaviour. Desktop configuration is exposed directly under `desktop`.
Gateway routes and multiplexing are emitted as the canonical top-level
`profile_routes` and `multiplex_profiles` keys. Hermes gives those keys precedence
over their nested `gateway` spellings in existing runtime files.

## Runtime Behaviour

With no profile declarations and Kanban dispatch disabled, these folders add no
profiles or routing settings. Declared profiles make gateway multiplexing default
to enabled. Hermes enumerates existing runtime profiles too; Kanban's explicit
worker list controls which profiles its dispatcher can claim tasks for.
Disabling these module contributions leaves existing runtime settings alone;
it does not undo a previous Hermes gateway migration or stop existing tasks.

Each enabled profile gets a writable `config.yaml`, `profile.yaml` and managed
marker under `home.path/profiles/<name>`. Activation uses
the same upstream renderers as the main profile, preserving undeclared runtime
settings. Merging is per key and never deletes: removing a key from Nix leaves
the old value in the runtime file until you delete it by hand. Activation also
provisions declared documents, plugins and secret files.
Session databases, learned memory and task data are never supplied as Nix files.
Documents in a tool workspace require an explicit `workingDirectory`.
Profiles use the main Hermes package and Python dependencies. Supply any plugin
dependencies through the main service's upstream package options.

On Linux, profile activation runs before Home Manager reloads systemd services.
The gateway unit tracks declared team changes so Home Manager can restart it
after writing the updated configuration. Runtime secret contents are not part of
that trigger; rotate and restart those credentials through their secret manager.
A package bump alone does not restart the unit either, so restart it after
rebuilding when the Hermes revision changes.

An enabled Bot gets a `hermes-bot-<name>` command. Opening that command creates or
resumes its canonical **Bot Chat** through Hermes, which enables the Bot Mode
messaging protocol. Desktop can initialise the chat when the Bot is opened too.
Activation itself starts no agent turn, creates no tasks and makes no model calls.
Bot Mode metadata alone does not create a session database.

Removing a profile declaration or setting `enable = false` stops managing its
files; its existing runtime profile, conversations and memory remain on disk.
Hermes can still discover that directory. Archive or remove it through Hermes
when it should leave the runtime roster. Setting `bot.enable = false` on an
enabled profile clears its Bot metadata on the next activation.

Kanban dispatch defaults to one worker across the host and one per profile.
`kanban.profiles = []` pauses new claims explicitly. With the default worker list,
the main `default` profile and all enabled declarations can receive tasks. An
explicit worker list must include the selected orchestration and fallback
assignees. These limits govern Kanban workers; interactive chats, Bot DMs and
other inference requests need their own runtime limits.

Automatic decomposition is off in the baseline. In this Hermes
revision, the decomposer sees every installed profile; `dispatch_profiles` only
limits which assignments the dispatcher claims. An automatic plan can therefore
assign work outside the worker list and leave it waiting. Use explicit task
assignments for a restricted team until that upstream boundary is addressed.
The auxiliary decomposer also uses the gateway profile's credentials; assigning
the root task to `planner` does not load the planner profile's credentials.

The owner can create task graphs with Hermes Kanban after deployment:

```sh
hermes kanban swarm "Review the proposed change" \
  --workers planner --verifier reviewer --synthesizer planner
```

## Check The Modules

From the repository root, evaluate the isolated configuration checks:

```sh
nix eval --json --impure --expr '
  let flake = builtins.getFlake ("path:" + toString ./.);
  in import ./Tests/nix/hermes { inherit flake; }
'
```

Every returned value should be `true`. The checks evaluate sample teams and
invalid declarations without activating profiles, starting services or calling
model providers. Deployment and live message delivery require separate checks.

The runtime contract checks feed that fixture into the flake-selected Hermes
gateway loader, dispatcher parsers and Bot metadata readers. They use temporary
homes and forbid Python network connections. When the flake's Python environment
is already available in the store, run:

```sh
nix eval --json --impure --expr '
  let flake = builtins.getFlake ("path:" + toString ./.);
  in import ./Tests/nix/hermes { inherit flake; exportFixture = true; }
' > /tmp/hermes-settings-contract.json

hermes_check_source=$(jq -r '.source' /tmp/hermes-settings-contract.json)
hermes_check_python=$(jq -r '.python' /tmp/hermes-settings-contract.json)
"$hermes_check_python/bin/python3" Tests/nix/hermes/runtime.py \
  --source "$hermes_check_source" --fixture /tmp/hermes-settings-contract.json
```

These checks also record the upstream planner/dispatcher roster mismatch, so a
passing suite does not claim automatic planning is restricted to the worker list.

## CCKI knowledge management

The `knowledge` feature packages the upstream CCKI command at revision
`b64cb6448bb5b0a71e16d89860f14b554ac988bb`, including its runtime dependencies. Only `run.sh` and the knowledge skill are
snapshotted in dotfiles; the private repository needs authenticated access and
cannot be fetched by an unauthenticated Nix builder.
Craole enables it through `API/nix/users/craole/ai/default.nix`. Host/user
`ai.hermes.knowledge` selections can override `enable`, `root`, and `repository`.
The root defaults to a `ccki` checkout beside the effective Hermes home, using
the existing projects path contract. The command, shared knowledge skill, gateway
environment, and named-profile environments use that root. Profile tool
restrictions still apply; installing a command does not authorise filing.

Craole selects the existing checkout at `~/Projects/craole-cc/ccki`. After
activating the Home Manager generation, the owner runs `ccki-setup` to validate
that checkout or clone `https://github.com/craole-cc/ccki.git` if missing. Existing
directories must be Git roots with the configured origin; mismatches are refused.
For GitHub HTTPS, setup uses the existing `gh` login and configures a credential
helper in that repository only, so later CCKI pushes use it too. Git identity and
`gh auth status` must already work. No checkout or knowledge data is fetched
during activation or copied into the Nix store. The immutable command is pinned;
the writable checkout follows its own Git history and contains the live rulebook.
The copied knowledge skill matches the command revision. CCKI augments the
Hermes dependency list at its baseline priority, preserving desktop tools.

Verify `ccki rules`, `ccki index --full`, and a known-page `ccki read SLUG`
before commissioning Librarian work. Read the live shared profile policy too;
legacy Receptionist references in knowledge records need owner-reviewed
reconciliation with the local Hermes policy before coordinated work. Durable
mutations automatically commit and push all changes in this dedicated repository.
Keep unrelated work and secrets out of the checkout. A failed push is incomplete;
retain the local commit and retry `ccki sync`, without repeating the page update.

Hash-checked filing, logging, reindexing, quarantine deletion, explicit-revision
restore and sync retain upstream behaviour. Raw-page creation and concept-folder
lookup/indexing remain unsupported. The dashboard, inbox drop service and ingest
workers are separate port work; this feature does not start them. Activation,
live GitHub publication from CCKI, and a real Hermes filing session require
verification after the owner activates the generation.

## Reuse the legacy Telegram bot

Craole's gateway selects `gateway.telegram.source = "${homeDirectory}/.hermes/.env"`.
At the next owner-run `nhs`, activation extracts only `TELEGRAM_` variables into
`${home.path}/telegram.env` with mode 0600, before Hermes merges runtime
environment files. The token, user allowlist and home-channel settings stay out
of Nix values and the store; the legacy file is unchanged. Missing token or
allowed users, or unrestricted Telegram access, refuses preparation. Existing
provider credential sources remain configured separately.

Only the root gateway receives this Telegram credential file. Named profiles
share that receiving bot through the existing multiplexed gateway; they do not
start independent pollers with the same token. Native profile routing remains
available. This does not install the legacy contributor broker or Telegram
return transport. The legacy gateway must stay stopped while this gateway owns
the bot. Configuration preparation does not stop, start or restart services;
Home Manager may restart the gateway when the owner later runs `nhs`.

After activation, the owner verifies a reply in the existing Telegram chat and
checks the available profile commands before relying on multi-profile delivery.
No Telegram API call or live message exchange was performed during this change.

## Named-team handoff from Telegram

Craole enables `handoff.enable`. The pinned Hermes Python source is patched at
the existing Bot Mode tool and prompt gates; it reuses native `message_agent`,
local canonical Bot Chat delivery, process tracking, cancellation, and completion
handling. Telegram remains its original gateway session, not a renamed Bot Chat.
The agent's actual platform and session-database home establish access, never
origin JSON or role names supplied in message text.

The root runtime `team-handoff.json` contract is written even when disabled, so
a later activation revokes the gateway extension instead of leaving a stale
enabled file. The enabled contract permits exactly one local recipient
per call. Telegram root/default Hermes may contact Coordinator only. Coordinator
may commission domain owners, Architect, Auditor, Scribe and Intern. Domain
owners may commission Scribe and Intern. Architect, Auditor and contributors
return results through the native final-response transport without initiating
further commissions. Only enabled configured profiles appear in these routes.
Peer gateways, remote Desktop connections and generic fan-out are excluded by
this team policy. Hermes and specialists keep delegation disabled. Coordinator
alone receives the pinned Advanced Delegation plugin and the profile_routes
backend, whose allowlist and descriptions come from the enabled bot catalog.
Intern is the fallback for tasks without a profile. Coordinator uses subagents
for bounded supporting work; responsible-owner commissions and review packages
continue through message_agent. These are separate execution paths and must not
duplicate the same commission. Automatic Kanban dispatch stays disabled.

CCKI remains the shared curated knowledge system. Memory Wiki is not declared
by this configuration. Its optional session-history interface does not replace
CCKI or provide agent knowledge tools. The plugin declaration installs Advanced
Delegation only in Coordinator's profile; the default profile explicitly disables
it. Activation writes the plugin link and configuration; restart sessions after
the owner runs nhs before relying on the new delegation schema.
The policy enforces named routing, not the semantic scope of a work assignment;
role instructions and repository approvals still govern what a worker may do.

Hermes gets a queued acknowledgement with delivery/process IDs, then receives
the native completion in the originating Telegram session. Commissioned owners
use the poll return path for their own nested calls, including when Desktop is
open, so they can collect specialist outcomes before returning the package.
They must use process wait/log as instructed by the acknowledgement. A dispatch
is never a completed audit. Approval requirements remain active; a worker that
cannot obtain approval reports that blocker rather than bypassing the gate.
Delivery failures and ambiguous outcomes retain native semantics: inspect them
before retrying. This transport is not an unattended durable Kanban worker queue,
and a restart during delivery can interrupt it.

After the owner runs `nhs`, first use `/new` in Telegram and send this bounded
acceptance request before commissioning application work:

```text
Verify the named-team round trip. Ask Coordinator to commission Auditor to
return the literal phrase TEAM-HANDOFF-OK and its profile identity. No file
writes, repository inspection, implementation, external messages, or other
work. Coordinator must collect Auditor's result before returning it. Hermes
should return that attributed result and the observed dispatch IDs here.
```

Acceptance requires actual Coordinator and Auditor delivery receipts, Auditor's
returned result, and its return to the originating Telegram chat. This change
builds and tests the runtime offline using temporary homes and stubbed delivery
endpoints, including native local-process completion persistence. It does not
claim a live provider/Telegram round trip, start the Lignum assignment, or restart
services. The owner performs activation and the bounded live acceptance above.

### Bounded multi-stage exchanges

`handoff.limits.hops` defaults to 16. When handoff is enabled, root and every
managed named profile receive `gateway.bot_loop_guard` with `enabled = true`,
that `max_hops`, and `bot_replies_expect_reply = false`. A root-only setting is
insufficient: each worker reads its own config. This permits the nested
Developer-to-Scribe stage and leaves headroom for review/correction exchanges
while retaining a finite bound, duplicate-send checks and reply-loop protection.
A hop measures bot exchange activity, not simply the number of named profiles.
Do not disable the guard or automatically reset a chain to evade its budget.

Nested team delivery requests polling deliberately. The terminal launcher may
omit `notify_on_complete` when false; the adapter uses the explicit team policy
as well as the result field to select polling, avoiding a false promise of a
notification. Root Telegram delivery still uses the native notification path.
After activation, verify the actual owning gateway and any Desktop-owned Bot
Chat runtime use the rebuilt package; rebuilding files alone does not replace
an already-running process. Reconcile saved outcomes before resuming a blocked
commission, and retry only an operation confirmed not to have been sent.
