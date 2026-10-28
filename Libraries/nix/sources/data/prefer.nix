# Tie-breaks when more than one package provides the same binary.
{
  kill = "procps"; # util-linux also ships a `kill`; procps is the one with -USR1 etc. semantics we rely on
  uptime = "procps"; # coreutils ships `uptime` on some channels; keep procps for consistency
}
