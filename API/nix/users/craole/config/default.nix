{
  imports = [
    ./avatar.nix
    # ./programs
    # ./services
  ];

  home.sessionPath = ["$HOME/.cargo/bin"];
}
