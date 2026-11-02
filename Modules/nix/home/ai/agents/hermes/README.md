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

The user-agnostic settings enable built-in memory and user profiles, with
`memory.provider = ""`. No model provider, model ID or endpoint is pinned by
default; those selections belong in user settings or provider resolutions.

The complete module baseline is declared locally in `defaults.nix`; application
settings are defined in `settings.nix`. Edit these files to change our defaults.
Enabled profiles and effective package selections are applied as resolutions,
so they do not change the baseline used by `updates`.

The module is split into folders:

| Folder | Responsibility |
| --- | --- |
| `bots/` | Typed profile declarations, writable configuration activation, Desktop Bot metadata and persistent Bot Chat launchers |
| `gateway/` | Shared gateway multiplexing and routes using native Hermes keys |
| `kanban/` | Kanban dispatcher, worker selection, planning model and concurrency |

## Declare A Team

Add a declaration to a Home Manager module imported for the user. Hermes must
also be selected through the user package API. Declaring profiles does not select
Ollama or download models; configure the host's Ollama module separately when
using a local model.

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
          provider = "ollama";
          default = "qwen3:4b-instruct";
          base_url = "http://127.0.0.1:11434/v1";
        };
        home.file."SOUL.md" = ''
          Keep replies brief. Clarify the request and record a task for the planner.
        '';
      };

      planner = {
        description = "Plan tasks and coordinate specialists.";
        bot.enable = true;
        settings.model = {
          provider = "openai-codex";
          default = "gpt-5.6-terra";
        };
      };

      reviewer = {
        description = "Review completed work and report concrete findings.";
        bot.enable = true;
        settings.model = {
          provider = "openai-codex";
          default = "gpt-5.6-terra";
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
          model = "gpt-5.6-terra";
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
settings. It also provisions declared documents, plugins and secret files.
Session databases, learned memory and task data are never supplied as Nix files.
Documents in a tool workspace require an explicit `workingDirectory`.
Profiles use the main Hermes package and Python dependencies. Supply any plugin
dependencies through the main service's upstream package options.

On Linux, profile activation runs before Home Manager reloads systemd services.
The gateway unit tracks declared team changes so Home Manager can restart it
after writing the updated configuration. Runtime secret contents are not part of
that trigger; rotate and restart those credentials through their secret manager.

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

Automatic decomposition is off in the starter declaration. In this Hermes
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
