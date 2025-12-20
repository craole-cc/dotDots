{lix, ...}: {
  imports =
    lix.importAll ./common
    ++ [
      ./apps.nix

      ./atuin
      ./bash
      ./firefox
      ./foot
      ./freetube
      ./ghostty
      ./helix
      # ./niri
      ./nushell
      ./obs
      ./starship
      # ./tinty # TODO: Not ready yet
      ./vscode
      ./zed
    ];
}
