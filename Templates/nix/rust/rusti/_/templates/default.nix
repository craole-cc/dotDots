{
  lib,
  pkgs,
  ...
}: let
  inherit (lib.attrsets) attrNames;
  inherit (lib.lists) head toList;
  inherit (lib.strings) concatStringsSep mkStyledOutput;

  print = mkStyledOutput {inherit pkgs;};

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

  deployCalls = concatStringsSep "\n" (map (name: deployTemplate name entries.${name}) (attrNames entries));

  deployScript = let
    template = builtins.readFile ../scripts/deploy-templates.sh;
  in
    ''
      GUM="${print.gum}"
    ''
    + template
    + ''

      ${deployCalls}
    '';

  deployPackage = pkgs.writeShellScriptBin "deploy-templates" ''
    ${deployScript}
  '';

  resetPackage = pkgs.writeShellScriptBin "reset-flake" (
    builtins.readFile ../scripts/reset-flake.sh
  );
in {
  inherit deployPackage deployScript entries resetPackage;
  command = "${deployPackage}/bin/deploy-templates";
  resetCommand = "${resetPackage}/bin/reset-flake";
}
