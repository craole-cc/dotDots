{
  services.espanso = {
    configs = import ./configs.nix;
    matches = import ./matches.nix;
  };
}
