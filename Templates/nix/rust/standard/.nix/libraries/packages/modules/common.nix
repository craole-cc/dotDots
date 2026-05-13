{
  lib,
  paths,
  ...
}: let
  inherit (lib.attrsets) attrValues  optionalAttrs recursiveUpdate;
  inherit (lib.packages) mkBins mkBin mkPkg mkPackages;
  inherit (lib.strings) mkStyledOutput;
in {
  mkCommon = {
    pkgs,
    variant ? {},
  }: let
    cfg =
      recursiveUpdate {
        kind = "core";
        name = "common";
        enable = true;
      }
      (optionalAttrs (variant ? common) variant.common);
  in
    {configuration = cfg;}
    // optionalAttrs cfg.enable (let
      packages = let
        inherit (pkgs.stdenv) isLinux isDarwin;
        common = with pkgs;
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
              ripgrep
              sd
              trashy
              undollar
              watchexec
              ;
          }
          // optionalAttrs isDarwin {inherit libiconv;}
          // optionalAttrs isLinux {inherit wl-clipboard xclip xsel;};

        custom = let
          auto =
            optionalAttrs (paths ? scripts.default)
            (mkPackages {
              inherit pkgs;
              dir = paths.scripts.default;
              priority = ["sh" "bash" "py" "rb"];
            });
          manual = with binaries.common; {
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
              command = ''${direnv} reload'';
            };
            repl = mkPkg {
              inherit pkgs;
              name = "repl";
              command = ''
                nix repl .
              '';
            };
            check = mkPkg {
              inherit pkgs;
              name = "check";
              command = ''nix flake check'';
            };
            check-all = mkPkg {
              inherit pkgs;
              name = "check-all";
              command = ''nix flake check --keep-going --all-systems'';
            };
            format = mkPkg {
              inherit pkgs;
              name = "format";
              command = ''nix fmt'';
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
        all = attrValues common ++ attrValues custom;
      in {inherit all common custom;};

      binaries = let
        common = with pkgs; (
          mkBins packages.common
          // optionalAttrs isLinux {
            wl-copy = "${wl-clipboard}/bin/wl-copy";
            wl-paste = "${wl-clipboard}/bin/wl-paste";
            ripgrep--all = "${ripgrep-all}/bin/rga";
          }
        );
        custom = mkBins packages.custom;
        all = common // custom;
      in {inherit all common custom;};

      variables = {};
    in {inherit variables packages binaries;});
}
