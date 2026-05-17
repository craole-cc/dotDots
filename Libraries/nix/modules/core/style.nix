{
  lib,
  # paths,
  ...
}: let
  meta = let
    doc = ''
      # Core Style [Layer 3]

      NixOS system configuration builders for visual/style concerns.

      ## Builders

      ### Data builders (pure attrsets, no NixOS config)

      - `resolveWallpapers`  - resolves wallpaper image, file, and search dirs per polarity
      - `resolveIcons`       - icon theme attrset per polarity
      - `resolveThemes`       - base16 theme attrset per polarity (wraps resolveCatppuccin)
      - `resolveCatppuccin`  - full Catppuccin theme + cursor data for any accent/variant
      - `resolveCursors`     - cursor name/package/size per polarity
      - `resolveOpacity`     - opacity settings per polarity
      - `resolveFonts`       - resolved font sets ({ name, package } per role) + package list

      ### NixOS config builders

      - `mkStyle`  - emits `fonts.fontconfig`, `fonts.packages`, optionally `stylix.*`,
                     and `environment.sessionVariables` for theme/wallpaper/cursor/fonts

      ## Polarity

      All data builders return `{ light = {...}; dark = {...}; }`.
      `mkStyle` selects the active variant via `polarity` (default: `"dark"`).
      Changing `polarity` flips theme, cursor, wallpaper, icons, and opacity atomically.
      Font data (`resolveFonts`) is not polarity-split - fonts are consistent across polarities.

      ## Wallpapers

      `resolveWallpapers` resolves three path concepts per polarity:

      - `image`  - current wallpaper file (nix store path from flake assets at `path`)
      - `file`   - dots asset path for activation script copy target
      - `dirs`   - ordered list of directories for wallpaper cyclers

      ## Catppuccin

      `resolveCatppuccin` derives cursor packages automatically from `variant` + `accent`:

        variant.dark = "frappe" + accent = "teal"
        → pkgs.catppuccin-cursors.frappeTeal

      Supported dark variants: `frappe`, `macchiato`, `mocha`. Light is always `latte`.

      ## Stylix

      Stylix integration is opt-in via `enableStylix = true` in `mkStyle`.
      When disabled, font and wallpaper session variables are still emitted.
      `stylix.targets.qt` is always disabled - Qt theming is handled separately.

      ## Dependencies

      - `lib.attrsets`  - optionalAttrs, recursiveUpdate
      - `lib.modules`   - mkForce, mkMerge
      - `lib.strings`   - hasInfix, hasPrefix, toUpper, substring
    '';
    exports = {
      local = {
        inherit
          resolveCatppuccin
          resolveFonts
          resolveIcons
          mkStyle
          resolveThemes
          resolveWallpapers
          ;
      };
      alias = {
        resolveCoreCatppuccin = resolveCatppuccin;
        resolveCoreFonts = resolveFonts;
        resolveCoreIcons = resolveIcons;
        mkCoreStyle = mkStyle;
        resolveCoreTheme = resolveThemes;
        resolveCoreWallpapers = resolveWallpapers;
      };
    };
  in {inherit doc exports;};
  inherit (lib.attrsets) optionalAttrs recursiveUpdate;
  inherit (lib.modules) mkForce mkMerge;
  inherit (lib.strings) hasInfix toUpper substring;

  isIn = check: value: hasInfix (toUpper check) (toUpper value);
  toPascal = s: toUpper (substring 0 1 s) + substring 1 (-1) s;

  resolveWallpapers = {
    tree,
    dots ? "$DOTS",
    pics ? "$HOME/Pictures",
    light ? {},
    dark ? {},
    ...
  }: let
    file = "/default.jpg";

    bases = {
      user = "/Wallpapers";
      dots = "/Assets/Images/wallpaper";
    };

    repos =
      {
        # path = paths.src + bases.dots;
        path = tree.store.default + bases.dots;
        dots = dots + bases.dots;
        user = pics + bases.user;
      }
      // {common = with repos; [dots user path];};

    get = polarity: let
      stem = "/" + polarity;
      stemAlt = "/" + (toPascal polarity);
    in {
      image = repos.path + stem + file;
      file = repos.dots + stem + file;
      dirs = with repos;
        [
          (dots + stem)
          (user + stemAlt)
          (user + stem)
        ]
        ++ common;
    };
  in
    recursiveUpdate {
      light = get "light";
      dark = get "dark";
    } {inherit light dark;};

  resolveCatppuccin = {
    pkgs,
    accent ? "teal",
    variant ? {
      light = "latte";
      dark = "frappe";
    },
    cursors ? {},
    themes ? {},
  }: let
    getCursor = polarity: {
      name = "catppuccin-${variant.${polarity}}-${accent}-cursors";
      package = pkgs.catppuccin-cursors.${variant.${polarity} + (toPascal accent)};
      size = cursors.size or 24;
    };

    getTheme = polarity:
      {package = pkgs.catppuccin;}
      // (
        if polarity == "light"
        then {
          name = "Catppuccin Latte";
          scheme = "catppuccin-latte";
          variant = variant.light;
        }
        else if isIn "macchiato" variant.dark
        then {
          name = "Catppuccin Macchiato";
          scheme = "catppuccin-macchiato";
          variant = variant.dark;
        }
        else if isIn "mocha" variant.dark
        then {
          name = "Catppuccin Mocha";
          scheme = "catppuccin-mocha";
          variant = variant.dark;
        }
        else if isIn "frappe" variant.dark
        then {
          name = "Catppuccin Frappé";
          scheme = "catppuccin-frappe";
          variant = variant.dark;
        }
        else
          throw "resolveCatppuccin: unsupported dark variant `${
            variant.dark
          }`; expected: frappe, macchiato, mocha"
      );
  in {
    themes =
      recursiveUpdate {
        inherit accent variant;
        light = getTheme "light";
        dark = getTheme "dark";
      }
      themes;
    cursors =
      recursiveUpdate {
        inherit accent variant;
        light = getCursor "light";
        dark = getCursor "dark";
      }
      cursors;
  };

  resolveCursors = {
    pkgs,
    light ? {},
    dark ? {},
    size ? null,
    accent ? null,
    variant ? null,
  }:
  # }: let
  # _material = let
  #   get = polarity: {
  #     size =
  #       if size != null
  #       then size
  #       else 32;
  #     name = "material_${polarity}_cursors";
  #     package = pkgs.material-cursors;
  #   };
  # in {
  #   light = get "light";
  #   dark = get "dark";
  # };
  # catppuccin = resolveCatppuccin (
  #   {
  #     inherit pkgs;
  #     cursor.size =
  #       if size != null
  #       then size
  #       else 24;
  #   }
  #   // optionalAttrs (accent != null) {inherit accent;}
  #   // optionalAttrs (variant != null) {inherit variant;}
  # );
  # default = catppuccin.cursors;
  # in
  # recursiveUpdate default {inherit light dark;};
    recursiveUpdate ((resolveCatppuccin (
      {
        inherit pkgs;
        cursors =
          {inherit light dark;}
          // optionalAttrs (size != null) {inherit size;};
      }
      // optionalAttrs (accent != null) {inherit accent;}
      // optionalAttrs (variant != null) {inherit variant;}
    )).cursors) {inherit light dark;};

  resolveThemes = {
    pkgs,
    light ? {},
    dark ? {},
    accent ? null,
    variant ? null,
  }:
    recursiveUpdate ((resolveCatppuccin (
      {
        inherit pkgs;
        themes = {inherit light dark;};
      }
      // optionalAttrs (accent != null) {inherit accent;}
      // optionalAttrs (variant != null) {inherit variant;}
    )).themes) {inherit light dark;};

  resolveIcons = {
    pkgs,
    light ? {},
    dark ? {},
  }: let
    package = pkgs.candy-icons;
    default = {
      inherit package;
      name = package.pname;
    };
  in
    recursiveUpdate {
      light = default;
      dark = default;
    } {inherit light dark;};

  resolveFonts = {
    pkgs,
    clock ? {},
    emoji ? {},
    material ? {},
    monospace ? {},
    sansSerif ? {},
    serif ? {},
    packages ? [],
    ...
  }: let
    sets = recursiveUpdate {
      clock = {
        name = "Rubik";
        package = pkgs.rubik;
      };
      emoji = {
        name = "Noto Color Emoji";
        package = pkgs.noto-fonts-color-emoji;
      };
      material = {
        name = "Material Symbols Sharp";
        package = pkgs.material-symbols;
      };
      monospace = {
        name = "Maple Mono NF";
        package = pkgs.maple-mono.NF-unhinted;
      };
      sansSerif = {
        name = "Monaspace Radon Frozen";
        package = pkgs.monaspace;
      };
      serif = {
        name = "Noto Serif";
        package = pkgs.noto-fonts;
      };
    } {inherit clock emoji material monospace sansSerif serif;};
  in {
    inherit sets;
    packages =
      packages
      ++ (with pkgs; [
        corefonts
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
      ])
      ++ (with sets; [
        clock.package
        emoji.package
        material.package
        monospace.package
        sansSerif.package
        serif.package
      ]);
  };

  resolveOpacity = {
    terminal ? 0.9,
    popups ? 0.95,
    light ? {},
    dark ? {},
  }: let
    default = {inherit terminal popups;};
  in
    recursiveUpdate {
      light = default;
      dark = default;
    } {inherit light dark;};

  mkStyle = {
    pkgs,
    tree,
    polarity ? "dark",
    accent ? null,
    variant ? null,
    cursors ? (resolveCursors {inherit pkgs;}),
    fonts ? (resolveFonts {inherit pkgs;}),
    icons ? (resolveIcons {inherit pkgs;}),
    opacity ? (resolveOpacity {}),
    theme ? (resolveThemes {inherit pkgs accent variant;}),
    wallpapers ? (resolveWallpapers {inherit tree;}),
    enableStylix ? false,
    ...
  }: let
    polarized = {
      cursors = cursors.${polarity};
      icons = icons.${polarity};
      theme = theme.${polarity};
      opacity = opacity.${polarity};
      wallpapers = wallpapers.${polarity};
    };
  in
    {
      environment.sessionVariables = (
        {THEME_POLARITY = polarity;}
        // (
          optionalAttrs
          ((polarized.theme.name or null) != null)
          {THEME_NAME = polarized.theme.name;}
        )
        // (
          optionalAttrs
          ((polarized.theme.variant or null) != null)
          {THEME_VARIANT = polarized.theme.variant;}
        )
        // (
          optionalAttrs
          ((polarized.theme.accent or null) != null)
          {THEME_ACCENT = polarized.theme.accent;}
        )
        // (with polarized.wallpapers; {
          WALLPAPER = toString image;
          WALLPAPERS = toString dirs;
        })
        // (
          with fonts.sets; {
            FONT_MONOSPACE = monospace.name;
            FONT_SANS = sansSerif.name;
            FONT_SERIF = serif.name;
            FONT_EMOJI = emoji.name;
          }
        )
      );

      fonts = {
        inherit (fonts) packages;
        enableDefaultPackages = true;
        fontconfig = {
          enable = true;
          antialias = true;
          hinting = {
            enable = true;
            style = "slight";
          };
          subpixel.rgba = "rgb";
          defaultFonts = with fonts.sets; {
            monospace = [monospace.name];
            sansSerif = [sansSerif.name];
            serif = [serif.name];
            emoji = [emoji.name];
          };
        };
      };
    }
    // (
      optionalAttrs
      (enableStylix && (polarized.theme.name or null) != null)
      (mkMerge [
        {
          stylix = {
            inherit polarity;
            inherit (polarized) opacity;
            inherit (polarized.wallpapers) image;
            enable = true;
            base16Scheme = with polarized.theme; "${package}/share/themes/${scheme}.yaml";

            cursor = {
              inherit (polarized.cursors) name package size;
            };
            fonts = {
              inherit (fonts.sets) emoji monospace sansSerif serif;
            };
            # icons = {
            #   inherit (polarized.icons) package light dark;
            # };
            targets.qt.enable = mkForce false;
          };
        }
      ])
    );
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
