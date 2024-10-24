{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    grafana
  ];
}
