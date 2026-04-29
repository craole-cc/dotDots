{lib}: let
  inherit (lib.strings) concatStringsSep;

  mkStyledOutput = {pkgs}: let
    gum = "${pkgs.gum}/bin/gum";
  in {
    inherit gum;
    green = ''${gum} style --foreground=82'';
    grey = ''${gum} style --foreground=250'';
    magenta = ''${gum} style --foreground=212'';
    red = ''${gum} style --foreground=196'';
    yellow = ''${gum} style --foreground=226'';
    confirmation = ''${gum} confirm'';
    error = "${gum} style --foreground 196 --bold --border normal --border-foreground 196 --padding '0 1'";
    success = "${gum} style --foreground 46 --bold";
    warning = "${gum} style --foreground 226 --bold";
    info = "${gum} style --foreground 250";
    code = "${gum} style --foreground 87";
  };

  mkSection = {
    print,
    title,
    content,
  }: ''
    ${print.magenta} " $ ${title}"
    ${print.grey} "${concatStringsSep "\n" (map (line: "  ${line}") content)}"
    echo ""
  '';

  mkHeader = {
    print,
    title,
    content,
  }: ''
    ${print.magenta} \
      --border-foreground 212 --border double \
      --align center --width 60 --margin "1 2" --padding "1 2" \
      "${title}" "${content}"
  '';
in {inherit mkStyledOutput mkSection mkHeader;}
