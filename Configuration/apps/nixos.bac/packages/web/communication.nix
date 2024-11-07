{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # thunderbird
    whatsapp-for-linux
    # skypeforlinux
    # zoom-us
  ];
}
