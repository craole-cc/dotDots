{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
      qalculate-qt
      wlprop
    ];
}
