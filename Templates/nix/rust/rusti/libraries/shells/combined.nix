{lib}: let
  inherit (lib.attrsets) recursiveUpdate;
  inherit (lib.packages) mkPkgs;
  inherit (lib.trivial) isNotEmpty;
  inherit (lib.shells) mkAISpec mkRustSpec;

  mkCombinedSpec = {
    pkgs ? null,
    channel ? null,
    preset ? null,
    targets ? null,
    extensions ? null,
    includeEditor ? true,
    includeAnalytics ? true,
    includeWorkflow ? false,
    minimal ? false,
  }: let
    pkgs' =
      if isNotEmpty pkgs
      then pkgs
      else mkPkgs {};
# env

    rust = mkRustSpec {
      pkgs = pkgs';
      inherit channel targets extensions includeEditor minimal;
    };

    ai = mkAISpec {
      pkgs = pkgs';
      inherit preset includeAnalytics includeWorkflow minimal;
    };

    rustMeta = rust.__meta;
    aiMeta = ai.__meta;

    rustName = rust.shell.name;
    aiName = ai.shell.name;

    combinedName = "combined-${rustName}-${aiName}";

    combinedWelcome = scripts.mkScriptPackage {
      pkgs = pkgs';
      name = "combined-welcome";
      file = ../../scripts/combined-welcome.sh;
      env = {
        AI_PRESET = aiMeta.preset;
        GUM = "${pkgs'.gum}/bin/gum";
        RUST_CHANNEL = rustMeta.toolchain.channel;
        RUST_TOOLCHAIN_FILE =
          if rustMeta.toolchain.file != null
          then toString rustMeta.toolchain.file
          else "<channel>";
      };
    };

    missionCommands = rustMeta.missionCommands // aiMeta.missionCommands;
    missionControl = scripts.mkMissionControl {
      pkgs = pkgs';
      shellName = combinedName;
      commands = missionCommands;
    };
    commandsAlias = scripts.mkAliasPackage {
      pkgs = pkgs';
      name = "commands";
      target = "${missionControl}/bin/mission-control";
    };
    mcAlias = scripts.mkAliasPackage {
      pkgs = pkgs';
      name = "mc";
      target = "${missionControl}/bin/mission-control";
    };

    env = recursiveUpdate rust.shell.env ai.shell.env;
    payloadPackages = rustMeta.payloadPackages ++ aiMeta.payloadPackages;
    controlPackages = [
      rustMeta.templates.deployPackage
      rustMeta.templates.resetPackage
      rustMeta.command
      aiMeta.command
      combinedWelcome
      missionControl
      commandsAlias
      mcAlias
    ];
    shellHook = ''
      ${rustMeta.templates.command}
      ${combinedWelcome}/bin/combined-welcome
    '';
  in {
    __meta = {
      kind = "combined";
      inherit aiMeta controlPackages env missionCommands payloadPackages rustMeta shellHook;
      name = combinedName;
    };

    shell = {
      name = combinedName;
      inherit env shellHook;
      packages = controlPackages ++ payloadPackages;
    };
  };

  mkCombinedSuite = {pkgs ? null}: let
    mk = args: mkCombinedSpec ({inherit pkgs;} // args);
  in {
    combined = mk {};
    combined-common = mk {
      channel = "nightly";
      preset = "common";
    };
    combined-stable = mk {
      channel = "stable";
      preset = "common";
    };
    combined-full = mk {
      channel = "nightly";
      preset = "full";
      includeWorkflow = true;
    };
    combined-minimal = mk {
      channel = "nightly";
      preset = "minimal";
      includeAnalytics = false;
      minimal = true;
    };
  };
in {
  inherit mkCombinedSpec mkCombinedSuite;
  mkCombined = mkCombinedSpec;
  mkCombinedShells = mkCombinedSuite;
}
