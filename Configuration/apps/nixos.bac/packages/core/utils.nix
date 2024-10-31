{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    coreutils
    binutils
    gcc
    openssl
    pkg-config
    killall
    findutils
    extundelete
    foremost
    trashy
  ];
}
