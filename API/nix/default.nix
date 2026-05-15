# {
#   lib,
#   hostName ? null,
#   ...
# }: let
#   inherit
#     (lib.attrsets)
#     mapAttrs
#     listToAttrs
#     attrNames
#     optionalAttrs
#     attrValues
#     recursiveUpdate
#     filterAttrs
#     removeAttrs
#     ;
#   inherit (lib.lists) head elem filter sort length;
#   inherit (builtins) readDir;
#   importAttrs = dir: let
#     entries = readDir dir;
#     dirNames = filter (name: entries.${name} == "directory") (attrNames entries);
#   in
#     listToAttrs (
#       map (name: {
#         inherit name;
#         value = import (dir + "/${name}");
#       })
#       dirNames
#     );
#   rawHosts = importAttrs ./hosts;
#   rawUsers = importAttrs ./users;
#   enrichHost = host: let
#     user = let
#       rolePriority = {
#         "administrator" = 1;
#         "admin" = 2;
#         "developer" = 3;
#         "poweruser" = 4;
#       };
#       usersByName = listToAttrs (map (p: {
#           name = p.name;
#           value = p;
#         })
#         host.principals);
#       # Merge user configs but keep enable, autoLogin, and role from principals
#       all =
#         mapAttrs (
#           name: hostUser: let
#             userData = rawUsers.${name} or {};
#             # Remove enable, autoLogin, and role from user data
#             userDataFiltered = removeAttrs userData ["enable" "autoLogin" "role"];
#           in
#             recursiveUpdate userDataFiltered hostUser
#         )
#         usersByName;
#       # Force-enable first principal if none enabled
#       # This ensures we always have at least one elevated user
#       allWithDefault =
#         if filterAttrs (_: u: u.enable == true) all == {}
#         then let
#           firstPrincipal = head host.principals;
#         in
#           all
#           // {
#             ${firstPrincipal.name} =
#               all.${firstPrincipal.name}
#               // {
#                 enable = true;
#                 role = all.${firstPrincipal.name}.role or "administrator";
#               };
#           }
#         else all;
#       enabled = filterAttrs (_: u: u.enable == true) allWithDefault;
#       autoLogin = filterAttrs (_: u: u.autoLogin == true) enabled;
#       elevated =
#         mapAttrs (_: u: u // {_priority = rolePriority.${u.role or "guest"} or 999;})
#         (filterAttrs (_: u: elem (u.role or "") (attrNames rolePriority)) enabled);
#       primary =
#         if autoLogin != {}
#         then autoLogin
#         else if elevated != {}
#         then let
#           sorted = sort (a: b: a._priority < b._priority) (attrValues elevated);
#         in {${(head sorted).name} = head sorted;}
#         else if enabled != {}
#         then enabled
#         else {}; # Return empty if no users enabled
#       names = {
#         all = attrNames all;
#         primary =
#           if primary != {}
#           then head (attrNames primary)
#           else null;
#         enabled = attrNames enabled;
#         elevated = attrNames elevated;
#         autoLogin = attrNames autoLogin;
#       };
#       count = {
#         total = length names.all;
#         enabled = length names.enabled;
#         elevated = length names.elevated;
#       };
#       data = {inherit all enabled elevated autoLogin primary;};
#     in {inherit names count data;};
#     interface = let
#       primaryUser = user.names.primary;
#       primaryInterface =
#         if primaryUser != null
#         then rawUsers.${primaryUser}.interface or {}
#         else {};
#       hostInterface = host.interface or {};
#       # Merge in priority order: primary user > host > defaults
#       merged = recursiveUpdate hostInterface primaryInterface;
#     in
#       normalizeInterface merged;
#     system = host.specs.platform or "x86_64-linux";
#     name = head (attrNames (filterAttrs (_: h: h == host) rawHosts));
#   in
#     host
#     // {
#       inherit
#         name
#         system
#         interface
#         ;
#       inherit (host.paths) dots;
#       users = user.data.enabled;
#       metadata = {inherit user;};
#     };
#   hosts = mapAttrs (_: enrichHost) rawHosts;
#   # Force protocol compatibility + recommend display manager
#   normalizeInterface = interface: let
#     de = interface.desktopEnvironment or null;
#     wm = interface.windowManager or null;
#     protocol = interface.displayProtocol or null;
#     # Environment database with priority and compatibility
#     envDB = {
#       # Desktop Environments (full stacks)
#       desktops = {
#         gnome = {
#           priority = 1;
#           protocols = ["wayland" "x11"];
#           preferredProtocol = "wayland";
#           displayManager = "gdm";
#         };
#         kde = {
#           priority = 1;
#           protocols = ["wayland" "x11"];
#           preferredProtocol = "wayland";
#           displayManager = "sddm";
#         };
#         plasma = {
#           priority = 1;
#           protocols = ["wayland" "x11"];
#           preferredProtocol = "wayland";
#           displayManager = "sddm";
#         };
#         cosmic = {
#           priority = 1;
#           protocols = ["wayland"];
#           preferredProtocol = "wayland";
#           displayManager = "sddm";
#         };
#         pantheon = {
#           priority = 1;
#           protocols = ["x11"];
#           preferredProtocol = "x11";
#           displayManager = "lightdm";
#         };
#         cinnamon = {
#           priority = 1;
#           protocols = ["x11"];
#           preferredProtocol = "x11";
#           displayManager = "lightdm";
#         };
#         xfce = {
#           priority = 1;
#           protocols = ["x11"];
#           preferredProtocol = "x11";
#           displayManager = "lightdm";
#         };
#       };
#       # Window Managers (compositor-based or standalone)
#       windowManagers = {
#         hyprland = {
#           priority = 2;
#           protocols = ["wayland"];
#           preferredProtocol = "wayland";
#           displayManager = "sddm";
#         };
#         sway = {
#           priority = 2;
#           protocols = ["wayland"];
#           preferredProtocol = "wayland";
#           displayManager = "sddm";
#         };
#         niri = {
#           priority = 2;
#           protocols = ["wayland"];
#           preferredProtocol = "wayland";
#           displayManager = "sddm";
#         };
#         river = {
#           priority = 2;
#           protocols = ["wayland"];
#           preferredProtocol = "wayland";
#           displayManager = "sddm";
#         };
#         i3 = {
#           priority = 2;
#           protocols = ["x11"];
#           preferredProtocol = "x11";
#           displayManager = "lightdm";
#         };
#         bspwm = {
#           priority = 2;
#           protocols = ["x11"];
#           preferredProtocol = "x11";
#           displayManager = "lightdm";
#         };
#         awesome = {
#           priority = 2;
#           protocols = ["x11"];
#           preferredProtocol = "x11";
#           displayManager = "lightdm";
#         };
#         xmonad = {
#           priority = 2;
#           protocols = ["x11"];
#           preferredProtocol = "x11";
#           displayManager = "lightdm";
#         };
#         openbox = {
#           priority = 2;
#           protocols = ["x11"];
#           preferredProtocol = "x11";
#           displayManager = "lightdm";
#         };
#       };
#     };
#     # Determine which environment to use (DE takes priority over WM)
#     selectedEnv =
#       if de != null && envDB.desktops ? ${de}
#       then {
#         name = de;
#         type = "desktop";
#         config = envDB.desktops.${de};
#       }
#       else if wm != null && envDB.windowManagers ? ${wm}
#       then {
#         name = wm;
#         type = "windowManager";
#         config = envDB.windowManagers.${wm};
#       }
#       else null;
#     # Determine final protocol
#     finalProtocol =
#       if selectedEnv != null
#       then
#         # Use user's choice if compatible, otherwise force to supported protocol
#         if protocol != null && elem protocol selectedEnv.config.protocols
#         then protocol
#         else selectedEnv.config.preferredProtocol
#       else if protocol != null
#       then protocol
#       else "wayland"; # Default to wayland if no environment specified
#     # Determine display manager
#     finalDisplayManager =
#       if selectedEnv != null
#       then selectedEnv.config.displayManager
#       else (interface.loginManager or "gdm");
#     # Build final interface config
#     result =
#       interface
#       // {
#         displayProtocol = finalProtocol;
#         loginManager = finalDisplayManager;
#       };
#   in
#     result;
#   getHost = name: optionalAttrs (hosts ? "${name}") hosts.${name};
#   host = optionalAttrs (hosts != {}) (
#     if (hostName == null)
#     then (head (attrValues hosts))
#     else (getHost hostName)
#   );
#   users = rawUsers;
# in {
#   inherit
#     host
#     hosts
#     users
#     rawHosts
#     ;
#   inherit
#     getHost
#     ;
#   inherit normalizeInterface;
# }
{}
