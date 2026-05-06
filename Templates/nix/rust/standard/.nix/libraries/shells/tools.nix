{
  lib,
  paths,
  ...
}: let
  inherit (lib.attrsets) attrValues optionalAttrs;
  inherit (lib.lists) concatMap flatten;
  inherit (lib.packages) mkBin mkBins mkPkgs;
  inherit (lib.shells) mkPackagesFrom;
  inherit (lib.strings) mkStyledOutput;

  /**
    Build a unified tool environment for dev shells.

    Produces `packages` (a list of derivations placed on PATH) from three
    optional groups — essential, web, and editor — each controlled by an
    `include*` flag. All commands are proper scripts, no aliases needed.

    # Type
  ```nix
    mkTools :: {
      pkgs          :: AttrSet;
      includeEditor :: bool;
      includeWeb    :: bool;
      includeExtras   :: bool;
    } -> {
      packages :: [derivation];
      style    :: AttrSet;
    }
  ```

    # Examples
  ```nix
    tools = mkTools { inherit pkgs; includeWeb = true; };
    # tools.packages — add to shell packages list
    # tools.style    — gum-based styled output helpers
  ```
  */
  mkTools = {
    pkgs ? mkPkgs {},
    channel ? "nightly",
    includeExtras ? false,
    includeEditor ? false,
    includeWeb ? false,
    includeAnalytics ? false,
    includeWorkflow ? false,
  }: let
    inherit (pkgs.stdenv) isLinux;

    shBin = pkgs.writeShellScriptBin;
    style = mkStyledOutput {inherit pkgs;};
    groups = {
      /**
      Core essential/navigation/git/file tooling.

      Scripts are built in two passes: `bin` is first resolved from
      packages, then augmented with sibling script paths via `mkBins
      scripts`, allowing scripts to reference each other by name.
      */
      essential = let
        packages =
          {
            inherit
              (pkgs)
              bat
              direnv
              fd
              git
              gnused
              gum
              jq
              nixd
              ripgrep-all
              sd
              trashy
              undollar
              ;
            inherit (pkgs) gcc rust-script;
          }
          // optionalAttrs isLinux {inherit (pkgs) wl-clipboard xclip xsel;};

        bin = {
          packages =
            mkBins packages
            // optionalAttrs isLinux {
              wl-copy = "${pkgs.wl-clipboard}/bin/wl-copy";
              wl-paste = "${pkgs.wl-clipboard}/bin/wl-paste";
            };
          scripts = mkBins scripts;
          all = bin.packages // bin.scripts;
        };

        scripts = let
          auto =
            if paths ? scripts && paths.scripts ? default
            then
              mkPackagesFrom {
                inherit pkgs;
                dir = paths.scripts.default;
              }
            else {};
          commit = ''gcp --no-push "$@"'';
          manual = with bin.packages; {
            #~@ Clipboard
            clip = shBin "clip" ''
              if [ -n "$WAYLAND_DISPLAY" ]; then
                exec ${wl-copy} "$@"
              elif [ -n "$DISPLAY" ]; then
                exec ${xclip} -selection clipboard "$@"
              else
                exec pbcopy "$@"
              fi
            '';
            pilc = shBin "pilc" ''
              if [ -n "$WAYLAND_DISPLAY" ]; then
                exec ${wl-paste} "$@"
              elif [ -n "$DISPLAY" ]; then
                exec ${xclip} -selection clipboard -o "$@"
              else
                exec pbpaste "$@"
              fi'';

            #~@ Project
            glog = shBin "glog" ''git log -1 --pretty=%B'';
            reload = shBin "reload" ''${commit}; ${direnv} reload'';
            format = shBin "format" ''${commit}; nix fmt'';
            rg = shBin "rg" ''${ripgrep-all} "$@"'';
            ff = shBin "ff" ''${fd} --absolute-path "$@"'';

            #~@ Script Helpers
            find_cmd = shBin "find_cmd" ''
              command -v "$1" 2>/dev/null || true
            '';
            require_cmd = shBin "require_cmd" ''
              cmd="$(command -v "$1" 2>/dev/null || true)"
              [ -n "''${cmd}" ] || {
                printf 'Error: required command not found: %s\n' "$1" >&2
                exit 1
              }
              printf '%s' "''${cmd}"
            '';
            is_true = shBin "is_true" ''
              case "$(printf '%s' "''${1:-}" | tr '[:upper:]' '[:lower:]')" in
              1 | yes | true | on | enable*) exit 0 ;;
              *) exit 1 ;;
              esac
            '';
          };

          printers = mkBin {
            inherit pkgs;
            prefix = "print";
            sep = "_";
            set = style;
          };
        in
          auto // manual // printers;
      in {inherit scripts packages;};

      /**
      Core essential/navigation/git/file tooling.

      Scripts are built in two passes: `bin` is first resolved from
      packages, then augmented with sibling script paths via `mkBins
      scripts`, allowing scripts to reference each other by name.
      */
      extra = optionalAttrs includeExtras (
        let
          packages = {
            inherit
              (pkgs)
              fastfetch
              gitui
              helix
              lsd
              microfetch
              mise
              nitch
              nixd
              onefetch
              tokei
              ;
          };

          bin = {
            packages = mkBins packages;
            scripts = mkBins scripts;
            all = bin.packages // bin.scripts;
          };

          scripts = with bin; {
            #~@ Navigation
            fetch = shBin "fetch" ''${fastfetch} "$@"'';
            ls = shBin "ls" ''${lsd} "$@"'';
            ll = shBin "ll" ''${lsd} --long --git --almost-all "$@"'';
            lt = shBin "lt" ''${lsd} --tree "$@"'';
            lr = shBin "lr" ''${lsd} --long --git --recursive "$@"'';

            #~@ Project Info
            prjfo = shBin "prjfo" ''
              ${tokei}
              ${onefetch} \
                --no-art \
                --no-title \
                --no-color-palette \
                --nerd-fonts \
                --hide-token \
                --number-separator comma
              ${microfetch}
            '';

            #~@ Git
            gt = shBin "gt" ''${gitui} "$@"'';
          };
        in {inherit scripts packages;}
      );

      /**
      Web development tooling: Deno, Node and Prettier.
      Enabled when `includeWeb = true`.
      */
      web = optionalAttrs includeWeb {
        packages = {inherit (pkgs) deno pnpm prettierd;};
      };

      /**
      Editor tooling: Helix.
      Enabled when `includeEditor = true`.
      */
      editor = optionalAttrs includeEditor {
        packages = {inherit (pkgs) helix;};
      };
    };
  in {
    inherit style;
    packages = flatten (
      concatMap
      (g:
        attrValues (g.packages or {})
        ++ attrValues (g.scripts or {}))
      (attrValues groups)
    );
  };
in {inherit mkTools;}
