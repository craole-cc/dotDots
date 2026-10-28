# alias = {cmd = [binary arg...]; doc = null | "...";}
# The head of `cmd` must be a key of the resolved binaries; the tail is
# shell-escaped when rendered. Long options that used to be glued
# (`--reference=`, `-I{}`) use the equivalent space-separated form.
let
  a = cmd: {
    inherit cmd;
    doc = null;
  };
  ad = cmd: doc: {inherit cmd doc;};
in {
  #> coreutils
  chmod0644 = a ["chmod" "0644"];
  chmodR = a ["chmod" "-R"];
  chmodRef = ad ["chmod" "--reference"] "copy mode from a reference file (caller supplies it)";
  chmodRuw = a ["chmod" "-R" "u+w"];
  cpa = a ["cp" "-a" "--reflink=auto"];
  cpaf = ad ["cp" "-af" "--reflink=auto"] "force version of cpa";
  dateI = ad ["date" "-I"] "ISO date";
  dateIs = ad ["date" "-Is"] "ISO date + time";
  headn = a ["head" "-n"];
  installD = ad ["install" "-D"] "create parent dirs";
  installDm = ad ["install" "-D" "-m"] "caller supplies the mode";
  install0644 = ad ["install" "-D" "-m" "0644"] "mode 0644, parent dirs created";
  install0600 = ad ["install" "-D" "-m" "0600"] "mode 0600, parent dirs created";
  installm = ad ["install" "-m"] "caller supplies the mode";
  lnsf = ad ["ln" "-sf"] "force symlink"; # was `lnSf` (= `-S f`, not what was meant)
  lnsfn = a ["ln" "-sfn"];
  mkdirp = a ["mkdir" "-p"];
  mktempd = a ["mktemp" "-d"];
  mvt = a ["mv" "-T"];
  mvf = a ["mv" "-f"];
  readlinkf = a ["readlink" "-f"];
  rmrf = a ["rm" "-rf"]; # was `rmf`
  sortn = a ["sort" "-n"];
  sortu = a ["sort" "-u"];
  sortV = a ["sort" "-V"];
  tailF = ad ["tail" "-F"] "follow by name, survives log rotation"; # was `tailf` (-f)
  tailn = a ["tail" "-n"];
  teea = a ["tee" "-a"];
  wcc = a ["wc" "-c"];
  wcl = a ["wc" "-l"];
  wcw = a ["wc" "-w"];

  #> finders (modern)
  fdh = a ["fd" "--hidden" "--no-ignore"];
  rgi = a ["rg" "-i"];
  rg0 = a ["rg" "--null"];
  rgq = a ["rg" "-q"];
  rgFxq = a ["rg" "-Fxq"];
  jaqr = a ["jaq" "-r"];
  jaqna = a ["jaq" "-n" "--arg"];
  jaqRr = a ["jaq" "-Rr"];

  #> findutils
  find0 = a ["find" "-print0"];
  grepr = a ["grep" "-r"];
  grepri = a ["grep" "-ri"];
  sedi = a ["sed" "-i"];
  xargs0 = a ["xargs" "-0"];
  xargsr = ad ["xargs" "-r"] "don't run if stdin is empty";
  xargsI = a ["xargs" "-I" "{}"];

  #> difftools
  cmps = a ["cmp" "-s"];

  #> git
  gitCfgFile = a ["git" "config" "--file"];

  #> glib
  gCall = a ["gdbus" "call"];
  gSet = a ["gsettings" "set"];
  gSetDI = a ["gsettings" "set" "org.gnome.desktop.interface"];

  #> gnupatch
  patchd = a ["patch" "-d"];

  #> ouch
  pack = a ["ouch" "compress"];
  unpack = a ["ouch" "decompress"];

  #> procps
  pgrepf = a ["pgrep" "-f"];
  pgrepa = ad ["pgrep" "-a"] "show full command line";
  pkillf = a ["pkill" "-f"];
  pkillUSR1 = a ["pkill" "-USR1"];
  pkillUSR1x = a ["pkill" "-USR1" "-x"];
  pkillUSR2 = a ["pkill" "-USR2"];
  pkillUSR2x = a ["pkill" "-USR2" "-x"];

  #> systemd
  journalctlUser = a ["journalctl" "--user"];
  systemctlUser = a ["systemctl" "--user"];
  systemctlUserR = a ["systemctl" "--user" "reload"];

  #> util-linux
  loggerT = ad ["logger" "-t"] "with tag (caller supplies the tag)";
}
