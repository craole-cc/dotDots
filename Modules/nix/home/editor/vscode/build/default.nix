args: let
  inherit (args) profile;
  app = import ./variant.nix (args // {inherit profile;});
  activation = import ./activation.nix (args
    // {
      inherit app profile;
      dms = import ./dms.nix (args // {inherit app;});
    });
in {inherit activation app profile;}
