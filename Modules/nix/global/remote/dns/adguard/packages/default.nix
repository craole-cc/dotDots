{
  pkgs,
  lix,
  lib,
  ...
}: let
  inherit (pkgs) adguardhome bind coreutils curl process-compose systemd writeShellApplication;
  dig = bind.dnsutils;
  inherit (lix.filesystem.access) readFile;
  inherit (lib) target tag set;

  serviceFile = pkgs.writeText "adguardhome.service" (readFile ../systemd/adguardhome.service);

  env' =
    set "PROCESS_FILE" (toString ./process-compose.yaml)
    // set "SYSTEMD_UNIT" (toString serviceFile);

  entries = [
    {
      name = "install-service";
      description = "Install and enable the systemd service on TheOracle";
      runtimeInputs = [adguardhome coreutils systemd];
      script = ./install-service.sh;
    }
    {
      name = "run";
      description = "Run ${target} in the foreground with process-compose";
      runtimeInputs = [adguardhome process-compose];
      script = ./run.sh;
    }
    {
      name = "status";
      description = "Check ${target} DNS and web listeners";
      runtimeInputs = [bind curl dig];
      script = ./status.sh;
    }
    {
      name = "verify";
      description = "Resolve a domain through ${target} and check Web UI";
      runtimeInputs = [bind curl dig];
      script = ./verify.sh;
    }
  ];

  scripts = map (entry:
    writeShellApplication {
      name = tag entry.name;
      inherit (entry) runtimeInputs;
      text = readFile entry.script;
    })
  entries;

  helpEntries =
    map (entry: {
      command = tag entry.name;
      inherit (entry) description;
    })
    entries;
in {
  env = env';
  packages = [adguardhome process-compose bind curl dig] ++ scripts;
  inherit helpEntries;
}
