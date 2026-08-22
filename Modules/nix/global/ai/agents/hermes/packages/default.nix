{
  pkgsFor,
  pkgs,
  lix,
  ...
}: let
  inherit (pkgs) writeScriptBin;
  inherit (lix.filesystem.access) readFile;

  resolved = pkgsFor {
    sources = {
      desktop = {
        input = "hermes-agent";
        description = "Official Desktop Interface";
      };
      minimal = {
        input = "hermes-agent";
        description = "Official Agent CLI";
      };
      tui = {
        input = "hermes-agent";
        description = "Official Terminal Interface";
      };
      hermes-hud = {
        input = "llm-agents";
        description = "Community status / memory monitor TUI";
      };
      hermes-one = {
        input = "llm-agents";
        description = "Community desktop (Hermes One)";
      };
    };
  };

  scripts = {
    start = writeScriptBin "start" (readFile ./start.sh);
    show-help = writeScriptBin "show-help" (readFile ./help.sh);
  };
in
  resolved
  // scripts
  // {
    packages = resolved.packages ++ (with scripts; [start show-help]);
  }
