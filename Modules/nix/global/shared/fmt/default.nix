{
  lix,
  pkgs,
  flake,
  pkgsFor,
  sources,
  ...
}: let
  inherit (flake) inputs;
  inherit (inputs.treefmt.lib) evalModule;
  inherit (lix.attrsets.access) attrNames;
  inherit (lix.attrsets.aggregation) recursiveUpdate;
  inherit (lix.attrsets.construction) genAttrs;
  inherit (lix.attrsets.transformation) mapAttrs filterAttrs;
  inherit (lix.lists.transformation) filter reverseList sort uniqueStrings;
  inherit (lix.strings.transformation) toLower;
  inherit (lix.modules.construction) mkForce;
  inherit (pkgs) writeShellScriptBin;
  inherit (lix.lists.access) elemAt;
  # inherit (lix.lists.aggregation) concatMap foldl';
  # inherit (lix.lists.construction) optionals;
  inherit (lix.lists.predicates) elem;
  inherit (lix.sources.packages) pkgsFrom;

  mkConfig = module: (evalModule pkgs module).config;
  extraSources = {
    treefmt = "treefmt";
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
  in
    mkConfig module;

  tool = let
    formatters = attrNames (init.module.settings.formatter or {});
    programs = attrNames (
      filterAttrs (_: cfg: cfg.enable or false) (init.module.programs or {})
    );
    packages = filter (name: !(elem name programs)) formatters;
    tools = uniqueStrings (formatters ++ programs);

    resolved = pkgsFor {
      sources = extraSources // (genAttrs tools (name: null));
    };
  in
    resolved
    // {
      inherit tools;
      names = tools;
      wrappers =
        recursiveUpdate
        (genAttrs programs (name: {command = mkForce name;}))
        (genAttrs packages (name: {command = mkForce resolved.cmds.${name};}));
    };

  eval = let
    module = {
      settings.formatter = recursiveUpdate tool.commands {
        dprint.options = mkForce [
          "fmt"
          "--allow-no-files"
          "--config"
          "dprint.json"
        ];
      };
    };
  in
    mkConfig {module.imports = [init.module module];};

  inherit (eval.build) wrapper check configFile;

  apps = let
    deploy = let
      name = "deploy-treefmt-config";
      value = let
        source = configFile;
        target = let
          name = ".treefmt.toml";
          path = "${flake.path}/${name}";
        in {inherit name path;};

        script = writeShellScriptBin name ''
          set -euo pipefail
          cp --force ${source} "${target.path}"
          chmod u+w "${target.path}"
          printf "Updated ${target.name} from Modules/global/shared/fmt\n"
        '';
      in {
        type = "app";
        program = "${script}/bin/${name}";
      };
    in {inherit name value;};
  in {${deploy.name} = deploy.value;};
in {
  treefmt = init;
  # treefmt = init // {inherit devShell;};
  inherit apps;
  formatter = wrapper;
  checks.formatting = check flake.path;
  formatters = tool.names ++ [wrapper];
  # formatters = names.formatters ++ [wrapper];
}
