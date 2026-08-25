{
  pkgsFor,
  inputs,
  pkgs,
  ...
}: let
  inherit (pkgs) writeShellScriptBin;

  sources = {
    inherit (inputs) hermes-agent llm-agents;
  };

  tools =
    pkgsFor {
      sources = {
        desktop = {
          input = "hermes-agent";
          description = "Official Desktop Interface";
        };
        minimal = {
          input = "hermes-agent";
          description = "Official Command Line Interface";
        };
        tui = {
          input = "hermes-agent";
          description = "Official Terminal Interface";
          exe = "hermes-tui";
        };
        hermes-hud = {
          input = "llm-agents";
          description = "Community-maintained Terminal Interface";
        };
        hermes-one = {
          input = "llm-agents";
          description = "Community-maintained Desktop Interface";
        };
      };
    }
    // {default = tools.minimal;};

  graphicalLaunchers = [
    (writeShellScriptBin "hermes-desktop" ''
      exec ${../scripts/launch-wayland.sh} ${tools.desktop.exe} "$@"
    '')
    (writeShellScriptBin "hermes-one" ''
      exec ${../scripts/launch-wayland.sh} ${tools.hermes-one.exe} "$@"
    '')
  ];

  packages =
    (builtins.filter
      (package: package != tools.desktop.package && package != tools.hermes-one.package)
      tools.packages)
    ++ graphicalLaunchers;
in {
  inherit packages sources tools;
}
