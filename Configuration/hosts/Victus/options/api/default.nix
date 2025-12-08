{
  config,
  systemName,
  configName,
  lib,
  _lib,
  ...
}: let
  inherit
    (lib.attrsets)
    filterAttrs
    attrNames
    mapAttrs
    ;
  inherit (lib.generators) toPretty;
  inherit
    (lib.lists)
    elem
    head
    length
    filter
    ;
  inherit (lib.modules) mkMerge;
  inherit (lix.filesystem) importAttrset;
  inherit (lix.attrsets) recursiveUpdate;

  hosts = mapAttrs (_: recursiveUpdate) (importAttrset ./hosts);
  users = mapAttrs (_: recursiveUpdate) (importAttrset ./users);

  cfg = let
    inherit (config.${DOM}) hosts users;
    hostNames = attrNames hosts;
    hostUsers = hosts.people or [];
    userNames = attrNames hosts;
    usersUnknown = filter (user: !(elem user userNames)) hostUsers;
  in {
    inherit
      hosts
      hostNames
      users
      userNames
      usersUnknown
      ;
  };

  active = let
    hosts = filterAttrs (_: h: h.enable or false) cfg.hosts;
    hostNames = attrNames hosts;
    hostName =
      if (length hostNames != 1)
      then null
      else head hostNames;
    host =
      if hostName == null
      then {}
      else hosts.${hostName} // {name = hostName;};
    hostUsers = host.people or [];
    users = filterAttrs (u: _: elem u hostUsers) cfg.users;
    userNames = attrNames users;
  in {
    inherit
      hosts
      host
      hostNames
      users
      userNames
      ;
  };
in {
  assertions = let
    list = output: toPretty {multiline = false;};
    cfgStr = "config.${DOM}.hosts";
    inherit (active) hostNames;
    inherit (cfg) usersUnknown;
  in [
    {
      assertion = length hostNames <= 1;
      message = "Only one ${cfgStr}.<name>.enable may be true; enabled hosts: " + list hostNames;
    }
    {
      assertion = length usersUnknown == 0;
      message = "Unknown users referenced in ${cfgStr}.people: " + list usersUnknown;
    }
  ];

  _module.args = {
    inherit (active) host users;
    inherit DOM;
  };

  ${DOM} = mkMerge [
    {inherit hosts users;}
    {
      hosts.${HOST} = {
        enable = true;
        users = active.users;
      };
    }
  ];
}
