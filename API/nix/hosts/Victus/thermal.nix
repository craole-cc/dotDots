{config, ...}: {
  assertions = [
    {
      assertion = !(config.services.tlp.enable || config.services.auto-cpufreq.enable);
      message = "Victus power-profiles-daemon cannot share CPU policy with TLP or auto-cpufreq.";
    }
  ];

  services.power-profiles-daemon.enable = true;

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
