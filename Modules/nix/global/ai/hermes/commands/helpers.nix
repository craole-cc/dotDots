{
  dots,
  paths,
  ...
}: let
  inherit (dots) pkgs lib;
  inherit (lib.attrsets) isAttrs;
  inherit (lib.strings) concatMapStringsSep escapeShellArg;
in rec {
  inherit pkgs;

  mkBin = name: runtimeInputs: text:
    pkgs.writeShellApplication {
      inherit name runtimeInputs text;
    };

  log = "gum log --level";
  confirm = "gum confirm";

  prepare-hermes-messaging = ''
    export HERMES_HOME="''${HERMES_HOME:-$HOME/.hermes}"
    export PYTHONPATH="${paths.telegram}''${PYTHONPATH:+:$PYTHONPATH}"
  '';

  prepare-whatsapp-bridge = ''
    export HERMES_WHATSAPP_BRIDGE_SRC=${escapeShellArg "${paths.hermes}/scripts/whatsapp-bridge"}
    export HERMES_WHATSAPP_BRIDGE_DIR="''${XDG_STATE_HOME:-$HOME/.local/state}/hermes/whatsapp-bridge"
    export HERMES_WHATSAPP_GATEWAY_PY=${escapeShellArg "${../middleware/whatsapp/gateway.py}"}
    ${builtins.readFile ../middleware/whatsapp/bridge.sh}
  '';

  env-file-functions = ''
    export HERMES_ENV_PY=${escapeShellArg "${../environment/env.py}"}
    ${builtins.readFile ../environment/env.sh}
  '';

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
      wayland) terminal="${pkgs.foot}/bin/foot" ;;
      *)
        case "''${DISPLAY:-}" in
          "")
            ${log} error "No display server detected."
            exit 1
          ;;
          *) terminal="${pkgs.xterm}/bin/xterm" ;;
        esac
      ;;
    esac
  '';
}
