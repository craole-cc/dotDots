{ specialArgs, ... }:
if specialArgs.ui.env == "xfce" then
  {
    imports = [
      ./packages.nix
      ./services.nix
    ];
  }
else
  { }
