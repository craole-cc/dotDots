{ paths, ... }:
let
  flake = paths.flake.local;
in
{
  Flake = ''pushd ${flake} && { { { command -v geet && geet ;} || git add --all; git commit --message "Flake Update" ;} ; sudo nixos-rebuild switch --flake . --show-trace ;}; popd'';
  Flush = ''sudo nix-collect-garbage --delete-old; sudo nix-store --gc'';
  Flash = ''geet --path ${flake} && sudo nixos-rebuild switch --flake ${flake} --show-trace'';
  Flick = ''Flush && Flash && Reboot'';
  Reboot = ''leave --reboot'';
  Reload = ''leave --logout'';
  Retire = ''leave --shutdown'';
  Q = ''kill -KILL "$(ps -o ppid= -p $$)"'';
  q = ''leave --terminal'';
  ".." = "cd .. || return 1";
  "..." = "cd ../.. || return 1";
  "...." = "cd ../../.. || return 1";
  "....." = "cd ../../../.. || return 1";
  h = "history";
}
