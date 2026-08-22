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
  inherit (lix.attrsets.construction) genAttrs;
  inherit (lix.attrsets.transformation) filterAttrs;
  inherit (lix.filesystem.traversal) importAllPaths;
  inherit (lix.lists.predicates) elem;
  inherit (lix.lists.transformation) filter sort uniqueStrings;
  inherit (lix.modules.construction) mkForce;

  mkConfig = module: (evalModule pkgs (module // {projectRootFile = mkForce "flake.nix";})).config;
  dprintConfig = pkgs.writeText "dprint.json" (builtins.replaceStrings [
      "https://plugins.dprint.dev/json-0.23.0.wasm"
      "https://plugins.dprint.dev/markdown-0.22.1.wasm"
      "https://plugins.dprint.dev/g-plane/pretty_yaml-v0.6.0.wasm"
      "https://plugins.dprint.dev/g-plane/malva-v0.16.0.wasm"
    ] [
      "${pkgs.dprint-plugins.dprint-plugin-json}/plugin.wasm"
      "${pkgs.dprint-plugins.dprint-plugin-markdown}/plugin.wasm"
      "${pkgs.dprint-plugins.g-plane-pretty_yaml}/plugin.wasm"
      "${pkgs.dprint-plugins.g-plane-malva}/plugin.wasm"
    ] (builtins.readFile "${flake.path}/dprint.json"));
  extraSources = {
    treefmt = "treefmt";
    statix = "statix";
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
        inherit (utility) commands;
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
    programs = attrNames (filterAttrs (_: cfg: cfg.enable or false) (init.programs or {}));
    # packages = filter (name: !(elem name programs)) formatters;
    packages = map (name: (of name).pkg) (filter (name: !(elem name programs)) formatters);
    tools = uniqueStrings (formatters ++ programs ++ ["treefmt"]);

    resolved = pkgsFor {
      required = false;
      aliases = {
        ruff-check = "ruff";
        ruff-format = "ruff";
      };
      sources = genAttrs tools (_: null) // genAttrs ["ruff"] (_: null) // extraSources;
    };

    of = name: resolved.${name} or null;

    wrappers = let
      for = field:
        genAttrs (filter (name: name != "treefmt") tools) (
          name:
            if name == "statix"
            then {
              command = mkForce "sh";
              options = mkForce [
                "-c"
                ''for f in "$@"; do statix fix "$f"; done''
                "_"
              ];
            }
            else {
              command = mkForce ((of name).${field} or name);
            }
        );
    in {
      exe = for "exe";
      cmd = for "cmd";
    };
  in
    resolved
    // {
      inherit
        tools
        packages
        programs
        formatters
        of
        wrappers
        ;
      names = tools;
    };

  mkEval = wrappers: let
    module = {
      settings.formatter = recursiveUpdate wrappers {
        dprint.options = mkForce [
          "fmt"
          "--allow-no-files"
          "--config"
          "${dprintConfig}"
        ];
      };
    };

    config = mkConfig {
      imports = [
        init.module
        module
      ];
    };
  in
    config // config.build // {inherit module;};

  treefmt = let
    eval = mkEval tool.wrappers.exe;
    inherit (eval) build check wrapper;
    allTools = filter (p: p != null) (map (name: (tool.of name).pkg or null) (filter (name: name != "treefmt") tool.tools));
    withTools = drv:
      drv.overrideAttrs (old: {
        nativeBuildInputs = (old.nativeBuildInputs or []) ++ allTools;
      });
  in
    eval
    // build
    // {
      formatter = withTools wrapper;
      checks.formatting = withTools (check flake.path);
      # formatters = tool.packages ++ [wrapper];
      formatters = allTools;
      devShell = eval.devShell.overrideAttrs (old: {
        shellHook =
          (old.shellHook or "")
          + ''
            ${print.title "Formatter Environment"}
            ${print.table {
              columns = [
                "Formatter"
                "Version"
                "Path"
              ];
              rows = let
                names = ["treefmt"] ++ (sort (a: b: a < b) (filter (name: name != "treefmt") tool.names));
                by = name: let
                  app = tool.of name;
                in [
                  name
                  (app.ver or "unknown")
                  (app.exe or "-")
                ];
              in
                map by names;
            }}
          '';
      });
    };
in {
  inherit treefmt;
  apps = {};
  inherit (treefmt) formatter checks formatters;
  __debug = init.module; # temporary, for inspection
}
