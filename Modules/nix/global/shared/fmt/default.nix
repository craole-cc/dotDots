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
  inherit (lix.attrsets.access) attrNames attrValues;
  inherit (lix.attrsets.aggregation) recursiveUpdate;
  inherit (lix.attrsets.construction) genAttrs;
  inherit (lix.attrsets.transformation) filterAttrs;
  inherit (lix.filesystem.access) readFile;
  inherit (lix.filesystem.primitives) mkPath;
  inherit (lix.filesystem.traversal) importAllPaths;
  inherit (lix.lists.construction) concatLists;
  inherit (lix.lists.predicates) elem;
  inherit (lix.lists.transformation) filter sort uniqueStrings;
  inherit (lix.modules.construction) mkForce;
  inherit (lix.strings.transformation) replaceStrings;
  inherit (pkgs) dprint-plugins writeShellApplication writeText;

  mkConfig = module: let
    input =
      inputs.treeFormatter or (
        inputs.treefmtNix or inputs.treefmt
      );
    output =
      input.lib.evalModule or (
        throw "no treefmt-nix input found"
      );
  in
    (output pkgs module).config;

  sources = {
    alejandra = null;
    harper = null;
    ruff = null;
    shellcheck = null;
    shfmt = null;
    statix = null;
    tombi = null;
    treefmt = "treefmt";
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
      programs = {
        alejandra.enable = mkForce false;
        statix.enable = mkForce false;
        shellcheck.enable = mkForce false;
        shfmt.enable = mkForce false;
      };
      settings = {
        global.excludes = [
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
          "**/flint-*-tmp.*/**"
        ];
      };
    };
    config = mkConfig module;
  in
    config // config.build // {inherit module;};

  custom = let
    flint = let
      mkName = type: "flint-${type}";
      specs = {
        sh = {
          dependencies = with pkgs; [shellcheck shfmt];
          includes = ["*"];
          options = ["--detect-shell"];
        };
        nix = {
          dependencies = with pkgs; [alejandra statix];
          includes = ["*.nix"];
        };
      };
      names = map mkName (attrNames specs);

      dependencies = concatLists (
        map (name: specs.${name}.dependencies) names
      );

      packages = genAttrs names (name:
        writeShellApplication {
          inherit name;
          runtimeInputs =
            (with pkgs; [
              coreutils
              diffutils
              fd
              findutils
              gnupatch
              gnused
              mawk
              ripgrep
              sd
            ])
            ++ specs.${name}.dependencies;
          text =
            readFile
            (mkPath [
              "Libraries"
              "posix"
              "project"
              "formatters"
              name
            ]).store;
        });
      formatters = genAttrs names (name: let
        spec = specs.${name};
      in {
        command = "${packages.${name}}/bin/${name}";
        includes = spec.includes or [];
        excludes = spec.excludes or [];
        options = spec.options or [];
      });
    in {inherit packages formatters dependencies;};

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

      package = pkgs.dprint;
      formatter.dprint = {
        command = "${package}/bin/dprint";
        options = [
          "fmt"
          "--allow-no-files"
          "--config"
          "${writeText "dprint.json" (plugins path)}"
        ];
      };
    in {inherit package formatter;};
  in {
    packages = dprint.package // flint.packages;
    formatters = dprint.formatter // flint.formatters;
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
      sources =
        genAttrs tools (_: null)
        // genAttrs ["ruff"] (_: null)
        // sources;
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
    module.settings.formatter = recursiveUpdate wrappers custom.formatters;
    config = mkConfig {imports = [init.module module];};
  in
    config // config.build // {inherit module;};

  treefmt = let
    eval = mkEval tool.wrappers.exe;
    inherit (eval) build check wrapper;
    allTools =
      filter (pkg: pkg != null) (
        map
        (name: (tool.of name).pkg or null)
        (filter (name: name != "treefmt") tool.tools)
      )
      ++ attrValues custom.packages
      ++ custom.dependencies;
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
        nativeBuildInputs = (old.nativeBuildInputs or []) ++ allTools;
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
                  ++ sort (a: b: a < b) (uniqueStrings (
                    filter
                    (name: name != "treefmt")
                    (tool.names ++ attrNames custom.packages)
                  ));
                by = name: let
                  app = tool.of name;
                  pkg = custom.packages.${name} or null;
                in [
                  name
                  (app.ver or "unknown")
                  (app.exe or (
                    if pkg == null
                    then "-"
                    else "${pkg}/bin/${name}"
                  ))
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
