{
  lix,
  pkgs,
  inputs ? {},
  paths,
  pkgsFor,
  print,
  ...
}: let
  inherit inputs;
  treefmtInput = inputs.treeFormatter or (inputs.treefmtNix or inputs.treefmt);
  inherit (treefmtInput.lib) evalModule;
  inherit (lix.attrsets.access) attrNames;
  inherit (lix.attrsets.aggregation) recursiveUpdate;
  inherit (lix.attrsets.construction) genAttrs;
  inherit (lix.attrsets.transformation) filterAttrs;
  inherit (lix.filesystem.access) readFile;
  inherit (lix.filesystem.primitives) mkPath;
  inherit (lix.filesystem.traversal) importAllPaths;
  inherit (lix.lists.predicates) elem;
  inherit (lix.lists.transformation) filter sort uniqueStrings;
  inherit (lix.modules.construction) mkForce;
  inherit (lix.strings.transformation) replaceStrings;
  inherit (pkgs) dprint-plugins writeShellApplication writeText;

  mkConfig = module:
    (evalModule pkgs module).config;

  sources = {
    treefmt = "treefmt";
    statix = null;
    harper = null;
    tombi = null;
    ruff = null;
  };
  utils = pkgsFor {
    inherit sources;
    extraSources = {
      fd = null;
      ripgrep = null;
      sd = null;
      mawk = null;
      git = null;
    };
  };

  #~@ Nix-side eval: store-path commands, used by `nix fmt`.
  init = let
    module = {
      _module.args = {inherit lix;} // utils;
      imports = (importAllPaths ./.).value;
      projectRootFile = "flake.nix";

      # flint-nix (alejandra + statix, see `custom` below) replaces the stock
      # nix formatters so the two tools don't run twice over the same files.
      programs.alejandra.enable = mkForce false;
      programs.statix.enable = mkForce false;

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
        # scratch dirs created next to each file by flint-nix / flint-sh
        "**/flint-*-tmp.*/**"
      ];
    };
    config = mkConfig module;
  in
    config // config.build // {inherit module;};

  custom = let
    # Wrap a script from Libraries/posix/project/formatters/<name>.
    # writeShellApplication puts runtimeInputs on PATH and shellchecks the text.
    mkFlint = {
      name,
      runtimeInputs,
    }:
      writeShellApplication {
        inherit name;
        runtimeInputs =
          (with pkgs; [
            coreutils
            diffutils
            findutils
            gnused
          ])
          ++ runtimeInputs;
        text =
          readFile
          (mkPath [
            "Libraries"
            "posix"
            "project"
            "formatters"
            name
          ]).store;
      };
  in {
    dprint = let
      stem = ["Configuration" "dprint" "config.jsonc"];
      path = readFile (mkPath stem).store;
      plugins =
        replaceStrings [
          "https://plugins.dprint.dev/json-0.23.0.wasm"
          "https://plugins.dprint.dev/markdown-0.22.1.wasm"
          "https://plugins.dprint.dev/g-plane/pretty_yaml-v0.6.0.wasm"
          "https://plugins.dprint.dev/g-plane/malva-v0.16.0.wasm"
        ] (with dprint-plugins; [
          "${dprint-plugin-json}/plugin.wasm"
          "${dprint-plugin-markdown}/plugin.wasm"
          "${g-plane-pretty_yaml}/plugin.wasm"
          "${g-plane-malva}/plugin.wasm"
        ]);
    in {
      options = mkForce [
        "fmt"
        "--allow-no-files"
        "--config"
        "${(writeText "dprint.json" (plugins path))}"
      ];
    };
    flint-sh = mkFlint {
      name = "flint-sh";
      runtimeInputs = with pkgs; [
        fd
        gnupatch
        mawk
        ripgrep
        sd
        shellcheck
        shfmt
      ];
    };
    flint-nix = mkFlint {
      name = "flint-nix";
      runtimeInputs = with pkgs; [
        alejandra
        fd
        statix
      ];
    };
  };

  tool = let
    formatters = attrNames (init.settings.formatter or {});
    programs = attrNames (
      filterAttrs
      (_: cfg: cfg.enable or false)
      (init.programs or {})
    );
    packages = map (name: (of name).pkg) (
      filter
      (name: !(elem name programs))
      formatters
    );
    tools = uniqueStrings (formatters ++ programs ++ ["treefmt"]);

    resolved = pkgsFor {
      required = false;
      aliases = {
        ruff-check = "ruff";
        ruff-format = "ruff";
      };
      sources = genAttrs tools (_: null) // genAttrs ["ruff"] (_: null) // sources;
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
    module.settings.formatter = recursiveUpdate wrappers {
      inherit (custom) dprint;
      flint-nix = {
        command = "${custom.flint-nix}/bin/flint-nix";
        includes = ["*.nix"];
        options = [];
      };
    };
    config = mkConfig {imports = [init.module module];};
  in
    config // config.build // {inherit module;};

  treefmt = let
    eval = mkEval tool.wrappers.exe;
    inherit (eval) build check wrapper;
    allTools = filter (pkg: pkg != null) (
      map
      (name: (tool.of name).pkg or null)
      (filter (name: name != "treefmt") tool.tools)
    );
    withTools = drv:
      drv.overrideAttrs (old: {
        nativeBuildInputs = (old.nativeBuildInputs or []) ++ allTools;
      });
  in
    eval
    // build
    // {
      formatter = withTools wrapper;
      checks.formatting = withTools (check paths.store.src);
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
                names =
                  ["treefmt"]
                  ++ (
                    sort (a: b: a < b)
                    (filter (name: name != "treefmt") tool.names)
                  );
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
}
