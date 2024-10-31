{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    sd
    copyq

    #> Launchers
    # tdrop

  ];
}
