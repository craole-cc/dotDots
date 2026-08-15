args: let
  inherit (args) pkgs lix;
  inherit (pkgs) foot kitty writeShellApplication;
  inherit (lix.attrsets.predicates) isAttrs;
  inherit (lix.strings.construction) concatMapStringsSep;

  mkBin = name: runtimeInputs: text:
    writeShellApplication {
      inherit name runtimeInputs text;
    };

  log = "gum log --level";
  confirm = "gum confirm";
in {
  inherit pkgs log confirm mkBin;

  renderHelp = arg: let
    content =
      if isAttrs arg
      then arg.content or []
      else arg;
    faint =
      if isAttrs arg
      then arg.faint or false
      else false;
  in
    concatMapStringsSep "\n"
    (line:
      if faint
      then ''gum style --faint "  ${line}"''
      else ''gum style "  ${line}"'')
    content;

  set-terminal = ''
    case "''${XDG_SESSION_TYPE:-}" in
      wayland) terminal="${foot}/bin/foot" ;;
      *)
        case "''${DISPLAY:-}" in
          "")
            ${log} error "No display server detected."
            exit 1
          ;;
          *) terminal="${kitty}/bin/kitty" ;;
        esac
      ;;
    esac
  '';
}
