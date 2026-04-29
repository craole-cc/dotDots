{
  lib,
  paths ? {}, #TODO: We should pass in paths from the top-level default.nix
  ...
}: let
  inherit (lib.attrsets) attrNames;
  inherit (lib.lists) head toList;
  inherit (lib.packages) mkPkgs;
  inherit (lib.scripts) mkScriptPackage mkMissionControl;
  inherit (lib.strings) concatStringsSep mkStyledOutput mkSection mkHeader;
  inherit (lib.trivial) readFile;

  scripts = let
    dir = paths.scripts or ../scripts;
  in {
    deploy = dir + "/deploy-templates.sh";
    reset = dir + "/reset-flake.sh";
  };

  entries = {
    cargo = {
      source = ./cargo.toml;
      target = ".cargo/config.toml";
    };
    envrc = {
      source = ./envrc;
      target = ".envrc";
    };
    gitignore = {
      source = ./gitignore;
      target = ".gitignore";
    };
    markdownlint = {
      source = ./markdownlint-cli2.yaml;
      target = [".markdownlint-cli2.yaml" "markdownlint-cli2.yaml"];
    };
    rust-analyzer = {
      source = ./rust-analyzer.toml;
      target = "rust-analyzer.toml";
    };
    rust-toolchain = {
      source = ./rust-toolchain.toml;
      target = "rust-toolchain.toml";
    };
    rustfmt = {
      source = ./rustfmt.toml;
      target = "rustfmt.toml";
    };
    shellcheck = {
      source = ./shellcheckrc;
      target = [".shellcheckrc" "shellcheckrc"];
    };
    treefmt = {
      source = ./treefmt.toml;
      target = [".treefmt.toml" "treefmt.toml"];
    };
  };

  #> Generates one `deploy_entry` call per template entry
  deployTemplate = name: {
    source,
    target,
  }: let
    targets = toList target;
    preferred = head targets;
    list = concatStringsSep " " (map (target: "\"${target}\"") targets);
  in ''deploy_entry "${name}" "${source}" "${preferred}" ${list}'';

  deployCalls =
    concatStringsSep "\n"
    (map (name: deployTemplate name entries.${name}) (attrNames entries));

  # --- package builders -------------------------------------------------

  mkTemplatePackage = {pkgs ? mkPkgs {}}: let
    print = mkStyledOutput {inherit pkgs;};

    banner = mkHeader {
      inherit print;
      title = "Template Deployment";
      content = "Syncing project configuration files into your workspace";
    };

    section = mkSection {
      inherit print;
      title = "Entries";
      content = map (name: name) (attrNames entries);
    };
  in
    # Still needs writeShellScriptBin because we must append generated
    # deployCalls after the file content; mkScriptPackage doesn't support
    # a post-file block. Everything else goes through the helpers.
    pkgs.writeShellScriptBin "deploy-templates" ''
      ${banner}
      ${section}
      CMD_GUM="${print.gum}"
      ${readFile scripts.deploy}
      ${deployCalls}
    '';

  # reset fits mkScriptPackage perfectly – no codegen needed
  mkResetPackage = {pkgs ? mkPkgs {}}:
    mkScriptPackage {
      inherit pkgs;
      name = "reset-flake";
      file = scripts.reset;
    };

  # --- unified dispatcher -----------------------------------------------

  mkCommands = {pkgs ? mkPkgs {}}:
    mkMissionControl {
      inherit pkgs;
      shellName = "rusti";
      commands = {
        deploy-templates = {
          description = "Sync config templates into the project";
          run = "${mkTemplatePackage {inherit pkgs;}}/bin/deploy-templates";
        };
        reset-flake = {
          description = "Reset the flake lock and generated files";
          run = "${mkResetPackage {inherit pkgs;}}/bin/reset-flake";
        };
      };
    };
in {
  inherit entries;

  packages = {
    deploy = mkTemplatePackage;
    reset = mkResetPackage;
  };

  # commands is now a proper mission-control dispatcher, not a raw bin path
  commands = mkCommands;
}
