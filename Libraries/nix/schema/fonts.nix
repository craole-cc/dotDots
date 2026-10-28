{_, ...}: let
  inherit (_.attrsets.access) attrNames attrValues;
  inherit (_.attrsets.aggregation) recursiveUpdate;
  inherit (_.attrsets.construction) listToAttrs;
  inherit (_.attrsets.transformation) mapAttrs;
  inherit (_.lists.access) elemAt length;
  inherit (_.lists.aggregation) concatMap;
  inherit (_.lists.construction) concatLists genList optional toList;
  inherit (_.lists.transformation) filter unique;
  inherit (_.strings.access) substring;
  inherit (_.strings.construction) concat;
  inherit (_.strings.transformation) toUpper;
  inherit (_.types.predicates) isAttrs isFloat isInt isString;

  ranks = rec {
    canonical = ["primary" "secondary" "tertiary"];
    variables = map (rank: toUpper (substring 0 3 rank)) canonical;
  };

  defaults = let
    noto = let
      pkg = "noto-fonts";
      mk = {
        variant,
        package ? pkg,
      }: {
        inherit package;
        family = "Noto ${variant}";
        name = "Noto ${variant}";
        style = "Regular";
        # weight = 400;
        size = 12;
      };
      mk' = variant: mk {inherit variant;};
      emoji = mk {
        variant = "Color Emoji";
        package = "${pkg}-color-emoji";
      };
      math = mk' "Math";
      mono = mk' "Mono";
      music = mk' "Music";
      sans = mk' "Sans";
      serif = mk' "Serif";
    in {inherit emoji math mono music sans serif;};
  in {
    clock = [];
    display = [];
    emoji = [noto.emoji];
    material = [];
    math = [];
    mono = [];
    monospace = [];
    music = [];
    sans = [];
    sansSerif = [];
    serif = [];
    square = [];
  };

  # canonical = alias; both keys end up populated with the same list.
  aliases = {
    monospace = "mono";
    sansSerif = "sans";
    square = "clock";
  };

  # Style -> numeric weight (fontconfig scale).
  weights = {
    Thin = 100;
    ExtraLight = 200;
    Light = 300;
    Regular = 400;
    Medium = 500;
    SemiBold = 600;
    Bold = 700;
    ExtraBold = 800;
    Heavy = 900;
    Black = 900;
  };

  normalise = fonts: let
    raw =
      recursiveUpdate (fonts.categories or {})
      (removeAttrs fonts ["categories" "packages"]);

    # Aliased roles the user actually declared, so untouched roles
    # don't override lower-priority declarations with an empty list.
    declared =
      filter
      (canonical: raw ? ${canonical} || raw ? ${aliases.${canonical}})
      (attrNames aliases);

    resolved = listToAttrs (
      map (canonical: {
        name = canonical;
        value = raw.${canonical} or raw.${aliases.${canonical}};
      })
      declared
    );

    mirrored = listToAttrs (
      map (canonical: {
        name = aliases.${canonical};
        value = resolved.${canonical};
      })
      declared
    );

    stripped =
      removeAttrs raw
      (concatMap (canonical: [canonical aliases.${canonical}]) declared);

    merged = recursiveUpdate stripped (resolved // mirrored);

    # A family name or a record -> {family, name, style, weight, size, package}.
    mkEntry = entry: let
      record =
        if isAttrs entry
        then entry
        else {family = entry;};
      family = record.family or (record.name or null);
      style = record.style or null;
      size = record.size or null;
      package = record.package or null;
      weight =
        record.weight or (
          if style != null
          then (weights.${style} or null)
          else null
        );
    in
      if !isString family || family == ""
      then throw "A font must be a family name or a record with a non-empty family."
      else if style != null && !isString style
      then throw "A font style must be a string such as Regular, Bold or Heavy."
      else if size != null && !(isInt size || isFloat size)
      then throw "A font size must be a number."
      else {
        inherit family style weight size;
        name = family;
        package =
          if isString package
          then package
          else null;
      };

    # Ranked legacy entries precede the remaining ordered selections.
    mkEntries = value: let
      entries =
        if isAttrs value && !(value ? family || value ? name)
        then
          (
            concatMap
            (rank: toList (value.${rank} or []))
            ranks.canonical
          )
          ++ toList (value.ordered or (value.list or []))
        else toList value;
    in
      unique (map mkEntry (filter (entry: entry != null) entries));
  in
    mapAttrs (category: mkEntries) merged;

  # TODO: this should use a better merger
  getFonts = definition:
    recursiveUpdate
    (normalise (definition.interface.style.fonts or {}))
    (normalise (definition.interface.fonts or {}));

  #? Whole role lists replace lower-priority declarations without truncation.
  categories = {
    host ? {},
    user ? {},
  }:
    let
      resolved = recursiveUpdate defaults (
      recursiveUpdate
      (getFonts (host
        // {
          interface =
            host.defaults.interface or (
              host.interface or {}
            );
        }))
      (getFonts user)
      );
    in
      resolved // {emoji = resolved.emoji ++ resolved.material;};

  variables = categories: let
    #? Canonical keys only, so mirrored aliases don't emit duplicates.
    stems = {
      display = ["DISPLAY"];
      emoji = ["EMOJI"];
      material = ["MATERIAL"];
      math = ["MATH"];
      monospace = ["MONO" "MONOSPACE"];
      music = ["MUSIC"];
      sansSerif = ["SANS" "SANS_SERIF"];
      serif = ["SERIF"];
      square = ["SQUARE"];
    };

    #? Null stays null so the pair is filtered out.
    show = value:
      if value == null
      then null
      else toString value;

    #? Family of the entry at the given index, or null if the list is too short.
    familyAt = entries: index:
      if length entries > index
      then (elemAt entries index).family
      else null;

    #? FONT_<STEM> plus FONT_<STEM>_PRI/_SEC/_TER for one category's entries.
    mkStem = entries: stem:
      [
        {
          name = "FONT_${stem}";
          value = familyAt entries 0;
        }
      ]
      ++ genList (index: {
        name = "FONT_${stem}_${elemAt ranks.variables index}";
        value = familyAt entries index;
      }) (length ranks.variables);

    #? Style, weight and size of the primary entry only.
    mkMeta = entries: stem: let
      first =
        if length entries > 0
        then elemAt entries 0
        else {};
    in [
      {
        name = "FONT_${stem}_STYLE";
        value = first.style or null;
      }
      {
        name = "FONT_${stem}_WEIGHT";
        value = show (first.weight or null);
      }
      {
        name = "FONT_${stem}_SIZE";
        value = show (first.size or null);
      }
    ];

    pairs =
      concatMap
      (
        category: let
          entries = categories.${category} or [];
        in
          concatMap
          (stem: mkStem entries stem ++ mkMeta entries stem)
          stems.${category}
      )
      (attrNames stems);
  in
    listToAttrs (filter (pair: pair.value != null) pairs);

  packages = categories: let
    fonts = concatLists (attrValues categories);
    names = map (font: font.package) fonts;
  in
    unique (filter isString names);

  families = categories: let
    #? CSS generic appended to each role's list; roles without one get none.
    generics = {
      mono = "monospace";
      monospace = "monospace";
      sans = "sans-serif";
      sansSerif = "sans-serif";
      serif = "serif";
    };

    #? Quoted family names in preference order, then the generic fallback.
    mk = category: entries: let
      quoted = map (entry: "'${entry.family}'") entries;
      generic = generics.${category} or null;
    in
      concat ", " (quoted ++ (optional (generic != null) generic));
  in
    mapAttrs mk categories;

  mkFonts = args: let
    resolved = categories args;
  in {
    categories = resolved;
    families = families resolved;
    packages = packages resolved;
    variables = variables resolved;
  };
in {inherit aliases categories defaults getFonts mkFonts normalise packages variables weights;}
