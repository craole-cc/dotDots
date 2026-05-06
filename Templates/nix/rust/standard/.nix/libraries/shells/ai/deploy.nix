{lib, ...}: let
  inherit (lib.packages) mkPkgs;
  inherit (lib.strings) mkStyledOutput;
  inherit (lib.shells) mkDeployConfig;

  entries = {
    # ai = {
    #   some-config = {
    #     source = config + "/some-config";
    #     target = ".some-config";
    #   };
    # };
  };

  deployConfig = {
    pkgs ? mkPkgs {},
    print ? mkStyledOutput {inherit pkgs;},
    includeFormat ? true,
    includeEditor ? false,
  }:
    mkDeployConfig {
      inherit pkgs print includeFormat includeEditor;
      title = "AI Configuration Deployment";
      description = "Syncing AI development configuration files into your workspace";
      extraEntries = entries;
    };
in {
  inherit entries deployConfig;
}
