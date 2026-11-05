{
  mkSource,
  mkAlias,
  mkAliasFamily,
  mergeDisjoint,
  ...
}: {
  codex = mkSource {
    categories = ["scripting" "ai"];
    description = "OpenAI Codex coding agent";
    aliases = let
      cmd = "codex";
      mk = alias: mkAlias cmd alias;

      variants = {
        Exec = {
          args = ["exec"];
          description = "run codex non-interactively, e.g. cxe 'fix the failing test'";
        };
        Review = {
          args = ["review"];
          description = "run a code review non-interactively";
        };
        Resume = {
          args = ["resume"];
          description = "resume a previous session (picker)";
        };
        ResumeLast = {
          args = ["resume" "--last"];
          description = "resume the most recent session";
        };
        Fork = {
          args = ["fork"];
          description = "fork a previous session (picker)";
        };
        ForkLast = {
          args = ["fork" "--last"];
          description = "fork the most recent session";
        };
        Apply = {
          args = ["apply"];
          description = "apply the latest codex diff to the working tree";
        };
        Agents = {
          args = ["agents"];
          description = "browse agent sessions on the local app-server daemon";
        };
        Cloud = {
          args = ["cloud"];
          description = "browse Codex Cloud tasks and apply changes locally";
        };
        Queue = {
          args = ["queue"];
          description = "queue a message for an existing session";
        };
        Archive = {
          args = ["archive"];
          description = "archive a saved session by id or name";
        };
        Unarchive = {
          args = ["unarchive"];
          description = "unarchive a saved session by id or name";
        };
        Delete = {
          args = ["delete"];
          description = "permanently delete a saved session";
        };
        Login = {
          args = ["login"];
          description = "manage codex login";
        };
        Logout = {
          args = ["logout"];
          description = "remove stored codex credentials";
        };
        Mcp = {
          args = ["mcp"];
          description = "manage external MCP servers";
        };
        Plugin = {
          args = ["plugin"];
          description = "manage codex plugins";
        };
        Features = {
          args = ["features"];
          description = "inspect feature flags";
        };
        Sandbox = {
          args = ["sandbox"];
          description = "run a command inside the codex sandbox";
        };
        Doctor = {
          args = ["doctor"];
          description = "diagnose install, config, auth and runtime health";
        };
        Update = {
          args = ["update"];
          description = "update codex to the latest version";
        };
        Completion = {
          args = ["completion"];
          description = "generate shell completion scripts";
        };
        Search = {
          args = ["--search"];
          description = "start codex with live web search enabled";
        };
        Worktree = {
          args = ["--worktree"];
          description = "start codex in a new managed git worktree";
        };
        Oss = {
          args = ["--oss"];
          description = "start codex with a local open-source provider";
        };
        ReadOnly = {
          args = ["--sandbox" "read-only"];
          description = "start codex with a read-only sandbox";
        };
        Yolo = {
          args = ["--dangerously-bypass-approvals-and-sandbox"];
          description = "DANGEROUS: no approvals, no sandbox";
        };
      };
    in
      mergeDisjoint [
        {
          cx = mk {description = "start the interactive codex agent";};
          cxe = mk variants.Exec;
          cxr = mk variants.Review;
          cxres = mk variants.Resume;
          cxlast = mk variants.ResumeLast;
          cxapply = mk variants.Apply;
          cxdoctor = mk variants.Doctor;
        }
        (mkAliasFamily cmd variants)
      ];
  };

  claude = mkSource {
    categories = ["scripting" "ai"];
    description = "Anthropic Claude Code agent";
    input = "llm-agents";
    target = "claude-code";
    exe = "claude";
    aliases = let
      cmd = "claude";
      mk = alias: mkAlias cmd alias;

      variants = {
        Continue = {
          args = ["--continue"];
          description = "continue the most recent conversation in this directory";
        };
        Resume = {
          args = ["--resume"];
          description = "resume a conversation (picker, or pass a session id or name)";
        };
        Print = {
          args = ["--print"];
          description = "non-interactive output for pipes, e.g. git diff | clp 'summarize'";
        };
        Plan = {
          args = ["--permission-mode" "plan"];
          description = "start in plan mode";
        };
        Background = {
          args = ["--bg"];
          description = "start a background session and return immediately";
        };
        Worktree = {
          args = ["--worktree"];
          description = "start in a new git worktree";
        };
        Safe = {
          args = ["--safe-mode"];
          description = "start with all customizations disabled, for troubleshooting";
        };
        Bare = {
          args = ["--bare"];
          description = "minimal mode: no hooks, plugins or CLAUDE.md discovery";
        };
        Agents = {
          args = ["agents"];
          description = "manage background agents";
        };
        Attach = {
          args = ["attach"];
          description = "open a background session in this terminal";
        };
        Logs = {
          args = ["logs"];
          description = "print a background session's recent output";
        };
        Stop = {
          args = ["stop"];
          description = "stop a background session";
        };
        Rm = {
          args = ["rm"];
          description = "delete a background session";
        };
        Respawn = {
          args = ["respawn"];
          description = "restart background sessions on the current version";
        };
        Ultrareview = {
          args = ["ultrareview"];
          description = "cloud multi-agent review of the current branch or a PR";
        };
        Auth = {
          args = ["auth"];
          description = "manage authentication";
        };
        SetupToken = {
          args = ["setup-token"];
          description = "set up a long-lived auth token";
        };
        Mcp = {
          args = ["mcp"];
          description = "configure and manage MCP servers";
        };
        Plugin = {
          args = ["plugin"];
          description = "manage plugins";
        };
        Doctor = {
          args = ["doctor"];
          description = "check installation health";
        };
        Update = {
          args = ["update"];
          description = "check for updates and install";
        };
        Yolo = {
          args = ["--dangerously-skip-permissions"];
          description = "DANGEROUS: bypass all permission checks";
        };
      };
    in
      mergeDisjoint [
        {
          clc = mk variants.Continue;
          clr = mk variants.Resume;
          clp = mk variants.Print;
          claude-plan = mk variants.Plan;
          claude-bg = mk variants.Background;
          claude-agents = mk variants.Agents;
          claude-attach = mk variants.Attach;
          claude-logs = mk variants.Logs;
          claude-review = mk variants.Ultrareview;
          claude-doctor = mk variants.Doctor;
          claude-update = mk variants.Update;
        }
        (mkAliasFamily cmd variants)
      ];
  };

  hermes = mkSource {
    categories = ["scripting" "ai"];
    description = "Hermes tool-calling AI agent";
    input = "hermes-agent";
    target = "default";
    exe = "hermes";
    transform = package: package.override {extraDependencyGroups = ["messaging"];};
    aliases = let
      cmd = "hermes";
      mk = alias: mkAlias cmd alias;

      variants = {
        Tui = {
          args = ["--tui"];
          description = "launch the modern TUI";
        };
        Continue = {
          args = ["--continue"];
          description = "resume the most recent session, or pass a name";
        };
        Oneshot = {
          args = ["--oneshot"];
          description = "single prompt, prints only the final answer, e.g. hermes-ask 'why is dns slow'";
        };
        Worktree = {
          args = ["--worktree"];
          description = "run in an isolated git worktree";
        };
        Safe = {
          args = ["--safe-mode"];
          description = "disable all customizations for troubleshooting";
        };
        Sessions = {
          args = ["sessions" "list"];
          description = "list past sessions";
        };
        SessionsBrowse = {
          args = ["sessions" "browse"];
          description = "interactive session picker";
        };
        Logs = {
          args = ["logs"];
          description = "view agent.log";
        };
        LogsFollow = {
          args = ["logs" "-f"];
          description = "follow agent.log in real time";
        };
        LogsErrors = {
          args = ["logs" "errors"];
          description = "view errors.log";
        };
        Status = {
          args = ["status"];
          description = "show status of all components";
        };
        Doctor = {
          args = ["doctor"];
          description = "check configuration and dependencies";
        };
        Update = {
          args = ["update"];
          description = "update hermes to the latest version";
        };
        Config = {
          args = ["config"];
          description = "view configuration";
        };
        ConfigEdit = {
          args = ["config" "edit"];
          description = "edit configuration in $EDITOR";
        };
        Model = {
          args = ["model"];
          description = "select default model and provider";
        };
        Usage = {
          args = ["usage"];
          description = "show account rate-limit windows";
        };
        Insights = {
          args = ["insights"];
          description = "show usage insights and analytics";
        };
        Dashboard = {
          args = ["dashboard"];
          description = "start the web UI dashboard";
        };
        Gateway = {
          args = ["gateway"];
          description = "messaging gateway management";
        };
        GatewayStatus = {
          args = ["gateway" "status"];
          description = "show gateway status";
        };
        Skills = {
          args = ["skills"];
          description = "search, install and manage skills";
        };
        Mcp = {
          args = ["mcp"];
          description = "manage MCP servers";
        };
        Cron = {
          args = ["cron"];
          description = "cron job management";
        };
        Kanban = {
          args = ["kanban"];
          description = "multi-profile collaboration board";
        };
        Profile = {
          args = ["--profile"];
          description = "run Hermes with a named profile";
        };
        Profiles = {
          args = ["profile"];
          description = "manage profiles";
        };
        Backup = {
          args = ["backup"];
          description = "back up the hermes home directory to a zip";
        };
        Pause = {
          args = ["pause"];
          description = "emergency stop for cron, kanban and gateway turns";
        };
        Unpause = {
          args = ["resume"];
          description = "lift the emergency stop set by pause";
        };
        Yolo = {
          args = ["--yolo"];
          description = "DANGEROUS: bypass all 'dangerous-command' safeguards";
        };
      };
    in
      mergeDisjoint [
        {
          hermes-tui = mk variants.Tui;
          hermes-continue = mk variants.Continue;
          hermes-ask = mk variants.Oneshot;
          hermes-sessions = mk variants.Sessions;
          hermes-browse = mk variants.SessionsBrowse;
          hermes-logs = mk variants.Logs;
          hermes-follow = mk variants.LogsFollow;
          hermes-errors = mk variants.LogsErrors;
          hermes-status = mk variants.Status;
          hermes-doctor = mk variants.Doctor;
          hermes-update = mk variants.Update;
          hermes-config = mk variants.Config;
          hermes-edit = mk variants.ConfigEdit;
          hermes-usage = mk variants.Usage;
          hermes-dashboard = mk variants.Dashboard;
        }
        (mkAliasFamily cmd variants)
      ];
  };

  llmhop = mkSource {
    categories = ["scripting" "ai"];
    description = "Language model request router";
    input = "llmhop";
    aliases = let
      cmd = "llmhop";
      mk = alias: mkAlias cmd alias;

      variants = {
        Check = {
          args = ["-check"];
          description = "validate config.json in this directory and exit";
        };
        Config = {
          args = ["-config"];
          description = "serve with a specific config, e.g. llmhop-config ./hop.json";
        };
        CheckConfig = {
          args = ["-check" "-config"];
          description = "validate a specific config and exit, e.g. llmhop-validate ./hop.json";
        };
      };
    in
      mergeDisjoint [
        {
          llmhop-check = mk variants.Check;
          llmhop-config = mk variants.Config;
          llmhop-validate = mk variants.CheckConfig;
        }
        (mkAliasFamily cmd variants)
      ];
  };

  ollama = mkSource {
    categories = ["scripting" "ai"];
    description = "Local language model inference";
    aliases = let
      cmd = "ollama";
      mk = alias: mkAlias cmd alias;

      variants = {
        Serve = {
          args = ["serve"];
          description = "start the ollama server";
        };
        List = {
          args = ["list"];
          description = "list installed models";
        };
        Find = {
          args = ["list"];
          pipe = [["rg" "-i"]];
          description = "search installed models, e.g. ollama-find llama";
        };
        Ps = {
          args = ["ps"];
          description = "list running models";
        };
        Run = {
          args = ["run"];
          description = "run a model, e.g. ollama-run llama3";
        };
        Stop = {
          args = ["stop"];
          description = "stop a running model";
        };
        Pull = {
          args = ["pull"];
          description = "pull a model from the registry";
        };
        Push = {
          args = ["push"];
          description = "push a model to the registry";
        };
        Show = {
          args = ["show"];
          description = "show information for a model";
        };
        Create = {
          args = ["create"];
          description = "create a model from a Modelfile";
        };
        Copy = {
          args = ["cp"];
          description = "copy a model";
        };
        Remove = {
          args = ["rm"];
          description = "remove a model";
        };
        Launch = {
          args = ["launch"];
          description = "launch the ollama menu or an integration";
        };
        Signin = {
          args = ["signin"];
          description = "sign in to ollama.com";
        };
        Signout = {
          args = ["signout"];
          description = "sign out of ollama.com";
        };
      };
    in
      mergeDisjoint [
        {
          ollama-ls = mk variants.List;
          ollama-find = mk variants.Find;
          ollama-ps = mk variants.Ps;
          ollama-run = mk variants.Run;
          ollama-pull = mk variants.Pull;
          ollama-stop = mk variants.Stop;
          ollama-show = mk variants.Show;
          ollama-rm = mk variants.Remove;
        }
        (mkAliasFamily cmd variants)
      ];
  };

  ollama-cpu = mkSource {
    categories = ["scripting" "ai"];
    description = "Local language model inference on the CPU";
  };
}
