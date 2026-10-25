{
  lix,
  context,
  mkEnable,
  ...
}: let
  lang = "markup";
  condition = true;
  enable = condition;
  options.${lang}.enable = mkEnable {inherit context condition;};
  defaultFormatter = "jnoortheen.nix-ide";
  server = "nixd";
  inherit (lix.lists.transformation) filter;
  extensions = [
    defaultFormatter
    "bbenoist.Nix"
    "kamadorueda.alejandra"
    "jeff-hykin.better-nix-syntax"
    "SebastianKarlsen.direnv-trusted"
    "vix.lint-runner"
  ];

  settings = {
    "[${lang}]".editor = {inherit defaultFormatter;};
    "${lang}" = {
      enableLanguageServer = true;
      serverPath = server;
      serverSettings."${server}" = {
        formatting.command = ["alejandra" "-q" "-"];
        diagnostic.suppress = ["sema-primop-overridden"];
      };
    };

    #~@ direnv
    direnv-trusted = {
      #> Cache the loaded environment in the workspace state, and apply it synchronously at startup (if direnv still allows the same `.envrc`) so that other extensions see it from the start. **Note:** values, including secrets loaded from `.env` files, are stored in VS Code's workspace storage.
      cacheEnvironment = true;

      #? Path to the `direnv` executable (direnv >= 2.33).
      #? Machine-scoped so that a workspace cannot point it elsewhere.
      path = "direnv";

      #> Show a notification offering to allow (or deny) an `.envrc` that direnv has not allowed yet.
      promptToAllow = true;

      #> Restart extensions when the environment changes
      #? Processes they already started (language servers…) are available.
      #? - prompt: Ask before restarting the extension host.
      #? - always: Restart the extension host automatically (at most once a minute).
      #? - never: Never restart; processes already started by other extensions keep their old environment.
      restartExtensions = "prompt";
    };

    lintRunner = {
      tools.statix = {
        kind = "diagnostic";
        command = "statix";
        args = ["check" "--format" "errfmt" "\${file}"];
        successExitCodes = [0 1];
        parser = {
          flags = "gm";
          pattern = "^.+?>(?<line>\\\\d+):(?<col>\\\\d+):[WE]:(?<code>\\\\d+):(?<message>.+)$";
        };
      };

      targets = [
        {
          name = "Nix";
          match = {
            languages = [lang];
            files = ["**/*.${lang}"];
          };
          onOpen = {
            strategy = "sequence";
            tools = ["statix"];
          };
          onSave = {
            strategy = "sequence";
            tools = ["statix"];
          };
          manual = {
            strategy = "sequence";
            tools = ["statix"];
          };
        }
      ];
    };
    settingsSync = {
      ignoredExtensions = filter (ext: ext != "vix.lint-runner") extensions;
    };
  };
in {inherit enable extensions options settings;}
