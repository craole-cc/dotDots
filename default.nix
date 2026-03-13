{
  self ? {},
  path ? ./.,
  system ? null,
  lib ? null,
  ...
}: let
  #|───────────────────────────────────────────────────────────────|
  #| Library Imports                                               |
  #|───────────────────────────────────────────────────────────────|
  libInit = import ./Libraries/nix {inherit lib path;};
  inherit (libInit) lix;
  inherit (lix.filesystem.resolution) getFlake;
  inherit (lix.filesystem.tree) mkTree;
  inherit (lix.inputs.source) resolveInputs;
  inherit (lix.schema._) mkSchema;
  inherit (lix.schema.resolution) getHost;

  #|───────────────────────────────────────────────────────────────|
  #| Core Data Layer                                               |
  #|───────────────────────────────────────────────────────────────|
  flake = getFlake {inherit self path;};
  inputs = resolveInputs {
    inherit path;
    self = flake;
  };

  tree = mkTree {inherit flake;};
  schema = mkSchema {inherit tree;};
  inherit (schema) hosts users;

  #|───────────────────────────────────────────────────────────────|
  #| Target Host Resolution                                        |
  #|───────────────────────────────────────────────────────────────|
  # nixosConfigurations = flake.nixosConfigurations or {};
  host = getHost {inherit flake hosts;};
  #|───────────────────────────────────────────────────────────────|
  #| REPL Helpers                                                  |
  #|───────────────────────────────────────────────────────────────|
  # helpers = {
  #   #~@ Script generators (copy-paste ready)
  #   scripts = {
  #     rebuild = h: "sudo nixos-rebuild switch --flake .#${h}";
  #     test = h: "sudo nixos-rebuild test --flake .#${h}";
  #     boot = h: "sudo nixos-rebuild boot --flake .#${h}";
  #     dry = h: "sudo nixos-rebuild dry-build --flake .#${h}";
  #     update = "nix flake update";
  #     clean = "sudo nix-collect-garbage -d";
  #   };
  #   #~@ Host discovery
  #   listHosts = attrNames nixosConfigurations;
  #   getHostConfig = name: nixosConfigurations.${name} or null;
  #   #~@ Host information
  #   hostInfo = name: let
  #     targetHost = nixosConfigurations.${name} or {};
  #     cfg = targetHost.config or {};
  #     allUsers = attrNames (cfg.users.users or {});
  #     version = {
  #       kernel = attrByPath ["boot" "kernelPackages" "kernel" "version"] "unknown" cfg;
  #       state = cfg.system.stateVersion or "unknown";
  #       nixos = cfg.system.nixos.version or "unknown";
  #     };
  #     userList = {
  #       custom = filter (u: !isSystemDefaultUser u) allUsers;
  #       system = filter isSystemDefaultUser allUsers;
  #     };
  #     usersData = listToAttrs (map (user: {
  #         name = user;
  #         value = {
  #           core = cfg.users.users.${user} or {};
  #           home = let hm = cfg.home-manager.users.${user} or {}; in hm // (hm.home or {});
  #           api = users.${user} or {};
  #         };
  #       })
  #       userList.custom);
  #     getHomeAttr = attr: user: user.home.${attr} or {};
  #     getApiAttr = attr: user: user.api.${attr} or {};
  #     mkConfigSection = {
  #       path,
  #       homeAttr,
  #       apiAttr,
  #     }: {
  #       core = attrByPath (splitString "." path) {} cfg;
  #       home =
  #         if length (attrNames usersData) == 1
  #         then
  #           getHomeAttr {
  #             attr = homeAttr;
  #             user = head (attrValues usersData);
  #           }
  #         else
  #           mapAttrs (_: user:
  #             getHomeAttr {
  #               attr = homeAttr;
  #               inherit user;
  #             })
  #           usersData;
  #       api =
  #         if length (attrNames usersData) == 1
  #         then
  #           getApiAttr {
  #             attr = apiAttr;
  #             name = head (attrValues usersData);
  #           }
  #         else
  #           mapAttrs (_: user:
  #             getApiAttr {
  #               attr = apiAttr;
  #               inherit user;
  #             })
  #           usersData;
  #     };
  #     programs = mkConfigSection {
  #       path = "programs";
  #       homeAttr = "programs";
  #       apiAttr = "programs";
  #     };
  #     services = mkConfigSection {
  #       path = "services";
  #       homeAttr = "services";
  #       apiAttr = "services";
  #     };
  #     variables = mkConfigSection {
  #       path = "environment.sessionVariables";
  #       homeAttr = "sessionVariables";
  #       apiAttr = "variables";
  #     };
  #     aliases = mkConfigSection {
  #       path = "environment.shellAliases";
  #       homeAttr = "shellAliases";
  #       apiAttr = "aliases";
  #     };
  #     packages = mkConfigSection {
  #       path = "environment.systemPackages";
  #       homeAttr = "packages";
  #       apiAttr = "packages";
  #     };
  #     desktopEnvironment = let
  #       dm = cfg.services.desktopManager or {};
  #     in
  #       if dm.plasma6.enable or false
  #       then "plasma"
  #       else if dm.gnome.enable or false
  #       then "gnome"
  #       else if dm.cosmic.enable or false
  #       then "cosmic"
  #       else null;
  #   in {
  #     inherit
  #       version
  #       usersData
  #       userList
  #       desktopEnvironment
  #       programs
  #       services
  #       variables
  #       aliases
  #       packages
  #       ;
  #     users = usersData;
  #     hostName = cfg.networking.hostName or "unknown";
  #     system = cfg.nixpkgs.hostPlatform.system or "unknown";
  #   };
  #   #~@ Host comparison
  #   compareHosts = host1: host2: let
  #     h1 = nixosConfigurations.${host1} or {};
  #     h2 = nixosConfigurations.${host2} or {};
  #     c1 = h1.config or {};
  #     c2 = h2.config or {};
  #   in {
  #     systems = {
  #       "${host1}" = c1.nixpkgs.hostPlatform.system or "unknown";
  #       "${host2}" = c2.nixpkgs.hostPlatform.system or "unknown";
  #     };
  #     kernels = {
  #       "${host1}" = attrByPath ["boot" "kernelPackages" "kernel" "version"] "unknown" c1;
  #       "${host2}" = attrByPath ["boot" "kernelPackages" "kernel" "version"] "unknown" c2;
  #     };
  #     stateVersions = {
  #       "${host1}" = c1.system.stateVersion or "unknown";
  #       "${host2}" = c2.system.stateVersion or "unknown";
  #     };
  #   };
  #   #~@ Service queries
  #   hostsWithService = service:
  #     attrNames (filterAttrs
  #       (_name: h: attrByPath (splitString "." service) false (h.config or {}))
  #       nixosConfigurations);
  #   enabledServices = hostName: let
  #     targetHost = nixosConfigurations.${hostName} or {};
  #     serviceSet = attrByPath ["config" "systemd" "services"] {} targetHost;
  #   in
  #     attrNames (filterAttrs (_n: v: v.enable or false) serviceSet);
  # };
in {
  inherit
    # helpers
    flake
    hosts
    inputs
    lib
    lix
    system
    tree
    users
    ;

  #~@ Top-level host attributes
  inherit (host) config options;
  specialArgs = host._module.specialArgs or {};

  # #~@ Convenient shortcuts to config sections (falls back safely if host is empty)
  # inherit
  #   (helpers.hostInfo (host.name or ""))
  #   users
  #   aliases
  #   packages
  #   programs
  #   services
  #   variables
  #   ;
}
