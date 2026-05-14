{
  lib,
  paths,
  ...
}: let
  inherit (lib.attrsets) optionalAttrs recursiveAttrs;
  inherit (lib.packages) mkBins mkPkg mkPackages;
in {
  mkExtra = {
    pkgs,
    variant ? {},
  }: let
    name = "extra";
    cfg = let
      set1 = {
        inherit name;
        kind = "core";
        enable = false;
        includeMise = false;
        includeFetch = false;
        includeGitTools = false;
        includeFileTools = false;
        includeRustScript = false;
      };
      set2 = variant.extra or {};
      set3 = recursiveAttrs {inherit set1 set2;};
      set4 = {};
    in {
      inherit
        set1
        set2
        set3
        set4
        ;
      final = recursiveAttrs {inherit set3 set4;};
    };
    configuration = cfg.final;
  in
    {
      inherit configuration;
    }
    // optionalAttrs configuration.enable (
      with configuration; let
        packages = let
          common = with pkgs;
            {}
            // optionalAttrs includeRustScript {inherit cargo rust-script gcc;}
            // optionalAttrs includeMise {inherit mise;}
            // optionalAttrs includeFetch {
              inherit
                fastfetch
                microfetch
                nitch
                onefetch
                tokei
                ;
            }
            // optionalAttrs includeGitTools {inherit gitui gh jj;}
            // optionalAttrs includeFileTools {inherit lsd;};

          custom =
            optionalAttrs (includeRustScript && (paths ? scripts.default)) (mkPackages {
              inherit pkgs;
              dir = paths.scripts.default;
              priority = [
                "rs"
                "sh"
                "bash"
                "py"
                "rb"
              ];
            })
            // (
              with binaries.common;
                {}
                // optionalAttrs includeFetch {
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
                // optionalAttrs includeGitTools {
                  gt = mkPkg {
                    inherit pkgs;
                    name = "gt";
                    command = gitui;
                  };
                }
                // optionalAttrs includeFileTools {
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
          all = common // custom;
        in {
          inherit all common custom;
        };

        binaries = let
          common = mkBins packages.common;
          custom = mkBins packages.custom;
          all = common // custom;
        in {
          inherit all common custom;
        };

        variables = {};
        messages = null;
      in {
        inherit
          variables
          packages
          binaries
          messages
          ;
      }
    );
}
