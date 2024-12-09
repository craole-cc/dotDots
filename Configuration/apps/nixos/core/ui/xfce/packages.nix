{ pkgs, ... }:
{
  environment = {
    xfce.excludePackages = with pkgs; [ xterm ];
  };
}
