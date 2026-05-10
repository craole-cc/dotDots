{
  lib,
  paths,
  ...
}: let
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.packages) mkBin mkBins mkPkg;
  inherit (lib.shells) mkPackagesFrom;
  inherit (lib.strings) mkStyledOutput;
  templates = lib.templates.base;
in {
  mkBase = pkgs: let
    inherit (pkgs.stdenv) isLinux;
    packages = with pkgs; (
      {
        inherit
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
        inherit gcc rust-script;
      }
      // optionalAttrs isLinux {inherit wl-clipboard xclip xsel;}
    );

    bin = {
      packages = with pkgs; (
        mkBins packages
        // optionalAttrs isLinux {
          wl-copy = "${wl-clipboard}/bin/wl-copy";
          wl-paste = "${wl-clipboard}/bin/wl-paste";
        }
      );
      scripts = mkBins scripts;
      all = bin.packages // bin.scripts;
    };

    scripts = let
      auto =
        optionalAttrs (paths ? scripts.default)
        mkPackagesFrom {
          inherit pkgs;
          dir = paths.scripts.default;
        };
      commit = ''gcp --no-push "$@"'';
      manual = with bin.packages; {
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
          command = "${ripgrep-all} \"$@\"";
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
  in {inherit templates scripts packages;};
}
