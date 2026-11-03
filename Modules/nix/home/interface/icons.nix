{
  inputs,
  lix,
  pkgs,
  style,
  ...
}: let
  inherit (lix.lists.predicates) isIn;
  inherit (lix.options.construction) mkOption;
  inherit (lix.styles.icons) mkOne;
  inherit (lix.types.primitives) str;

  buufIcons = pkgs.stdenvNoCC.mkDerivation {
    pname = "buuf-icons";
    version = "unstable-2026-10-12";
    src = inputs.buuf-icons;
    dontConfigure = true;
    dontBuild = true;
    installPhase = ''
      runHook preInstall
      mkdir -p "$out/share/icons/Buuf"
      cp -R "$src"/. "$out/share/icons/Buuf/"
      runHook postInstall
    '';
  };

  resolveIcon = polarity: requested:
    if isIn requested ["buuf-nestort" "buufIcons" "buuf" "buuf-icons"]
    then {
      name = "Buuf";
      package = buufIcons;
    }
    else if isIn requested ["candy-icons" "candy"]
    then {
      name = "candy-icons";
      package = pkgs.candy-icons;
    }
    else
      mkOne {
        inherit pkgs polarity;
        icon = requested;
      };
in {
  options.themes.icons = {
    dark = mkOption {
      type = str;
      default = style.icons.dark;
      description = "Icon theme requested for dark mode";
      apply = resolveIcon "dark";
    };
    light = mkOption {
      type = str;
      default = style.icons.light;
      description = "Icon theme requested for light mode";
      apply = resolveIcon "light";
    };
  };
}
