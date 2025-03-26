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
      formatter = fmt.wrapper;
      treefmt = {
        projectRootFile = "flake.nix";
        programs = {
          #| Nix
          nixfmt = {
            enable = true;
            package = pkgs.nixfmt-rfc-style;
            priority = 2;
          };
          deadnix = {
            enable = true;
            priority = 1;
          };

          #| Shellscript
          shellcheck = {
            # enable = true;
            priority = 1;
          };
          shfmt = {
            # enable = true;
            priority = 2;
          };

          #| Documentation & Configuration
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

          #| Web & Fallback
          biome = {
            enable = true;
            priority = 1;
          };
          deno = {
            enable = true;
            priority = 2;
          };
        };
        settings = {
          global.on-unmatched = "info";
          formatter =
            let
              sh.includes = [
                "**/sh/**"
                "**/shellscript/**"
                "**/bash/**"
              ];
            in
            {
              shellcheck.includes = sh.includes;
              shfmt.includes = sh.includes;
            };
        };
      };
    };
}
