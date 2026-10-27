{
  config,
  host,
  lix,
  pkgs,
  top ? "_",
  ...
}: let
  inherit (lix.attrsets.access) attrByPath attrValues;
  inherit (lix.attrsets.transformation) mapAttrs;
  inherit (lix.lists.aggregation) concatMap;
  inherit (lix.lists.construction) toList;
  inherit (lix.lists.transformation) unique;
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkOption mkTrue;
  inherit (lix.schema.fonts) mkFonts;
  inherit (lix.strings.construction) splitString;
  inherit (lix.types.combinators) either listOf;
  inherit (lix.types.primitives) package str;

  context = mkContext {
    inherit config top;
    dom = "interface";
    # sub = "style";
    mod = "fonts";
  };
  inherit (context) cfg;

  selected = mkFonts {
    inherit host;
    user = host.users.data.primary or {};
  };

  # Canonical roles only; sans and mono are mirrors of sansSerif and monospace.
  roles =
    removeAttrs
    (mapAttrs (_: entries: unique (map (entry: entry.family) entries)) selected.categories)
    ["sans" "mono"];

  resolvePackage = name:
    attrByPath (splitString "." name)
    (throw "Unknown font package '${name}'.")
    pkgs;

  users = attrValues (host.users.data.enabled or {});
  selections = [selected] ++ map (user: mkFonts {inherit host user;}) users;
  packages = unique (
    concatMap (fonts: map resolvePackage fonts.packages) selections
  );
  # first = role: optionalString (cfg.${role} != []) (head cfg.${role});
in
  mkConfig {
    inherit context;
    options =
      {
        enable = mkTrue "fonts";
        packages = mkOption {
          description = "Font packages for every ordered selection of enabled users";
          default = packages;
          type = listOf package;
        };
      }
      // mapAttrs (role: default:
        mkOption {
          description = "Ordered ${role} font families, with the preferred family first";
          inherit default;
          type = either str (listOf str);
          apply = toList;
        })
      roles;

    outputs = {
      fonts = {
        inherit (cfg) packages;
        enableDefaultPackages = true;
        enableGhostscriptFonts = true;
        fontDir.enable = true;
        fontconfig = {
          enable = true;
          defaultFonts = {inherit (cfg) monospace sansSerif serif emoji;};
        };
      };
      environment.sessionVariables = selected.variables;
    };
  }
