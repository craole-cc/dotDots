{
  config,
  pkgs,
  ...
}: {
  assertions = [
    {
      assertion = !(config.services.tlp.enable || config.services.auto-cpufreq.enable);
      message = "Victus power-profiles-daemon cannot share CPU policy with TLP or auto-cpufreq.";
    }
  ];

  services.power-profiles-daemon.enable = true;
  #? Preserve the global boost limit while PPD changes governor and EPP.
  services.power-profiles-daemon.package = pkgs.power-profiles-daemon.overrideAttrs (previous: {
    patches = (previous.patches or []) ++ [./ppd-respect-global-boost.patch];
  });

  #? Start balanced; later selections, including performance, stay user-controlled.
  systemd.services.default-power-profile = {
    description = "Select the default Victus power profile";
    wantedBy = ["multi-user.target"];
    requires = ["disable-cpu-boost.service" "power-profiles-daemon.service"];
    after = ["disable-cpu-boost.service" "power-profiles-daemon.service"];
    serviceConfig.Type = "oneshot";
    script = ''
      test "$(cat /sys/devices/system/cpu/cpufreq/boost)" = 0
      ${config.services.power-profiles-daemon.package}/bin/powerprofilesctl set balanced
      test "$(cat /sys/devices/system/cpu/cpufreq/boost)" = 0
    '';
  };

  systemd.services.disable-cpu-boost = {
    description = "Disable CPU boost on Victus";
    wantedBy = ["multi-user.target"];
    after = ["systemd-modules-load.service" "power-profiles-daemon.service"];
    serviceConfig.Type = "oneshot";
    script = ''
      boost=/sys/devices/system/cpu/cpufreq/boost
      test -w "$boost" || { echo "CPU boost control is unavailable" >&2; exit 1; }
      printf '0\n' > "$boost"
      test "$(cat "$boost")" = 0 || { echo "CPU boost remained enabled" >&2; exit 1; }
    '';
  };

  powerManagement.resumeCommands = ''
    boost=/sys/devices/system/cpu/cpufreq/boost
    test -w "$boost" || { echo "CPU boost control is unavailable after resume" >&2; exit 1; }
    printf '0\n' > "$boost"
    test "$(cat "$boost")" = 0 || { echo "CPU boost remained enabled after resume" >&2; exit 1; }
  '';
}
