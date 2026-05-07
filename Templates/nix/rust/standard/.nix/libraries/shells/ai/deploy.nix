{lib, ...}: let
  inherit (lib.shells) mkDeployConfig;

  defineConfigDeployment = _: let
    entries = {
      all = {
        # ai = {
        #   some-config = {
        #     source = config + "/some-config";
        #     target = ".some-config";
        #   };
        # };
      };
      selected = entries.all;
    };
  in
    mkDeployConfig {
      inherit entries;
      title = "AI Configuration Deployment";
      description = "Syncing AI development configuration files into your workspace";
    };
in {inherit defineConfigDeployment;}
