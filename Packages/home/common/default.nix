{lix, ...}: {
  imports =
    (lix.importAll ./.)
    ++ [
      ./fetchers
      ./vsc
      ./vim

      #   # ./default
      #   # ./delta
      #   # ./direnv
      #   # ./fastfetch
      #   # ./github
      #   # ./gitui
      #   # ./grep
      #   # ./jujutsu
      #   # ./nh
      #   # ./nix-index
      #   # ./script
      #   # ./topgrade
      #   # ./yazi
    ];
}
