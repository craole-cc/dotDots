{
  config,
  lix,
  pkgs,
  ...
}: let
  inherit (lix.sources.access) getExe';
  inherit (lix.strings.transformation) escapeShellArg;
  avatar = "${config.home.homeDirectory}/.face";
  dms = getExe' config.programs.dank-material-shell.package "dms";
  setProfile = pkgs.writeShellScript "set-dms-profile" ''
    for attempt in $(${pkgs.coreutils}/bin/seq 1 30); do
      # DMS can return "Target not found." with exit status zero during startup.
      if response="$(${dms} ipc call profile setImage ${escapeShellArg avatar})"; then
        case "$response" in
          "SUCCESS: Profile image set to "*)
            if current="$(${dms} ipc call profile getImage)" && [ "$current" = ${escapeShellArg avatar} ]; then
              exit 0
            fi
            ;;
        esac
      fi
      ${pkgs.coreutils}/bin/sleep 1
    done
    echo "DMS did not confirm the configured profile image" >&2
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
      RemainAfterExit = true;
      ExecStart = setProfile;
    };
    Install.WantedBy = ["dms.service"];
  };
}
