{
  lib,
  paths,
  ...
}: let
  inherit (lib.attrsets) optionalAttrs recursiveUpdate;
  inherit (lib.packages) mkBins mkPkg mkPackages;
in {
  mkExtra = {
    pkgs,
    variant ? {},
  }: let
    cfg =
      recursiveUpdate {
        kind = "core";
        name = "extra";
        enable = true;
        includeMise = true;
        includeFetch = true;
        includeGitTools = true;
        includeFileTools = true;
        includeRustScript = true;
      }
      (optionalAttrs (variant ? extra) variant.extra);
  in
    {variant = cfg;}
    // optionalAttrs cfg.enable (let
      packages = with pkgs; let
        common = (
          {}
          // optionalAttrs cfg.includeRustScript {inherit cargo rust-script gcc;}
          // optionalAttrs cfg.includeMise {inherit mise;}
          // optionalAttrs cfg.includeFetch {inherit fastfetch microfetch nitch tokei onefetch;}
          // optionalAttrs cfg.includeGitTools {inherit gitui gh jj;}
          // optionalAttrs cfg.includeFileTools {inherit lsd;}
        );

        custom =
          {}
          //
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
        all = common // custom;
      in {inherit all common custom binaries;};

      binaries = let
        common = mkBins packages.common;
        custom = mkBins packages.custom;
        all = common // custom;
      in {inherit all common custom;};

      variables =
        {}
        # // optionalAttrs cfg.includeClaude
        # {ANTHROPIC_API_KEY = "$ANTHROPIC_API_KEY";}
        // {};
    in {inherit variables packages binaries;});
}
