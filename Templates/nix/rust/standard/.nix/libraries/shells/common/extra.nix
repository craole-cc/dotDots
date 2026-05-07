{lib, ...}: let
  inherit (lib.packages) mkBins mkPkg;
in {
  mkBase = pkgs: let
    templates = {};

    packages = with pkgs; {
      inherit
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
      inherit gcc rust-script;
    };

    bin = {
      packages = mkBins packages;
      scripts = mkBins scripts;
      all = bin.packages // bin.scripts;
    };

    scripts = with bin.packages; {
      #~@ Navigation
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
      ls = mkPkg {
        inherit pkgs;
        name = "ls";
        command = "${lsd}";
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

      #~@ Project Info
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

      #~@ Git
      gt = mkPkg {
        inherit pkgs;
        name = "gt";
        command = "${gitui}";
      };
    };
  in {inherit templates scripts packages;};
}
