# Hermes Profiles And Kanban

Hermes is supplied by `lix.toolkit.packages.hermes`. Configuration renderers live
under `lix.toolkit.hermes`, loaded from the same resolved toolkit source. The
toolkit owns input resolution; the Hermes modules extend that contract without
accessing flake inputs directly. `flake.lock` pins the upstream revision.

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

Craig's setup starts with one default agent, Hermes, in `~/Projects/hermes`.
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
for the new home. Kanban and gateway multiplexing are disabled.

User bot definitions live in `API/nix/users/craole/ai/bots/<name>/default.nix`.
The parent declares a `definitions` path map and an explicit `enabled` list.
The `hermes` entry configures the root agent; other enabled entries configure
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

The owner adds the bot path to `definitions` and its name to `enabled` to
activate it. Supporting skill files use additional `home.file` entries beneath
the same skill directory. Keep credentials in runtime files referenced through
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
