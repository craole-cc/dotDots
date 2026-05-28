{
  helpers,
  description,
  names,
  commands,
  all,
  ...
}: let
  inherit (helpers) mkBin pkgs;
  mkSection = cmd: ''printf "%s\n\n" "$(${cmd})"'';
  hr = ''gum style --faint "──────────────────────────────────────────────────────"'';
in {
  show-help = mkBin "show-help" (
    [pkgs.gum all.help]
    ++ map (name: commands.${name}.help) names
  ) ''
    gum style --border rounded --padding "0 1" --align left "$(
      gum style --bold --italic "${description}"
      ${hr}

      ${mkSection "help-services"}

      ${builtins.concatStringsSep "\n" (
        map (name: mkSection "${name}-help") names
      )}
    )"
  '';
}
