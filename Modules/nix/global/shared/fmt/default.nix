{
  lix,
  pkgs,
  flake,
  pkgsFor,
  sources,
  print,
  ...
}: let
  inherit (flake) inputs;
  inherit (inputs.treefmt.lib) evalModule;
  inherit (lix.attrsets.access) attrNames;
  inherit (lix.attrsets.aggregation) recursiveUpdate;
  inherit (lix.attrsets.construction) genAttrs optionalAttrs;
  inherit (lix.attrsets.transformation) filterAttrs;
  inherit (lix.filesystem.traversal) importAllPaths;
  inherit (lix.lists.predicates) elem;
  inherit (lix.lists.transformation) filter sort uniqueStrings;
  inherit (lix.modules.construction) mkForce;
  inherit (pkgs) writeShellApplication writeShellScript;

  mkConfig = module: (evalModule pkgs module).config;
  extraSources = {
    treefmt = {
      input = "treefmt";
      versionArgs = "--version";
    };
    statix = null;
    harper = null;
    tombi = null;
  };
  utility = pkgsFor {
    sources = sources // extraSources;
  };

  #~@ Nix-side eval: store-path commands, used by `nix fmt`.
  init = let
    module = {
      _module.args = {
        inherit lix flake;
        inherit (utility) binaries;
      };
      imports = importAllPaths ./.;
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
    config = mkConfig module;
  in
    config // config.build // {inherit module;};

  tool = let
    formatters = attrNames (init.settings.formatter or {});
    programs = attrNames (
      filterAttrs (_: cfg: cfg.enable or false) (init.programs or {})
    );
    packages = filter (name: !(elem name programs)) formatters;
    tools = uniqueStrings (formatters ++ programs ++ ["treefmt"]);

    resolved = pkgsFor {
      required = false;
      aliases = {
        ruff-check = "ruff";
        ruff-format = "ruff";
      };
      sources =
        genAttrs tools (_: null)
        // genAttrs ["ruff"] (_: null)
        // extraSources;
    };

    of = name: resolved.${name} or null;

    wrappers = genAttrs packages (
      name:
        optionalAttrs
        ((of name) != null)
        {command = mkForce (of name).exe;}
    );
    # wrappers =
    #   recursiveUpdate
    #   (genAttrs programs (name: {
    #     command = mkForce ((of name).exe or name);
    #   }))
    #   (genAttrs packages (name:
    #     optionalAttrs ((of name) != null) {
    #       command = mkForce (of name).exe;
    #     }));
  in
    resolved
    // {
      inherit tools packages programs formatters wrappers of;
      names = tools;
    };

  eval = let
    module = {
      settings.formatter = recursiveUpdate tool.wrappers {
        dprint.options = mkForce [
          "fmt"
          "--allow-no-files"
          "--config"
          "dprint.json"
        ];
        statix = {
          command = mkForce "${writeShellScript "statix-wrapper" ''
            for file in "$@"; do
              ${tool.statix.exe} fix "$file"
            done
          ''}";
          options = mkForce [];
        };
      };
    };

    config = mkConfig {imports = [init.module module];};
  in
    config // config.build // {inherit module;};
  inherit (eval) wrapper check configFile;

  # apps = let
  #   deploy = let
  #     name = "deploy-treefmt-config";
  #     value = let
  #       source = configFile;
  #       target = let
  #         name = ".treefmt.toml";
  #         path = "${flake.path}/${name}";
  #       in {inherit name path;};

  #       script = writeShellScriptBin name ''
  #         set -euo pipefail
  #         cp --force ${source} "${target.path}"
  #         chmod u+w "${target.path}"
  #         printf "Updated ${target.name} from Modules/global/shared/fmt\n"
  #       '';
  #     in {
  #       type = "app";
  #       program = "${script}/bin/${name}";
  #     };
  #   in {inherit name value;};
  # in {${deploy.name} = deploy.value;};
  apps = let
    deploy = let
      name = "deploy-treefmt-config";
      source = configFile;
      target = {
        path = "${flake.home}/${target.name}";
        name = ".treefmt.toml";
      };
      app = writeShellApplication {
        inherit name;
        text = ''
          cp --force ${source} "${target.path}"
          chmod u+w "${target.path}"
          printf "Updated ${target.name} from Modules/global/shared/fmt\n"
        '';
      };
    in {
      inherit name;
      value = {
        type = "app";
        program = "${app}/bin/${name}";
      };
    };
  in {${deploy.name} = deploy.value;};

  devShell = eval.devShell.overrideAttrs (old: {
    shellHook =
      (old.shellHook or "")
      + ''
        ${print.title "Formatter Environment"}
        ${print.table {
          columns = ["Formatter" "Version" "Path"];
          rows = let
            rest = sort (a: b: a < b) (filter (name: name != "treefmt") tool.names);
            names = ["treefmt"] ++ rest;
            row = name: let
              app = tool.of name;
            in [
              name
              (app.ver or "unknown")
              (app.exe or "-")
            ];
          in
            map row names;
        }}
      '';
  });
in {
  treefmt = eval.build // {inherit devShell;};
  inherit apps;
  formatter = wrapper;
  checks.formatting = check flake.path;
  formatters = tool.packages ++ [wrapper];
}
