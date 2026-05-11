{
  lib,
  paths,
  ...
}: let
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.packages) mkBins mkBin mkPkg mkPackages;
  inherit (lib.strings) mkStyledOutput;

  mkBase = {
    pkgs,
    variant ? {
      base = {
        enable = true;
        includeMise = false;
      };
    },
  }: let
    inherit (variant) base;
    inherit (pkgs.stdenv) isLinux;
  in (
    {kind = "base";}
    // optionalAttrs base.enable (let
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
        // optionalAttrs isLinux {inherit (pkgs) wl-clipboard xclip xsel;}
        // optionalAttrs base.includeMise {inherit (pkgs) mise;};

      binaries = {
        packages = with pkgs; (
          mkBins packages
          // optionalAttrs isLinux {
            wl-copy = "${wl-clipboard}/bin/wl-copy";
            wl-paste = "${wl-clipboard}/bin/wl-paste";
          }
        );
        scripts = mkBins scripts;
        all = binaries.packages // binaries.scripts;
      };

      scripts = let
        auto =
          optionalAttrs (paths ? scripts.default)
          mkPackages {
            inherit pkgs;
            dir = paths.scripts.default;
          };
        commit = ''gcp --no-push "$@"'';
        manual = with binaries.packages; {
          #~@ Clipboard
          clip = mkPkg {
            inherit pkgs;
            name = "clip";
            script = ''
              if [ -n "$WAYLAND_DISPLAY" ]; then
                exec ${wl-copy} "$@"
              elif [ -n "$DISPLAY" ]; then
                exec ${xclip} -selection clipboard "$@"
              else
                exec pbcopy "$@"
              fi
            '';
          };
          pilc = mkPkg {
            inherit pkgs;
            name = "pilc";
            script = ''
              if [ -n "$WAYLAND_DISPLAY" ]; then
                exec ${wl-paste} "$@"
              elif [ -n "$DISPLAY" ]; then
                exec ${xclip} -selection clipboard -o "$@"
              else
                exec pbpaste "$@"
              fi
            '';
          };

          #~@ Project
          glog = mkPkg {
            inherit pkgs;
            name = "glog";
            command = "git log -1 --pretty=%B";
          };
          reload = mkPkg {
            inherit pkgs;
            name = "reload";
            command = "${commit}; ${direnv} reload";
          };
          format = mkPkg {
            inherit pkgs;
            name = "format";
            command = "${commit}; nix fmt";
          };
          rg = mkPkg {
            inherit pkgs;
            name = "rg";
            command = "${binaries.packages.ripgrep-all} \"$@\"";
          };
          ff = mkPkg {
            inherit pkgs;
            name = "ff";
            command = "${fd} --absolute-path \"$@\"";
          };

          #~@ Script Helpers
          find_cmd = mkPkg {
            inherit pkgs;
            name = "find_cmd";
            script = ''command -v "$1" 2>/dev/null || true'';
          };
          require_cmd = mkPkg {
            inherit pkgs;
            name = "require_cmd";
            script = ''
              cmd="$(command -v "$1" 2>/dev/null || true)"
              [ -n "''${cmd}" ] || {
                printf 'Error: required command not found: %s\n' "$1" >&2
                exit 1
              }
              printf '%s' "''${cmd}"
            '';
          };
          is_true = mkPkg {
            inherit pkgs;
            name = "is_true";
            script = ''
              case "$(printf '%s' "''${1:-}" | tr '[:upper:]' '[:lower:]')" in
              1 | yes | true | on | enable*) exit 0 ;;
              *) exit 1 ;;
              esac
            '';
          };
        };

        printers = mkBin {
          inherit pkgs;
          prefix = "print";
          sep = "_";
          set = mkStyledOutput {inherit pkgs;};
        };
      in
        auto // manual // printers;
    in {inherit packages binaries scripts;})
  );
in {inherit mkBase;}
