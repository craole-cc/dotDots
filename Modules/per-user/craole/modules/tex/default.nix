{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.zfs-root.per-user.craole.modules.tex;
  inherit (lib) mkDefault mkOption types mkIf;
in {
  options.zfs-root.per-user.craole.modules.tex.enable = mkOption {
    default = config.zfs-root.per-user.craole.enable;
    type = types.bool;
  };
  config = mkIf cfg.enable {
    environment.systemPackages = [
      (pkgs.texlive.combine {
        inherit
          (pkgs.texlive)
          # necessary for org-mode
          
          scheme-basic
          dvipng
          latexmk
          wrapfig
          amsmath
          ulem
          hyperref
          capt-of
          # times like font
          
          newtx
          xkeyval
          xstring
          fontaxes
          # MLModern, thicker Computer Modern
          
          mlmodern
          # maths
          
          collection-mathscience
          # languages
          
          collection-langgerman
          # mathtools for coloneq
          
          mathtools
          # pdf manipulation tool
          
          pdfjam
          pdfpages
          # code listings
          
          listings
          # pictures and tikz
          
          collection-pictures
          ;
      })
    ];
  };
}
