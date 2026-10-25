{
  inputs,
  lix,
  pkgs,
  ...
}: let
  inherit (lix.sources.packages) pkgsFrom;
  tools = pkgsFrom {
    inherit inputs pkgs;
    sources = {
      coreutils = null;
      dms-shell = null;
      diffutils = {exe = "cmp";};
      gum = null;
      glib = null;
      jaq = null;
      procps = {exe = "pkill";};
      quickshell = null;
      ripgrep = null;
      sd = null;
      systemd = null;
    };
    required = true;
  };

  package = import ./package.nix tools.dms-shell.package;

  bins = let
    inherit (tools) binaries;
    coreutils = "${tools.coreutils.paths.binary}";
    glib = "${tools.glib.paths.binary}";
  in rec {
    inherit (binaries) gum jaq sd;
    systemctl = "${tools.systemd.paths.binary}/systemctl";
    cmp = binaries.diffutils;
    cksum = "${coreutils}/cksum";
    cat = "${coreutils}/cat";
    chmod = "${coreutils}/chmod";
    dirname = "${coreutils}/dirname";
    dms = "${package}/bin/dms";
    dmsCall = "${dms} ipc call";
    dmsSet = "${dmsCall} settings set";
    gCall = "${glib}/gdbus call";
    gSet = "${gsettings} set";
    gSetDI = "${gSet} org.gnome.desktop.interface";
    gsettings = "${glib}/gsettings";
    install = "${coreutils}/install";
    mkdir = "${coreutils}/mkdir";
    mktemp = "${coreutils}/mktemp";
    mv = "${coreutils}/mv";
    pkill = binaries.procps;
    rg = binaries.ripgrep;
    rm = "${coreutils}/rm";
    readlink = "${coreutils}/readlink";
  };
in {inherit tools bins package;}
