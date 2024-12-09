{ pkgs, ... }:
let
  excludePackages = with pkgs; [ kate ];
  includePackages =
    with pkgs;
    [ kde-gruvbox ]
    ++ (with kdePackages; [
      # full
      koi
      kalm
      yakuake
    ]);
in
{
  environment = {
    plasma5 = { inherit excludePackages; };
    plasma6 = { inherit excludePackages; };
    systemPackages = includePackages;
  };
}
