{lib}: let
  inherit (lib.attrsets) attrValues optionalAttrs;
  inherit (lib.lists) flatten;
  inherit (lib.packages) mkBins;
  inherit (lib.strings) mkStyledOutput;
  inherit (lib.trivial) isNotEmpty;
  inherit (lib.packages) mkPkgs;

  mkTools = {
    pkgs ? mkPkgs {},
    minimal ? false,
    includeEditor ? true,
    includeFmt ? true,
    includeInfo ? true,
  }: let
    print = mkStyledOutput {inherit pkgs;};
    tools = {
      fmt = optionalAttrs (includeFmt && !minimal) {
        inherit
          (pkgs)
          taplo
          treefmt
          markdownlint-cli2
          prettierd
          yamlfmt
          ;
      };
      info = optionalAttrs (includeInfo && !minimal) {
        inherit
          (pkgs)
          gitui
          onefetch
          tokei
          direnv
          gum
          mise
          trashy
          ;
      };
      editor = optionalAttrs (includeEditor && !minimal) {
        inherit (pkgs) helix;
      };
    };

    bin = with tools;
      {}
      // optionalAttrs (isNotEmpty fmt) (mkBins fmt)
      // optionalAttrs (isNotEmpty info && !minimal) (mkBins info)
      // optionalAttrs (isNotEmpty editor) (mkBins editor)
      // {};

    cmd =
      {
        gumv = ''${bin.gum} --version 2>&1 | head -n1 | awk '{print $2}' '';
      }
      // optionalAttrs (includeFmt && !minimal) {
        fmtree = bin.treefmt;
        treefmtv = ''${bin.treefmt} --version 2>&1 | awk '{print substr($2,2)}' '';
      }
      // optionalAttrs (includeInfo && !minimal) {
        info = "${bin.tokei}; ${bin.onefetch}";
        gt = bin.gitui;
        reload = "${bin.direnv} reload";
        misev = ''${bin.mise} version 2>/dev/null | grep -o '^[0-9]*\.[0-9]*\.[0-9]*' '';
        update-flake = ''
          ${print.yellow} "Updating flake inputs..."
          nix flake update
        '';
      }
      // optionalAttrs (includeEditor && !minimal) {
        hxv = ''${bin.helix} --version 2>&1 | head -n1 | awk '{print $2}' '';
      };
  in {
    inherit bin cmd print;
    tools = tools // {all = flatten (attrValues tools);};
  };
in {inherit mkTools;}
