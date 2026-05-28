{
  dots,
  helpers,
  runtimes,
  ...
}: let
  inherit (dots) pkgs lib;
  inherit (lib.strings) escapeShellArg;
  inherit (helpers) confirm log mkBin renderHelp set-terminal;
in rec {
  mkProcess = pattern: let
    cmd = action: ''${action} -f -- ${escapeShellArg pattern} >/dev/null 2>&1'';
  in {
    check = cmd "pgrep";
    kill = cmd "pkill";
  };

  mkWait = check: label: ''
    timeout="''${STARTUP_TIMEOUT:-15}"
    elapsed=0

    _wait_check() {
      ${check}
    }

    while [ "$elapsed" -lt "$timeout" ]; do
      if _wait_check; then
        ${log} info "${label}"
        break
      fi
      sleep 1
      elapsed=$((elapsed + 1))
    done

    if [ "$elapsed" -ge "$timeout" ]; then
      ${log} warn "Timed out waiting for ${label}"
      exit 1
    fi
  '';

  mkCheck = {
    check,
    msg,
    level ? "error",
    action ? "exit 1",
    invert ? false,
  }: let
    condition =
      if invert
      then "_mkcheck"
      else "! _mkcheck";
  in ''
    _mkcheck() {
      ${check}
    }
    if ${condition}; then
      ${log} ${level} "${msg}"
      ${action}
    fi
  '';

  mkRequire = args:
    mkCheck ({
        level = "error";
        action = "exit 1";
        invert = false;
      }
      // args);

  parseStartArgs = ''
    while [ "$#" -gt 0 ]; do
      case "$1" in
        -y|--yes|--no-confirm) assume_yes=1 ;;
        --no-wait)             wait=0 ;;
        -h|--help)
          gum style \
            "  -y, --yes, --no-confirm   start without prompting" \
            "  --no-wait                 do not wait for readiness"
          exit 0 ;;
        *)
          ${log} error "Unknown option: $1"
          exit 2 ;;
      esac
      shift
    done
  '';

  parseStopArgs = ''
    while [ "$#" -gt 0 ]; do
      case "$1" in
        -f|--force|-y|--yes|--no-confirm) force=1 ;;
        -h|--help)
          gum style \
            "  -f, --force               stop without prompting" \
            "  -y, --yes, --no-confirm   stop without prompting"
          exit 0 ;;
        *)
          ${log} error "Unknown option: $1"
          exit 2 ;;
      esac
      shift
    done
  '';

  mkLaunch = name: runtime: command: let
    session = pkgs.writeShellApplication {
      name = "${name}-session";
      runtimeInputs = runtime;
      text = command;
    };
  in ''
    "$terminal" -e ${session}/bin/${name}-session \
      </dev/null >/dev/null 2>&1 &
  '';

  mkService = name: cfg: let
    process = mkProcess cfg.process;
    check = cfg.check or process.check;
    kill = cfg.kill or process.kill;
    command = cfg.command or cfg.process;
    runtime = runtimes.default ++ (cfg.runtime or []);
    wait-label = cfg.wait.label or "${cfg.title} is running.";
  in {
    inherit check;

    start = mkBin "${name}-start" runtime ''
      assume_yes=0
      wait=1

      ${parseStartArgs}

      ${mkCheck {
        inherit check;
        msg = "${cfg.title} already running - skipping.";
        level = "warn";
        action = "exit 0";
        invert = true;
      }}

      ${set-terminal}
      clear

      if [ "$assume_yes" -ne 1 ]; then
        ${confirm} "Start ${cfg.title}?" || exit 0
      fi

      ${mkLaunch name runtime command}

      ${log} info "${cfg.title} launched via $(basename "$terminal")."

      if [ "$wait" -eq 1 ]; then
        ${mkWait check wait-label}
      fi

      show-help
    '';

    stop = mkBin "${name}-stop" runtime ''
      force=0
      clear

      ${parseStopArgs}

      ${mkCheck {
        inherit check;
        msg = "${cfg.title} is not running.";
        level = "warn";
        action = "exit 0";
      }}

      if [ "$force" -ne 1 ]; then
        ${confirm} "Stop ${cfg.title}?" </dev/tty || {
          ${log} warn "${cfg.title} left active."
          exit 0
        }
      fi

      if ${kill}; then
        ${log} info "${cfg.title} stopped."
      else
        ${log} error "Failed to stop ${cfg.title}."
        exit 1
      fi

      show-help
    '';

    status = mkBin "${name}-status" runtime ''
      ${mkCheck {
        inherit check;
        msg = "${cfg.title} is not running.";
        level = "warn";
        action = "exit 1";
      }}

      ${log} info "${cfg.title} is running."
    '';

    help = mkBin "${name}-help" runtimes.common ''
      _help_check() {
        ${check}
      }

      gum style "${cfg.title}"

      if _help_check; then
        ${renderHelp cfg.help.running}
        ${renderHelp cfg.help.common}
        ${renderHelp {
          content = cfg.help.stopped;
          faint = true;
        }}
      else
        ${renderHelp cfg.help.stopped}
        ${renderHelp cfg.help.common}
        ${renderHelp {
          content = cfg.help.running;
          faint = true;
        }}
      fi
    '';
  };
}
