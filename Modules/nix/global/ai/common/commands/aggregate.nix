{
  helpers,
  names,
  commands,
  lib,
  ...
}: let
  inherit (helpers) mkBin pkgs;
  inherit (lib.strings) concatStringsSep;

  mkAll = {
    name,
    action,
    passthru ? true,
  }: let
    args =
      if passthru
      then ''"$@"''
      else "";
    bins = map (service: commands.${service}.${action}) names;
  in
    mkBin name bins ''
      failed=0
      for service in ${concatStringsSep " " names}; do
        "$service-${action}" ${args} || failed=1
      done
      exit "$failed"
    '';
  all = {
    start = mkAll {
      name = "start";
      action = "start";
    };
    stop = mkAll {
      name = "stop";
      action = "stop";
    };
    status = mkAll {
      name = "status";
      action = "status";
      passthru = false;
    };

    help = mkBin "help-services" [pkgs.gum] ''
      gum style "All Services" \
        "  status                  Check all service statuses" \
        "  start                   Start missing services" \
        "  stop                    Stop running services"
    '';
  };
in {inherit all mkAll;}
