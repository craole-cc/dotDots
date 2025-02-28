{ lib, ... }:
let
  systems = [
    # systems = lib.attrValues (lib.mapAttrsToList (_name: host: host.system) hosts);
    # systems = lib.attrValues (lib.mapAttrsToList (hostName: host: host.system) hosts);
    #TODO: This is extra code for no reason. We should get this information from the hosts, simply lookfor the system value in each host.

    "x86_64-linux"
    "aarch64-linux"
  ];

  clients = {
    victus = {
      name = "victus";
      id = "444CC9B3";
      context = [ "laptop" ];
      profile = [
        "development"
        "gaming"
        "productivity"
      ];
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMNDko91cBLITGetT4wRmV1ihq9c/L20sUSLPxbfI0vE root@victus";
      age = "age1j5cug724x386nygk8dhc38tujhzhp9nyzyelzl0yaz3ndgtq3qwqxtkfpv";
      system = "x86_64-linux";
      cpu = "amd";
      gpu = "nvidia";
      services = [
        # "nvidia" #TODO: Fix this
        "ssh"
        "sops"
      ];
      keyboard = {
        modifier = "Super";
        swapCapsEscape = true;
      };
    };

    dbooktoo = {
      name = "dbooktoo";
      id = "444OO8D6";
      context = [ "laptop" ];
      profile = [ "development" ];
      system = "x86_64-linux";
      cpu = "intel";
      timezone = "America/Jamaica";
      locale = "en_US.UTF-8";
      frequency = "weekly";
      autoLogin = true;
      keyboard = {
        modifier = "Alt Control";
        swapCapsEscape = false;
      };
    };

    raspi = {
      name = "raspi";
      type = "server";
      key = "";
      system = "aarch64-linux";
    };
  };
in
with lib;
with types;
{
  options.coreArgs = {
    systems = mkOption {
      description = "Common arguments";
      type = attrs;
      default = systems;
    };
    clients = mkOption {
      description = "Common arguments";
      type = attrs;
      default = clients;
    };
  };
}
