{
  pkgsFor,
  inputs,
  pkgs,
  ...
}: let
  inherit (pkgs) writeShellScriptBin;

  resolved = pkgsFor {
    sources = {
      hermes-agent = {
        input = "llm-agents";
        description = "Official Command Line Interface";
      };
      hermes-desktop = {
        input = "llm-agents";
        description = "Official Desktop Interface";
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
    aliases = {
      minimal = "hermes-agent";
      desktop = "hermes-desktop";
    };
  };

  tuiPackage = writeShellScriptBin "hermes-tui" ''
    exec ${resolved.minimal.exe} --tui "$@"
  '';

  tui = {
    name = "tui";
    source = "llm-agents";
    value = tuiPackage;
    package = tuiPackage;
    pkg = tuiPackage;
    command = "hermes-tui";
    cmd = "hermes-tui";
    exe = "${tuiPackage}/bin/hermes-tui";
    bin = "${tuiPackage}/bin";
    paths = {
      executable = "${tuiPackage}/bin/hermes-tui";
      binary = "${tuiPackage}/bin";
      store = tuiPackage;
    };
    revision = resolved.minimal.revision or null;
    version = resolved.minimal.version or null;
    ver = resolved.minimal.ver or null;
    vr3n = resolved.minimal.vr3n or null;
    description = "Official Terminal Interface";
  };

  binaries = resolved.binaries // {tui = tui.exe;};
  commands = resolved.commands // {tui = tui.cmd;};
  versions = resolved.versions // {tui = tui.ver;};
  origins = resolved.origins // {tui = tui.source;};
  descriptions = resolved.descriptions // {tui = tui.description;};

  tools =
    resolved
    // {
      inherit
        binaries
        commands
        descriptions
        origins
        tui
        versions
        ;
      bins = binaries;
      cmds = commands;
      vr3n = versions;
      names = resolved.names ++ ["tui"];
      packages = resolved.packages ++ [tuiPackage];
      default = resolved.minimal;
    };

  # The official Hermes source is now the fixed-output source derivation
  # carried by llm-agents.nix. Merely evaluating dotDots no longer fetches the
  # NousResearch repository; the source is realized only when a Hermes shell or
  # package that depends on it is built.
  sources = {
    inherit (inputs) llm-agents;
    hermes-agent = tools.minimal.package.src;
  };

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
