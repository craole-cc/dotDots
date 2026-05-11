{
  lib,
  paths,
  ...
}: let
  inherit (lib.attrsets) attrValues optionalAttrs;
  inherit (lib.packages) mkBins mkBin mkPkg mkPackages;
  inherit (lib.strings) mkStyledOutput;
in {
  mkCommon = {
    pkgs,
    variant ? {common.enable = true;},
  }: let
    cfg = variant.common;
    inherit (pkgs.stdenv) isLinux;
  in
    {
      kind = "common";
      all = [];
    }
    // optionalAttrs cfg.enable (let
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
            ripgrep
            sd
            trashy
            undollar
            watchexec
            ;
        }
        // optionalAttrs isLinux {inherit (pkgs) wl-clipboard xclip xsel;};

      binaries = {
        packages = with pkgs; (
          mkBins packages
          // optionalAttrs isLinux {
            wl-copy = "${wl-clipboard}/bin/wl-copy";
            wl-paste = "${wl-clipboard}/bin/wl-paste";
            ripgrep--all = "${ripgrep-all}/bin/rga";
          }
        );
        scripts = mkBins scripts;
        all = binaries.packages // binaries.scripts;
      };

      scripts = let
        auto =
          optionalAttrs (paths ? scripts.default)
          (mkPackages {
            inherit pkgs;
            dir = paths.scripts.default;
            priority = ["sh" "bash" "py" "rb"];
          });
        commit = ''gcp --no-push "$@" || true'';
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
          wl-copy = mkPkg {
            inherit pkgs;
            name = "wl-copy";
            command = wl-copy;
          };
          wl-paste = mkPkg {
            inherit pkgs;
            name = "wl-paste";
            command = wl-paste;
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
            command = ''
              gcp --no-push
              ${direnv} reload
            '';
          };
          check = mkPkg {
            inherit pkgs;
            name = "check";
            command = "${commit}; nix flake check";
          };
          format = mkPkg {
            inherit pkgs;
            name = "format";
            command = "${commit}; nix fmt";
          };
          ff = mkPkg {
            inherit pkgs;
            name = "ff";
            command = "${fd} --hidden";
          };
          fa = mkPkg {
            inherit pkgs;
            name = "fa";
            command = "${fd} --absolute-path --hidden";
          };
          rga = mkPkg {
            inherit pkgs;
            name = "rga";
            command = "${ripgrep--all} --hidden";
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
          sep = "-";
          set = mkStyledOutput {inherit pkgs;};
        };
      in
        auto // manual // printers;
      all = attrValues packages ++ attrValues scripts;
    in {inherit all packages binaries scripts;});
}
