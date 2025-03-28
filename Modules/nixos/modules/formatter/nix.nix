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
          #| Nix
          nixfmt-rfc-style = {
            enable = true;
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
