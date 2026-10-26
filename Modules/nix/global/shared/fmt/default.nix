{
  lix,
  pkgs,
  inputs ? {},
  paths,
  pkgsFor,
  print,
  ...
}: let
  inherit (lix.attrsets.access) attrNames attrValues;
  inherit (lix.attrsets.aggregation) mergeSafe recursiveUpdate;
  inherit (lix.attrsets.construction) genAttrs;
  inherit (lix.attrsets.transformation) filterAttrs mapAttrs;
  inherit (lix.filesystem.access) readFile;
  inherit (lix.filesystem.primitives) concat;
  inherit (lix.filesystem.traversal) importAllPaths;
  inherit (lix.lists.construction) concatLists;
  inherit (lix.lists.predicates) elem;
  inherit (lix.lists.transformation) filter sort uniqueStrings;
  inherit (lix.modules.construction) mkForce;
  inherit (lix.sources.access) getExe;
  inherit (lix.strings.transformation) replaceStrings;
  inherit (pkgs) dprint-plugins writeShellApplication writeText;
  paths' = paths.store;

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

  #~@ Tools resolved through pkgsFor (name -> input, null = nixpkgs)
  sources = {
    alejandra = null;
    dprint = null;
    harper = null;
    ruff = null;
    rumdl = null;
    shellcheck = null;
    shfmt = null;
    statix = null;
    tombi = null;
    treefmt = "treefmt";
  };

  #~@ Tools the flint scripts need at runtime
  runtimeNames = [
    "coreutils"
    "diffutils"
    "fd"
    "findutils"
    "gnupatch"
    "gnused"
    "mawk"
    "ripgrep"
    "sd"
  ];

  utils = pkgsFor {
    inherit sources;
    extraSources =
      genAttrs runtimeNames (_: null)
      // {git = null;};
  };

  specs = {
    excludes = [
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
      "secrets.yaml"
      "**/secrets.yaml"
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

    #~@ Each entry becomes a `flint-<name>` formatter.
    #~@ `dependencies` are names that must exist in `sources` above.
    domains = {
      sh = {
        dependencies = ["shellcheck" "shfmt"];
        includes = [
          "Libraries/posix/**"
          "**/posix/**"
          "**/bash/**"
          "**/sh/**"
          "**/shellscript/**"
          "*.sh"
          "*.bash"
        ];
        excludes = [
          #~@ Other languages and docs that live inside the shell directories
          "*.md"
          "*.nix"
          "*.json"
          "*.jsonc"
          "*.toml"
          "*.yaml"
          "*.yml"
          "*.txt"
          "*.py"
          "*.rs"
          "*.js"
          "*.ts"
          "*.ps1"
          "*.bat"
          "*.cmd"
          "*.lock"
          #> Patch artefacts and backups of non-shell files.
          #? `.orig`, `.bak` and ` copy` are left in on purpose, since
          #? some are real shell scripts.
          "*.rej"
          "*.diff"
          "*.patch"
          "*.nix.*"
          "*.md.*"
        ];
        options = ["--detect-shell"];
      };
    };
  };

  #~@ Nix-side eval: store-path commands, used by `nix fmt`.
  init = let
    flake.path = paths.store.src;
    module = {
      _module.args = {inherit flake lix;} // utils;
      imports = (importAllPaths ./.).value;
      projectRootFile = "flake.nix";
      programs = {
      };
      settings.global = {inherit (specs) excludes;};
    };
    config = mkConfig module;
  in
    config // config.build // {inherit module;};

  custom = let
    flint = let
      inherit (specs) domains;
      mkName = type: "flint-${type}";
      types = attrNames domains;

      resolve = names: map (name: utils.records.${name}.package) names;
      deps = genAttrs types (type: resolve domains.${type}.dependencies);
      dependencies = concatLists (attrValues deps);
      runtimeInputs = resolve runtimeNames;

      packages = genAttrs types (type: let
        name = mkName type;
      in
        writeShellApplication {
          inherit name;
          runtimeInputs = runtimeInputs ++ deps.${type};

          text = readFile (concat {
            root = paths'.lib.sh;
            stem = ["project" "formatters" name];
          });
        });

      #> type -> executable path
      exes = mapAttrs (_: getExe) packages;

      formatters = genAttrs types (type: let
        spec = domains.${type};
      in {
        command = exes.${type};
        includes = spec.includes or [];
        excludes = spec.excludes or [];
        options = spec.options or [];
      });
    in {inherit packages formatters dependencies exes;};

    dprint = let
      content = readFile (concat {
        root = paths'.cfg.default;
        stem = ["dprint" "config.jsonc"];
      });
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

      package = utils.records.dprint.package;
      formatter.dprint = {
        command = utils.records.dprint.exe;
        options = mkForce [
          "fmt"
          "--allow-no-files"
          "--config"
          "${writeText "dprint.json" (plugins content)}"
        ];
      };
    in {inherit package formatter;};
  in {
    formatters = mergeSafe [
      dprint.formatter
      flint.formatters
      {
        rumdl = {
          command = utils.records.rumdl.exe;
          options = ["fmt"];
          includes = ["*.md" "**/*.md"];
        };
      }
      {
        statix.priority = mkForce 11;
        alejandra.priority = mkForce 12;
        #~@ The standalone checkers only get files with a shell extension, which
        #~@ are always valid shell. flint-sh covers shebang-only scripts through
        #~@ --detect-shell, so nothing non-shell can reach shellcheck or shfmt.
        shellcheck = {
          priority = mkForce 21;
          includes = mkForce ["*.sh" "*.bash"];
        };
        shfmt = {
          priority = mkForce 22;
          includes = mkForce ["*.sh" "*.bash"];
        };
      }
    ];
    inherit (flint) packages dependencies exes;
  };

  tool = let
    formatters = attrNames (init.settings.formatter or {});
    programs = attrNames (
      filterAttrs
      (_: cfg: cfg.enable or false)
      (init.programs or {})
    );
    packages = map (name: (of name).package) (
      filter
      (name: !(elem name programs))
      formatters
    );
    names = uniqueStrings (formatters ++ programs ++ ["treefmt"]);

    resolved = pkgsFor {
      required = false;
      aliases = {
        ruff-check = "ruff";
        ruff-format = "ruff";
      };
      sources =
        genAttrs names (_: null)
        // genAttrs ["ruff"] (_: null)
        // sources;
    };

    of = name: resolved.records.${name} or null;

    wrappers = let
      for = field:
        genAttrs (filter (name: name != "treefmt") names) (
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
            else {command = mkForce ((of name).${field} or name);}
        );
    in {
      exe = for "exe";
      cmd = for "cmd";
    };
  in
    resolved
    // {inherit names packages programs formatters of wrappers;};

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
        (name: (tool.of name).package or null)
        (filter (name: name != "treefmt") tool.names)
      )
      ++ attrValues custom.packages
      ++ custom.dependencies
      ++ [utils.records.rumdl.package];
    withTools = drv:
      drv.overrideAttrs (old: {
        nativeBuildInputs = (old.nativeBuildInputs or []) ++ allTools;
      });
  in
    eval
    // build
    // {
      formatter = withTools wrapper;
      checks.formatting = withTools (check paths'.src);
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
                in [
                  name
                  (app.ver or "unknown")
                  (app.exe or (custom.exes.${name} or "-"))
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
