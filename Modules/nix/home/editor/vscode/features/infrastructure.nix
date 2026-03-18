{
  lix,
  pkgs,
  inputs,
  ...
}: let
  inherit (lix.applications.editors) mkVSCodeFeature;
in {
  name = "infrastructure";
  description = "Docker, SQL, DevOps extensions";
  default = false;
  feature = enabled:
    mkVSCodeFeature {
      inherit enabled pkgs inputs;
      extensions = [
        #? Docker file support and container management
        "ms-azuretools.vscode-docker"
        #? SQL client and query runner
        "mtxr.sqltools"
        #? SQLite driver for sqltools
        "mtxr.sqltools-driver-sqlite"
        #? Tailscale network integration
        "tailscale.vscode-tailscale"
      ];
    };
}
