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
  inherit (lix.lists.access) findFirst head;
  inherit (lix.lists.aggregation) concatMap;
  inherit (lix.lists.construction) toList;
  inherit (lix.lists.transformation) unique;
  inherit (lix.modules.construction) mkConfig mkContext;
  inherit (lix.options.construction) mkOption mkTrue;
  inherit (lix.schema.fonts) mkFonts;
  inherit (lix.strings.construction) optionalString splitString;
  inherit (lix.types.combinators) either listOf;
  inherit (lix.types.primitives) package str;

  context = mkContext {
    inherit config top;
    dom = "interface";
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

  fallbackSize = 11;

  packageByName = name: attrByPath (splitString "." name) null pkgs;
  resolvePackage = name:
    attrByPath (splitString "." name)
    (throw "Unknown font package '${name}'.")
    pkgs;

  users = attrValues (host.users.data.enabled or {});
  selections = [selected] ++ map (user: mkFonts {inherit host user;}) users;
  packages = unique (
    concatMap (fonts: map resolvePackage fonts.packages) selections
  );

  first = role: optionalString (cfg.${role} != []) (head cfg.${role});

  # Name, package and size of the preferred family for a role.
  resolve = role: let
    name = first role;
    entry = findFirst (candidate: candidate.family == name) null (selected.categories.${role} or []);
  in {
    inherit name;
    package =
      if entry != null && entry.package != null
      then packageByName entry.package
      else null;
    size =
      if entry != null && entry.size != null
      then entry.size
      else fallbackSize;
  };

  resolved = {
    monospace = resolve "monospace";
    sansSerif = resolve "sansSerif";
    serif = resolve "serif";
  };
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
      home = {inherit (cfg) packages;};

      fonts.fontconfig = {
        antialiasing = true;
        enable = true;
        defaultFonts = {inherit (cfg) monospace sansSerif serif emoji;};
      };

      xdg.configFile."fontconfig/conf.d/99-monospace-override.conf".text = ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
        <fontconfig>
          <match target="pattern">
            <test qual="any" name="family"><string>monospace</string></test>
            <edit name="family" mode="prepend" binding="strong">
              <string>${resolved.monospace.name}</string>
            </edit>
          </match>
        </fontconfig>
      '';

      home.sessionVariables = selected.variables;

      gtk.font = {inherit (resolved.sansSerif) name package size;};

      dconf.settings."org/gnome/desktop/interface" = {
        font-name = with resolved.sansSerif; "${name} ${toString size}";
        document-font-name = with resolved.serif; "${name} ${toString size}";
        monospace-font-name = with resolved.monospace; "${name} ${toString size}";
      };
    };
  }
