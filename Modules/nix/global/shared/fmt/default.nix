{
  lix,
  pkgs,
  flake,
  binaries,
  packages,
  ...
}: let
  inherit (flake) inputs;
  inherit (inputs.treefmt.lib) evalModule;
  # inherit (lix.attrsets.access) attrValues;
  inherit (lix.attrsets.aggregation) recursiveUpdate;
  inherit (lix.attrsets.construction) genAttrs;
  inherit (lix.attrsets.transformation) mapAttrs;
  inherit (lix.modules.construction) mkForce;
  inherit (pkgs) writeShellScriptBin;

  module = {
    _module.args = {inherit lix flake binaries;};
    imports = lix.filesystem.traversal.importAllPaths ./.;
    projectRootFile = "flake.nix";

    settings.global.excludes = [
      ".dotsrc"
      "LICENSE"
      "**/node_modules/**"
      "**/target/**"
      "**/.git/**"
      "**/dist/**"
      "**/build/**"
      "**/review/**"
      "**/archive/**"
      "*.lock"
      "Assets/**"
      "*.diff"
      "*.patch"
      "AGENTS.md"
      "**/dump.nix"
      "**/.bin/**"
      "**/.config/**"
      "**README.md"
      ".zed/**"
      "Configuration/**"
      "Documentation/**"
      "Environment/**"
      "Modules/global/**"
      "Modules/nixos/configurations/hosts/QBX/**"
      "Modules/nixos/scripts/**"
      "Review/**"
      "Scripts/**"
      "Tasks/**"
      "Templates/**"
    ];
  };

  #~@ Nix-side eval: store-path commands, used by `nix fmt`.
  imported = {
    inherit module;
    eval = evalModule pkgs module;
  };

  #~@ Portable eval: same module, bare commands resolved via PATH,
  #~@ exported to .treefmt.toml for use outside Nix (e.g. Windows).
  exported = let
    names = [
      "actionlint"
      "alejandra"
      "dprint"
      "leptosfmt"
      "rustfmt"
      "shellcheck"
      "shfmt"
      "statix"
      "stylua"
      "typos"
      "typstyle"
    ];

    commands =
      mapAttrs
      (_: name: {command = mkForce name;})
      (genAttrs names (name: name));

    portable = {
      settings.formatter = recursiveUpdate commands {
        dprint.options = mkForce [
          "fmt"
          "--allow-no-files"
          "--config"
          "dprint.json"
        ];
      };
    };

    module' = {imports = [module portable];};
  in {
    inherit names;
    module = module';
    eval = evalModule pkgs module';
  };

  # inherit (imported.eval.config.build) check programs wrapper devShell;
  inherit (exported.eval.config.build) configFile;

  sync = let
    name = "sync-treefmt-toml";

    script = writeShellScriptBin name ''
      set -euo pipefail
      root="$(${binaries.git} rev-parse --show-toplevel)"
      cp --force ${configFile} "$root/.treefmt.toml"
      chmod u+w "$root/.treefmt.toml"
      printf "Synced .treefmt.toml (portable) from fmt.nix\n"
    '';

    value = {
      type = "app";
      program = "${script}/bin/${name}";
    };
  in {inherit name value;};

  treefmt = imported.eval.config.build;
  formatter = treefmt.wrapper;
in
  treefmt
  // {
    inherit formatter;
    apps = {${sync.name} = sync.value;};
    checks.formatting = treefmt.check flake.path;
    # formatters = (attrValues treefmt.programs) ++ [formatter];
    formatters = packages ++ [formatter];
  }
