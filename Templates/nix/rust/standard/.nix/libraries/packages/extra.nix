{
  lib,
  paths,
  ...
}: let
  inherit (lib.attrsets) attrValues optionalAttrs;
  inherit (lib.packages) mkBins mkPkg mkPackages;
in {
  mkExtra = {
    pkgs,
    variant ? {
      extra = {
        enable = false;
        includeMise = false;
        includeFetch = false;
        includeGitTools = false;
        includeFileTools = false;
        includeRustScript = false;
      };
    },
  }: let
    cfg = variant.extra;
  in {
      kind = "extra";
      all = [];
    }
    // optionalAttrs cfg.enable (let
      packages = with pkgs; (
        {}
        // optionalAttrs cfg.includeRustScript {inherit cargo rust-script gcc;}
        // optionalAttrs cfg.includeMise {inherit mise;}
        // optionalAttrs cfg.includeFetch {inherit fastfetch microfetch nitch tokei onefetch;}
        // optionalAttrs cfg.includeGitTools {inherit gitui gh jj;}
        // optionalAttrs cfg.includeFileTools {inherit lsd;}
      );

      binaries = {
        packages = mkBins packages;
        scripts = mkBins scripts;
        all = binaries.packages // binaries.scripts;
      };

      scripts =
        #? Re-discover common scripts with rs support when rust-script is available
        optionalAttrs (cfg.includeRustScript && (paths ? scripts.default))
        (mkPackages {
          inherit pkgs;
          dir = paths.scripts.default;
          priority = ["rs" "sh" "bash" "py" "rb"];
        })
        // (
          with binaries.packages;
            {}
            // optionalAttrs cfg.includeFetch {
              fetch = mkPkg {
                inherit pkgs;
                name = "fetch";
                script = ''
                  if [ -f "$HOME/.config/fastfetch/config.jsonc" ]; then
                    exec ${fastfetch} --config "$HOME/.config/fastfetch/config.jsonc" "$@"
                  else
                    exec ${fastfetch} --config all "$@"
                  fi
                '';
              };
              prjfo = mkPkg {
                inherit pkgs;
                name = "prjfo";
                script = ''
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
              };
            }
            // optionalAttrs cfg.includeGitTools {
              gt = mkPkg {
                inherit pkgs;
                name = "gt";
                command = gitui;
              };
            }
            // optionalAttrs cfg.includeFileTools {
              ls = mkPkg {
                inherit pkgs;
                name = "ls";
                command = lsd;
              };
              ll = mkPkg {
                inherit pkgs;
                name = "ll";
                script = ''${lsd} --long --git --almost-all "$@"'';
              };
              lt = mkPkg {
                inherit pkgs;
                name = "lt";
                script = ''${lsd} --tree "$@"'';
              };
              lr = mkPkg {
                inherit pkgs;
                name = "lr";
                script = ''${lsd} --long --git --recursive "$@"'';
              };
            }
        );

      all = attrValues packages ++ attrValues scripts;
    in {inherit all packages binaries scripts;});
}
