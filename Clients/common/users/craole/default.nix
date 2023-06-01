{
  pkgs,
  config,
  ...
}: let
  ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in {
  users.mutableUsers = false;
  users.users.craole = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups =
      [
        "wheel"
        "video"
        "audio"
      ]
      ++ ifTheyExist [
        "network"
        "wireshark"
        "i2c"
        "mysql"
        "docker"
        "podman"
        "git"
        "libvirtd"
        "deluge"
      ];

    openssh.authorizedKeys.keys = [(builtins.readFile ../../../../Home/craole/keys/ssh.pub)];
    passwordFile = config.sops.secrets.craole-password.path;
    packages = [pkgs.home-manager];
  };

  sops.secrets.craole-password = {
    sopsFile = ../../secrets.yaml;
    neededForUsers = true;
  };

  home-manager.users.craole = import ../../../../Home/craole/${config.networking.hostName}.nix;

  services.geoclue2.enable = true;
  security.pam.services = {swaylock = {};};
}
