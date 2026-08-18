{
  config,
  lix,
  pkgs,
  ...
}: let
  inherit (lix.attrsets.construction) listToAttrs;
  inherit (lix.modules.construction) mkContext mkConfig;
  inherit (lix.sources.access) getExe;

  context = mkContext {
    inherit config;
    dom = "remote";
    sub = "tools";
    mod = "vpn-firejail";
  };

  vpnRoot = config.${context.top}.resolved.remote.tools;
  apps = vpnRoot.vpn-openvpn.explicit.apps or [];

  mkWrapped = app: {
    name = app;
    value = {
      executable = getExe pkgs.${app};
      extraArgs = ["--netns=vpn"];
    };
  };
in
  mkConfig {
    inherit context;
    predicate = apps != [];
    options = {};
    outputs.programs.firejail = {
      enable = true;
      wrappedBinaries = listToAttrs (map mkWrapped apps);
    };
  }
