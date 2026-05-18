{_, ...}: let
  meta = let
    doc = ''
      Style resolution (Layer 3).

      ## Functions

      - `cursor`  - { pkgs, polarity, accent?, flavors?, size? } -> { name, package, size }
      - `cursors` - { pkgs, accent?, flavors?, size? } -> { light, dark }
      - `theme`   - { polarity, accent?, flavors? } -> { name, flavor, accent, polarity }
      - `themes`  - { accent?, flavors? } -> { light, dark }
      - `resolve` - { pkgs, accent?, flavors?, size? } -> { cursors, themes }
    '';
    exports = {
      local = {
        inherit defaults cursor cursors theme themes resolve;
      };
      alias = {
        resolveCursor = cursor;
        resolveCursors = cursors;
        resolveTheme = theme;
        resolveThemes = themes;
        resolveStyle = resolve;
      };
    };
  in {inherit doc exports;};

  inherit (_.attrsets.access) attrNames attrValues;
  inherit (_.attrsets.aggregation) recursiveUpdate mapAttrsToList;
  inherit (_.content.emptiness) isEmpty;
  inherit (_.lists.transformation) uniqueStrings;
  inherit (_.lists.aggregation) foldl';
  inherit (_.lists.predicates) isIn;
  # inherit (_.sources.packages) getPackage;# TODO: Include when available
  inherit (_.attrsets.resolution) getPackage; # TODO: Exclude when unavailable
  inherit (_.strings.transformation) toTitleCase toLowerCase;
  inherit (_.strings.construction) concat;

  defaults = {
    accent = "teal";
    accents = {
      light = "sapphire";
      dark = "sky";
    };
    flavors = {
      light = "latte";
      dark = "frappe";
    };
    size = 24;
  };

  enums = {
    accents = let
      known = {
        rosewater = {
          aliasMap = {
            rose = "rosewater";
            "rosé" = "rosewater";
          };
        };

        flamingo = {
          aliasMap = {
            coral = "flamingo";
          };
        };

        pink = {
          aliasMap = {
            hotpink = "pink";
            hot-pink = "pink";
          };
        };

        mauve = {
          aliasMap = {
            purple = "mauve";
            violet = "mauve";
          };
        };

        red = {
          aliasMap = {
            scarlet = "red";
          };
        };

        maroon = {
          aliasMap = {
            burgundy = "maroon";
            wine = "maroon";
          };
        };

        peach = {
          aliasMap = {
            orange = "peach";
            apricot = "peach";
          };
        };

        yellow = {
          aliasMap = {
            gold = "yellow";
          };
        };

        green = {
          aliasMap = {
            lime = "green";
          };
        };

        teal = {
          aliasMap = {
            cyan = "teal";
            aqua = "teal";
            turquoise = "teal";
          };
        };

        sky = {
          aliasMap = {
            lightblue = "sky";
            light-blue = "sky";
          };
        };

        sapphire = {
          aliasMap = {
            azure = "sapphire";
            cerulean = "sapphire";
          };
        };

        blue = {
          aliasMap = {
            navy = "blue";
            cobalt = "blue";
          };
        };

        lavender = {
          aliasMap = {
            lilac = "lavender";
            magenta = "lavender";
          };
        };
      };

      names = attrNames known;

      aliases =
        foldl'
        recursiveUpdate
        {}
        (mapAttrsToList (_: value: value.aliasMap or {}) known);

      check = input: let
        value = toLowerCase input;
        normalized = aliases.${value} or value;
      in
        if isIn normalized names
        then normalized
        else throw "Invalid Catppuccin accent `${input}`. Expected one of: ${concat ", " names}";
    in {
      inherit names aliases check;
    };

    flavors = let
      known = {
        latte = {
          aliasMap = {
            light = "latte";
            day = "latte";
            daytime = "latte";
            morning = "latte";
            sun = "latte";
          };
        };

        frappe = {
          aliasMap = {
            "frappé" = "frappe";
            muted = "frappe";
            soft = "frappe";
            dusk = "frappe";
            evening = "frappe";
          };
        };

        macchiato = {
          aliasMap = {
            mac = "macchiato";
            mid = "macchiato";
            medium = "macchiato";
            cozy = "macchiato";
            rainy = "macchiato";
          };
        };

        mocha = {
          aliasMap = {
            dark = "mocha";
            night = "mocha";
            darkest = "mocha";
            original = "mocha";
          };
        };
      };

      names = attrNames known;

      aliases =
        foldl'
        recursiveUpdate
        {}
        (mapAttrsToList (_: value: value.aliasMap or {}) known);

      check = input: let
        value = toLowerCase input;
        normalized = aliases.${value} or value;
      in
        if isIn normalized names
        then normalized
        else throw "Invalid Catppuccin flavor `${input}`. Expected one of: ${concat ", " names}";
    in {
      inherit names aliases check;
    };
  };

  cursor = {
    pkgs,
    polarity,
    accents ? defaults.accent,
    flavors ? defaults.flavors,
    size ? defaults.size,
  }: let
    accent = accents.${polarity};
    flavor = flavors.${polarity};
  in {
    name = "catppuccin-${flavor}-${accent}-cursors";
    package = pkgs.catppuccin-cursors.${flavor + (toTitleCase accent)};
    inherit size;
  };

  cursors = {
    pkgs,
    accents ? defaults.accent,
    flavors ? defaults.flavors,
    size ? defaults.size,
  }: let
    mk = polarity: cursor {inherit pkgs accents flavors size polarity;};
  in {
    light = mk "light";
    dark = mk "dark";
  };

  theme = {
    pkgs,
    polarity,
    accents ? defaults.accents,
    flavors ? defaults.flavors,
  }: let
    target = "catppuccin";
    accent = enums.accents.check accents.${polarity};
    flavor = enums.flavors.check flavors.${polarity};
  in {
    inherit flavor accent;
    name = toTitleCase (concat " " [target flavor]);
    scheme = concat "-" [target flavor];
    package = getPackage {inherit pkgs target;};
  };

  themes = {
    pkgs,
    accent ? defaults.accent,
    flavors ? defaults.flavors,
  }: let
    mk = polarity: cursor {inherit pkgs accent flavors polarity;};
  in {
    light = mk "light";
    dark = mk "dark";
  };

  resolve = {
    pkgs,
    accents ? defaults.accent,
    flavors ? defaults.flavors,
    size ? defaults.size,
  }: {
    cursors = cursors {inherit pkgs accents flavors size;};
    themes = themes {inherit pkgs accents flavors;};
  };
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
