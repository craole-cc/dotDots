{
  perSystem =
    {
      config,
      pkgs,
      ...
    }:
    let
      fmt = {
        config = config.treefmt.build.configFile;
        packages = with pkgs; [
          #TODO: These should not be necessary since the wrapper is actuall a package of the entire treefmt config.
          treefmt
          biome
          alejandra
          deadnix
          shellcheck
          shfmt
          mdsh
          taplo
          yamlfmt
          nodePackages.prettier
        ];
        wrapper = config.treefmt.build.wrapper;
      };
    in
    {
      _module.args = { inherit fmt; };
      treefmt = {
        programs = {
          actionlint = {
            enable = true;
          };
          mdsh = {
            enable = true;
            priority = 1;
          };
          taplo = {
            enable = true;
            priority = 1;
          };
          yamlfmt = {
            enable = true;
            priority = 1;
          };
          # biome = {
          #   enable = true;
          #   priority = 1;
          # };
          deno = {
            enable = true;
            priority = 1;
          };
          prettier = {
            enable = true;
            priority = 2;
          };
          nufmt = {
            enable = true;
          };
        };
      };
    };
}
