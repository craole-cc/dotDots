{
  perSystem =
    {
      config,
      pkgsUnstable,
      ...
    }:
    let
      fmt = {
        config = config.treefmt.build.configFile;
        packages = with pkgsUnstable; [
          alejandra
          nixfmt-rfc-style
          deadnix
        ];
        wrapper = config.treefmt.build.wrapper;
      };
    in
    {
      _module.args = { inherit fmt; };
      treefmt = {
        programs = {
          nixfmt = {
            enable = true;
            package = pkgsUnstable.nixfmt-rfc-style;
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
