{
  lib,
  lix,
  ...
}: let
  inherit (lib.modules) mkForce;
  inherit (lix.filesystem.access) readFile;
  inherit (lix.strings.construction) fromJSON;

  bindings = import ./bindings.nix {};
  learnedSettings = fromJSON (readFile ./settings.json);
in {
  # Stable VS Code is the mutable learning environment. The settings captured
  # from it are the authoritative declarative baseline for Insiders; feature
  # modules still select extensions, while DMS may overlay runtime-owned theme
  # keys after this profile is evaluated.
  userSettings = mkForce learnedSettings;

  inherit (bindings) keybindings;
}
