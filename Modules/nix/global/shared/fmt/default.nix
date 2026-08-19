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
      sources = resolved;
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

  devShell = eval.devShell; #TODO: Update shellHook to should formatter info
  # devShell = eval.devShell.overrideAttrs (old: let
  #   inherit (sources) treefmt;
  #   version = let
  #     rev = treefmt.revision;
  #   in
  #     if rev != null
  #     then "$(${treefmt.paths.exe} --version | ${pkgs.gawk}/bin/awk '{print $2}') (${rev})"
  #     else "unknown";
  #   programNames = attrNames args.programs;
  #   fromPrograms =
  #     map (name: [name (args.programs.${name}.version or "unknown")])
  #     programNames;
  #   fromPackages =
  #     map (pkg: [(pkg.pname or pkg.name or "unknown") (pkg.version or "unknown")])
  #     (filter (
  #         pkg: let
  #           n = toLower (pkg.pname or pkg.name or "");
  #         in
  #           n
  #           != ""
  #           && n != "treefmt"
  #           && n != "git"
  #           && !(elem n (map toLower programNames))
  #       )
  #       args.packages);
  #   formatters = let
  #     rest = fromPrograms ++ fromPackages;
  #     sorted =
  #       sort
  #       (a: b: (elemAt a 0) < (elemAt b 0))
  #       rest;
  #   in
  #     [["treefmt" version]]
  #     ++ (
  #       sort
  #       (a: b: (elemAt a 0) < (elemAt b 0))
  #       (map (name: [name (args.programs.${name}.version or "unknown")])
  #         programNames)
  #     );
  # in {
  #   shellHook =
  #     (old.shellHook or "")
  #     + ''
  #       ${print.title "Formatter Environment"}
  #       ${print.table {
  #         columns = ["Formatter" "Version"];
  #         rows = formatters;
  #       }}
  #     '';
  # });
  # shell = devShell.overrideAttrs (old: let
  #   inherit (args.sources) treefmt;
  #   version = let
  #     rev = treefmt.revision;
  #   in
  #     if rev != null
  #     then "$(${treefmt.paths.exe} --version | ${pkgs.gawk}/bin/awk '{print $2}') (${rev})"
  #     else "unknown";
  #   programNames = attrNames args.programs;
  #   fromPrograms =
  #     map (name: [name (args.programs.${name}.version or "unknown")])
  #     programNames;
  #   fromPackages =
  #     map (pkg: [(pkg.pname or pkg.name or "unknown") (pkg.version or "unknown")])
  #     (filter (
  #         pkg: let
  #           n = toLower (pkg.pname or pkg.name or "");
  #         in
  #           n
  #           != ""
  #           && n != "treefmt"
  #           && n != "git"
  #           && !(elem n (map toLower programNames))
  #       )
  #       args.packages);
  #   formatters = let
  #     rest = fromPrograms ++ fromPackages;
  #     sorted =
  #       sort
  #       (a: b: (elemAt a 0) < (elemAt b 0))
  #       rest;
  #   in
  #     [["treefmt" version]] ++ sorted;
  # in {
  #   shellHook =
  #     (old.shellHook or "")
  #     + ''
  #       ${print.title "Formatter Environment"}
  #       ${print.table {
  #         columns = ["Formatter" "Version"];
  #         rows = formatters;
  #       }}
  #     '';
  # });
  # sources' = removeAttrs sources ["git" ""];
  # packages' =
  #   filter (
  #     pkg: let
  #       name = toLower (pkg.pname or pkg.name or "");
  #     in
  #       (name != "")
  #       && name != "treefmt"
  #       && name != "git"
  #       && !(elem name (map toLower (attrNames packages)))
  #   )
  #   packages;
  # binaries' = mapAttrs (_: pkg: pkg.paths.exe) resolved;
  # commands = mapAttrs (_: pkg: pkg.cmd) resolved;
  # fmt = args.devShell.overrideAttrs (old: let
  #   inherit (args.sources) treefmt;
  #   version = let
  #     rev = treefmt.revision;
  #   in
  #     if rev != null
  #     then "$(${treefmt.paths.exe} --version | ${pkgs.gawk}/bin/awk '{print $2}') (${rev})"
  #     else "unknown";
  #   programNames = attrNames args.programs;
  #   fromPrograms =
  #     map (name: [name (args.programs.${name}.version or "unknown")])
  #     programNames;
  #   fromPackages =
  #     map (pkg: [(pkg.pname or pkg.name or "unknown") (pkg.version or "unknown")])
  #     (filter (
  #         pkg: let
  #           n = toLower (pkg.pname or pkg.name or "");
  #         in
  #           n
  #           != ""
  #           && n != "treefmt"
  #           && n != "git"
  #           && !(elem n (map toLower programNames))
  #       )
  #       args.packages);
  #   formatters = let
  #     rest = fromPrograms ++ fromPackages;
  #     sorted =
  #       sort
  #       (a: b: (elemAt a 0) < (elemAt b 0))
  #       rest;
  #   in
  #     [["treefmt" version]] ++ sorted;
  # in {
  #   shellHook =
  #     (old.shellHook or "")
  #     + ''
  #       ${print.title "Formatter Environment"}
  #       ${print.table {
  #         columns = ["Formatter" "Version"];
  #         rows = formatters;
  #       }}
  #     '';
  # });
in {
  treefmt = eval // {inherit devShell;};
  inherit apps;
  formatter = wrapper;
  checks.formatting = check flake.path;
  # formatters = (attrValues treefmt.programs) ++ [formatter];
  # formatters = names.formatters ++ [wrapper];
}
