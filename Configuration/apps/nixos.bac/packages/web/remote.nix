{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    tigervnc
    # rustdesk
    # anydesk
    # vncrec
  ];
}
