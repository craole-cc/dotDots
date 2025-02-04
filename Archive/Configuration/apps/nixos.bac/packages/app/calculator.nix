{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    #> Graphics
    bc
    fend
    qalculate-gtk
  ];
}
