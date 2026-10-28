{lix, ...}: {
  # imports = [
  #   ./bat
  #   ./default
  #   ./delta
  #   ./direnv
  #   ./fastfetch
  #   ./git
  #   ./github
  #   ./gitui
  #   ./grep
  #   ./jujutsu
  #   ./nh
  #   ./nix-index
  #   ./script
  #   ./topgrade
  #   ./yazi
  # ];
  imports = lix.importAll ./.;
}
