{
  paths,
  config,
  ...
}:
let
  dots = paths.flake.${config.networking.hostName};
  scripts = with paths.parts.bin; {
    dev = dots + shellscript + "/project/nix/devnix";
    eda = dots + shellscript + "/packages/alias/edita";
    gyt = dots + shellscript + "/project/git/gyt";
  };
in
{
  environment = {
    variables = {
      VISUAL = "eda";
      EDITOR = "eda --helix";
      DOTS = dots;
      DOTS_RC = "$DOTS/.dotsrc";
    };
    shellAliases = {
      ".." = "cd .. || exit 1";
      "..." = "cd ../.. || exit 1";
      "...." = "cd ../../.. || exit 1";
      "....." = "cd ../../../.. || exit 1";
      ".dots" = ''cd ${dots} || exit 1'';
      devdots = ''${scripts.dev} ${dots}'';
      vsdots = ''${scripts.eda} --dots'';
      hxdots = ''${scripts.eda} --dots --helix'';
      eda = ''${scripts.eda}'';
      dev = ''${scripts.dev}'';

      # ".dots-root" = ''cd ${flake.root}'';
      # ".dots-link" = ''cd ${flake.link}'';
      # Flake = ''if command -v geet ; then geet ; else git add --all; git commit --message "Flake Update" ; fi ; sudo nixos-rebuild switch --flake . --show-trace'';
      Flash = ''sudo nixos-rebuild switch --flake ${dots}--show-trace'';
      Flux = ''${scripts.gyt} --dir ${dots}'';

      # Flick = ''Flush && Flash && Reboot'';
      # Flick-local = ''Flush && Flash-local && Reboot'';
      # Flick-root = ''Flush && Flash-root && Reboot'';
      # Flick-link = ''Flush && Flash-link && Reboot'';
      flush = ''sudo nix-collect-garbage --delete-old; sudo nix-store --gc'';
      # Reboot = ''leave --reboot'';
      # Reload = ''leave --logout'';
      # Retire = ''leave --shutdown'';
      Q = ''kill -KILL "$(ps -o ppid= -p $$)"'';
      # q = ''leave --terminal'';
      h = "history";
    };
    shellInit = ''[ -f "$DOTS_RC" ] && . "$DOTS_RC"'';
  };
}
