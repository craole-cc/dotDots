{user, ...}: {
  enable = true;
  settings =
    import ./settings.nix
    // import ./bindings.nix {inherit user;};
  style = import ./style.nix;
}
