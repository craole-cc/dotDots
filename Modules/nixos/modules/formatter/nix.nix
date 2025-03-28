{
  perSystem =
    {
      config,
      pkgsUnstable,
      ...
    }:
    let
      nixfmtRfcStyle = pkgsUnstable.nixfmt-rfc-style;
      fmt = {
        config = config.treefmt.build.configFile;
        packages = with pkgsUnstable; [
          alejandra
          nixfmtRfcStyle
          deadnix
        ];
        wrapper = config.treefmt.build.wrapper;
      };
    in
    {
      _module.args = { inherit fmt; };
      treefmt = {
        programs = {
          #| Nix
          nixfmt = {
            enable = true;
            pkgs = nixfmtRfcStyle;
            priority = 2;
          };
          # deadnix = {
          #   enable = true;
          #   priority = 1;
          # };
        };
      };
    };
}
