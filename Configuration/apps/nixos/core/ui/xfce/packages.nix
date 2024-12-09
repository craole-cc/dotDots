{ pkgs, ... }:
{
  environment = {
    xfce.excludePackages = with pkgs; [ kate ];
  };
}
