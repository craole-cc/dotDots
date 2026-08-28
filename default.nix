{
  lib ? null,
  flake ? null,
  root ? null,
}: let
  inherit (builtins) getEnv pathExists;

  bootstrap = let
    envOr = key: default: let
      val = getEnv key;
    in
      if val != ""
      then val
      else default;

    paths = {
      api.store = ./API/nix;
      lib.store = ./Libraries/nix;
    };

    api = import paths.api.store;
    hosts = {
      default = let
        name = envOr "HOSTNAME" "QBX";
      in {inherit name;};
    };
    # host = let
    #   path = api.hosts + "/${envOr "HOSTNAME" "QBX"}";
    # in
    #   if pathExists (path + "/default.nix")
    #   then import path
    #   else {};
    # api' =
    #   global
    #   // host
    #   // {
    #     paths = (global.paths or {}) // (host.paths or {});
    #     names = (global.names or {}) // (host.names or {});
    #   };
    # paths = {
    #   flake = {
    #     store = ./.;
    #     local =
    #       if root != null
    #       then root
    #       else api.paths.flake or (envOr "PWD" "/home/craole/.dots");
    #   };
    #   lib = {
    #     store = ./Libraries/nix;
    #   };
    # };
    # libraries = import paths.lib.store {
    #   inherit flake lib;
    #   inherit (api) names;
    #   inherit paths;
    # };
  in {
    inherit envOr paths api hosts;
    # inherit paths libraries;
    # inherit (libraries) default;
    # expose the short name the library chose
    # lix = libraries.default;
  };
  # inherit (bootstrap) default lix paths;
  # ── Pass 2: now we have a real library, use it ─────────────────────
  # Everything that previously lived in the huge bootstrap can move here
  # and call into lix / default instead of re-implementing helpers.
  # Example – the rest of your original logic, but powered by the library:
  #
  # api      = …;                          # still load global + host
  # stems    = …;
  # roots    = …;
  # paths'   = lix.filesystem.tree.mkTree { inherit stems roots; } // { … };
  # env      = lix.attrsets.transformation.asEnvVars { … };
  # schema   = lix.schema.construction.mkSchema paths';
  # …
