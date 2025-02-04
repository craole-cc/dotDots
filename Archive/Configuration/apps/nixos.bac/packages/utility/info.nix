{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    #> System/Process
    btop
    procs
    hyperfine
    macchina
    neofetch
    cpufetch
    # strace
    # ltrace
    # kmon

    #> Network
    bandwhich
    # speedtest-cli
    ookla-speedtest

    #> Notification
    dunst
    tiramisu
    libnotify

    #> Help
    tealdeer

    #> Code
    tokei
    kondo

    #> Regex
    grex

    #> Password
    bitwarden

    #> Hardware
    dmidecode
    acpi
    hwdata
    pciutils
    smartmontools
    iotop
    lm_sensors
    rtw88-firmware
    nmap
  ];
}
