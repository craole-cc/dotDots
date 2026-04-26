{lib, ...}: let
  inherit (lib.attrsets) attrNames;
  inherit (lib.lists) head toList;
  inherit (lib.packages) mkPkgs;
  inherit (lib.strings) concatStringsSep mkStyledOutput;
  inherit (lib.trivial) readFile;

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

  deployTemplate = name: {
    source,
    target,
  }: let
    target' = let
      targets = toList target;
      preferred = head targets;
      args = concatStringsSep " " (map (t: "\"${t}\"") targets);
      list = args;
    in {inherit preferred list;};
  in ''
    deploy_entry "${name}" "${source}" "${target'.preferred}" ${target'.list}
  '';

  deployCalls = concatStringsSep "\n" (map
    (name: deployTemplate name entries.${name})
    (attrNames entries));

  scripts = {
    deploy = {pkgs ? mkPkgs {}}: let
      template = readFile ./deploy.sh;
      print = mkStyledOutput {inherit pkgs;};
    in
      ''CMD_GUM="${print.gum}"''
      + template
      + ''${deployCalls}'';
  };

  packages = {
    deploy = {pkgs ? mkPkgs {}}:
      pkgs.writeShellScriptBin "deploy-templates" ''${scripts.deploy}'';
    reset = {pkgs ? mkPkgs {}}:
      pkgs.writeShellScriptBin "reset-flake" (readFile ./reset.sh);
  };
in {
  inherit packages scripts entries;
  commands = "${packages.deploy {}}/bin/deploy-templates";
  reset = "${packages.reset {}}/bin/reset-flake";
}
