{lix ? (import ../.. {}).libraries.default}: let
  pkgs = {
    fastfetch = {};
    nitch = {};
    onefetch = {};
    tokei = {};
    git = {};
    writeShellApplication = specification:
      specification
      // {
        type = "derivation";
        outPath = "/packaged-${specification.name}";
      };
  };
  paths.store.lib.sh = ../../Libraries/posix;
  maintenance = lix.modules.core.software.mkMaintenance {
    inherit pkgs paths;
    repo = {
      name = "dots";
      home = "/tmp/dots checkout";
    };
    keep.args = [];
  };
  package = builtins.head maintenance.environment.systemPackages;
  aliases = maintenance.environment.shellAliases;
in {
  genericPackage = package.name == "fetch";
  sharedImplementation = package.text == builtins.readFile ../../Libraries/posix/data/fetch;
  checkoutShortcut = aliases.dots-fetch == "/packaged-fetch/bin/fetch '/tmp/dots checkout'";
  fullShortcut = aliases.dots-fetch-full == "/packaged-fetch/bin/fetch --full '/tmp/dots checkout'";
  separateCommandNames = package.name != "dots-fetch";
}
