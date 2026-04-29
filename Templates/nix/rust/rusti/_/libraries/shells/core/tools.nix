{lib}: let
  mkTools = {
    pkgs,
    minimal ? false,
    includeEditor ? true,
    includeFmt ? true,
    includeInfo ? true,
  }: let
    inherit (lib.attrsets) attrValues;
    inherit (lib.lists) optionals flatten;
    inherit (lib.strings) mkStyledOutput;

    print = mkStyledOutput {inherit pkgs;};

    tools = {
      fmt =
        optionals (includeFmt && !minimal)
        (with pkgs; [taplo treefmt markdownlint-cli2 prettierd yamlfmt]);
      info =
        optionals (includeInfo && !minimal)
        (with pkgs; [gitui onefetch tokei direnv gum mise trashy]);
      editor =
        optionals (includeEditor && !minimal)
        (with pkgs; [helix]);
    };

    bin =
      {}
      // optionals (includeFmt && !minimal) {
        treefmt = "${pkgs.treefmt}/bin/treefmt";
      }
      // optionals (includeInfo && !minimal) {
        gum = "${pkgs.gum}/bin/gum";
        gitui = "${pkgs.gitui}/bin/gitui";
        tokei = "${pkgs.tokei}/bin/tokei";
        onefetch = "${pkgs.onefetch}/bin/onefetch";
        direnv = "${pkgs.direnv}/bin/direnv";
        mise = "${pkgs.mise}/bin/mise";
        trashy = "${pkgs.trashy}/bin/trash";
      }
      // optionals (includeEditor && !minimal) {
        helix = "${pkgs.helix}/bin/hx";
      };

    cmd =
      {}
      // optionals (includeFmt && !minimal) {
        fmtree = bin.treefmt;
        treefmtv = ''${bin.treefmt} --version 2>&1 | awk '{print substr($2,2)}' '';
      }
      // optionals (includeInfo && !minimal) {
        info = "${bin.tokei}; ${bin.onefetch}";
        gt = bin.gitui;
        reload = "${bin.direnv} reload";
        misev = ''${bin.mise} version 2>/dev/null | grep -o '^[0-9]*\.[0-9]*\.[0-9]*' '';
        update-flake = ''
          ${print.yellow} "Updating flake inputs..."
          nix flake update
        '';
      }
      // optionals (includeEditor && !minimal) {
        hxv = ''${bin.helix} --version 2>&1 | head -n1 | awk '{print $2}' '';
      };
  in {
    inherit bin cmd print;
    tools = tools // {all = flatten (attrValues tools);};
  };
in {inherit mkTools;}
