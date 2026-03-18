{lix, ...}: let
  inherit (lix.applications.editors) mkVSCodeFeature;
in
  mkVSCodeFeature {
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
  }
