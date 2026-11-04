{
  config,
  lix,
  pkgs,
  ...
}: let
  inherit (lix.sources.access) getExe';
  inherit (lix.strings.transformation) escapeShellArg;
  avatar = "${config.home.homeDirectory}/.face";
  setProfile = pkgs.writeShellScript "set-dms-profile" ''
    for attempt in $(${pkgs.coreutils}/bin/seq 1 30); do
      if ${getExe' config.programs.dank-material-shell.package "dms"} ipc call profile setImage ${escapeShellArg avatar}; then
        exit 0
      fi
      ${pkgs.coreutils}/bin/sleep 1
    done
    exit 1
  '';
in {
  home.file.".face".source = ./avatar.jpg;
  systemd.user.services.dms-profile = {
    Unit = {
      Description = "Set the DMS profile image";
      After = ["dms.service"];
      PartOf = ["dms.service"];
    };
    Service = {
      Type = "oneshot";
      ExecStart = setProfile;
    };
    Install.WantedBy = ["dms.service"];
  };
}