in {inherit bootstrap;}
# final export
# (removeAttrs bootstrap.libraries ["default"])
# // {
#   inherit (bootstrap) libraries;
# inherit api env paths' schema …;
# }
# {
#   lib ? null,
#   flake ? null,
#   root ? null,
# }: let
#   inherit
#     (builtins)
#     attrNames
#     concatStringsSep
#     filter
#     genList
#     isAttrs
#     isString
#     mapAttrs
#     pathExists
#     replaceStrings
#     split
#     stringLength
#     substring
#     ;
#   # TODO: Move to API/global
#   # defaults = {
#   #   names = {
#   #     top = "dots";
#   #     lib = "lix";
#   #   };
#   #   config = {
#   #     allowUnfree = true;
#   #     allowBroken = false;
#   #   };
#   #   core = {
#   #     attrs = "legacyPackages";
#   #     names = [
#   #       "nixpkgs"
#   #       "nixpkgs-stable"
#   #       "nixpkgs-unstable"
#   #     ];
#   #   };
#   #   home = {
#   #     attrs = "packages";
#   #     names = [
#   #       "age"
#   #       "caelestia"
#   #       "catppuccin"
#   #       "dank-material-shell"
#   #       "dms-plugin-registry"
#   #       "fresh-editor"
#   #       "helix"
#   #       "hermes-agent"
#   #       "home-manager"
#   #       "llm-agents"
#   #       "noctalia-shell"
#   #       "nvf"
#   #       "plasma"
#   #       "quickshell"
#   #       "treefmt"
#   #       "typix"
#   #       "vscode-insiders"
#   #       "zen-browser"
#   #     ];
#   #   };
#   # };
#   bootstrap = let
#     getEnv = env: default: let
#       resolved = builtins.getEnv env;
#     in
#       if resolved != ""
#       then resolved
#       else default;
#     importAttr = path:
#       if pathExists path
#       then import path
#       else {};
#     mergeAttrs = set1: set2:
#       if isAttrs set1 && isAttrs set2
#       then
#         (mapAttrs (key: value:
#           if set1 ? ${key}
#           then mergeAttrs set1.${key} value
#           else value)
#         set2)
#         // removeAttrs set1 (attrNames set2)
#       else set2;
#     hasPrefix = prefix: str:
#       (substring 0 (stringLength prefix) str) == prefix;
#     removePrefix = prefix: str:
#       if hasPrefix prefix str
#       then
#         substring
#         (stringLength prefix)
#         (stringLength str - stringLength prefix)
#         str
#       else str;
#     asPath = {
#       stem,
#       base,
#     }: let
#       stringToCharacters = str:
#         genList (char: substring char 1 str) (stringLength str);
#       escape = list:
#         replaceStrings list (map (char: "\\${char}") list);
#       escapeRegex =
#         escape (stringToCharacters "\\[{()^$?*+|.");
#       addContextFrom = flake: target:
#         substring 0 0 flake + target;
#       splitString = sep: str: let
#         string = toString str;
#         separator = toString sep;
#       in
#         if separator == ""
#         then [(addContextFrom str string)]
#         else
#           map
#           (addContextFrom str) #TODO: Is this correct? addContextFrom takes 2 arguments
#           (filter isString (split (escapeRegex separator) string));
#     in
#       if isAttrs stem
#       then
#         mapAttrs (_: part:
#           asPath {
#             inherit base;
#             stem = part;
#           })
#         stem
#       else if isString stem
#       then
#         if substring 0 1 stem == "/"
#         then {
#           store =
#             if substring 0 11 stem == "/nix/store/"
#             then /. + stem
#             else null;
#           local = stem;
#         }
#         else
#           asPath {
#             inherit base;
#             stem = (
#               filter
#               (val: isString val && val != "")
#               (splitString "/" stem)
#             );
#           }
#       else let
#         relPath = concatStringsSep "/" stem;
#       in {
#         store =
#           if base.store == null
#           then null
#           else base.store + "/${relPath}";
#         local = concatStringsSep "/" (
#           filter
#           (string: string != "")
#           [base.local relPath]
#         );
#       };
#     api = let
#       global = import ./API/nix/global;
#       inherit (global.paths.api) hosts;
#       host = let
#         name = getEnv "HOSTNAME" "QBX";
#         path = ./. + "/${concatStringsSep "/" hosts}/${name}";
#       in
#         importAttr path;
#     in
#       {inherit global host;} // mergeAttrs global host;
#     paths = {
#       flake = {
#         store = ./.;
#         local =
#           if root != null
#           then root
#           else getEnv "PWD" api.paths.flake;
#       };
#       user = let
#         path = getEnv "HOME" "/home/${api.names.alpha}";
#         flakeLocal = toString paths.flake.local;
#       in {
#         store =
#           if hasPrefix flakeLocal path
#           then paths.flake.store + removePrefix flakeLocal path
#           else null;
#         local = path;
#       };
#       #> Only the repo-relative groups are needed to reach paths.lib.default -
#       #> user/xdg/tmpdir are irrelevant to loading `_` and are skipped.
#       repo = asPath {
#         base = paths.flake;
#         stem =
#           removeAttrs api.paths
#           ["user" "xdg" "flake" "home" "tmpdir"];
#       };
#     };
#   in {
#     inherit api paths;
#     inherit (api) names;
#   };
#   inherit (bootstrap) names;
#   libraries = import bootstrap.paths.repo.lib.default.store {
#     inherit flake lib names;
#     inherit (bootstrap) paths;
#   };
#   library = libraries.default;
#   inherit (library.attrsets.transformation) asEnvVars mapAttrsToList;
#   inherit (library.filesystem.tree) mkTree;
#   inherit (library.lists.access) elemAt length;
#   inherit (library.lists.construction) concatLists optionals;
#   inherit (library.schema.construction) mkSchema;
#   inherit (library.strings.construction) concat;
#   inherit (library.strings.transformation) toUpper;
#   stems = removeAttrs bootstrap.api.paths ["flake" "home" "tmpdir"];
#   roots = {
#     user = bootstrap.paths.user.local;
#     xdg = bootstrap.paths.user.local;
#   };
#   paths =
#     (mkTree {inherit stems roots;})
#     // {
#       flake = bootstrap.paths.flake;
#       home = bootstrap.paths.user;
#       tmpdir = {
#         store = null;
#         local = with bootstrap; getEnv "TMPDIR" (api.paths.tmpdir or "/tmp");
#       };
#     };
#   #> --------------------------------------------------------------------
#   #> Final configuration: preserve the raw API data, but replace its raw
#   #> path stems with the fully-resolved canonical path model.
#   #> --------------------------------------------------------------------
#   cfg = bootstrap.api // {inherit paths;};
#   # cfg = with bootstrap; mergeAttrs api {inherit paths;};
#   env = let
#     transformPathVar = domain: attrPath: localPath: let
#       leaf = elemAt attrPath (length attrPath - 1);
#       joinedAttr =
#         if leaf == "default"
#         then null
#         else concat "_" attrPath;
#     in
#       if domain == "xdg"
#       then let
#         prefix = "XDG";
#         suffix =
#           if leaf == "runtime_dir" || leaf == "tmpdir"
#           then null
#           else "HOME";
#       in {
#         name = toUpper (concat [prefix] ++ attrPath ++ [suffix]);
#         default = localPath;
#       }
#       else if domain == "user"
#       then {
#         name = leaf;
#         default = localPath;
#       }
#       else {
#         name = "${bootstrap.names.flake}_${domain}${joinedAttr}";
#         default = localPath;
#       };
#     # Flatten a domain's tree into [{name; default;}], skipping non-leaf nodes.
#     treeOf = domain: attrPath: node:
#       optionals (isAttrs node) (
#         if node ? local
#         then [(transformPathVar domain attrPath node.local)]
#         else
#           concatLists (
#             mapAttrsToList
#             (key: child: treeOf domain (attrPath ++ [key]) child)
#             node
#           )
#       );
#     ignore = ["flake" "store" "local" "mkLocal"];
#   in
#     asEnvVars {
#       type = "set";
#       uppercase = true;
#       vars =
#         (
#           mapAttrsToList
#           (name: default: {inherit name default;})
#           cfg.environment
#         )
#         ++ [
#           {
#             name = names.flake;
#             default = paths.flake.local;
#           }
#           {
#             name = concat "_" [names.flake "HOME"];
#             default = paths.flake.local;
#           }
#         ]
#         ++ (concatLists (
#           mapAttrsToList (
#             domain: node:
#               concatLists (
#                 mapAttrsToList
#                 (key: child: treeOf domain [key] child)
#                 (removeAttrs node ignore)
#               )
#           ) (removeAttrs paths ignore)
#         ));
#     };
#   schema = mkSchema paths;
#   inherit (schema) hosts users;
# in
#   (removeAttrs libraries ["default"])
#   // {
#     inherit
#       bootstrap
#       cfg
#       env
#       hosts
#       libraries
#       names
#       paths
#       schema
#       stems
#       users
#       ;
#   }
