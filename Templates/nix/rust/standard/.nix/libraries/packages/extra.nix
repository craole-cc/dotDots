{lib, ...}: let
  inherit (lib.attrsets) attrValues optionalAttrs;
  inherit (lib.packages) mkBins mkPkg;
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
      };
    },
  }: let
    cfg = variant.extra;
  in (
    {kind = "base";}
    // optionalAttrs cfg.enable (let
      packages =
        {}
        // optionalAttrs cfg.includeMise {inherit (pkgs) mise;}
        // optionalAttrs cfg.includeFetch {
          inherit (pkgs) fastfetch microfetch nitch tokei onefetch;
        }
        // optionalAttrs cfg.includeGitTools {
          inherit (pkgs) gitui gh jj;
        }
        // optionalAttrs cfg.includeFileTools {
          inherit (pkgs) lsd;
        };

      binaries = {
        packages = mkBins packages;
        scripts = mkBins scripts;
        all = binaries.packages // binaries.scripts;
      };

      scripts = with binaries.packages;
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
        };
      all = attrValues packages ++ attrValues scripts;
    in {inherit all packages binaries scripts;})
  );
}
