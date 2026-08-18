{
  lix,
  config,
  lib,
  pkgs,
  top,
  user,
  ...
}: let
  inherit (lix.modules.core.staging) mkStaged;
  cfg = config.${top}.resolved.interface.theme.dispatcher;
  inherit (cfg) statePath;
  inherit (cfg) socketPath;
  darkTheme = user.style.theme.dark or "Catppuccin Frappé";
  lightTheme = user.style.theme.light or "Catppuccin Latte";
  dispatcher = pkgs.writeText "dotdots-theme-dispatcher.py" ''
    import os
    import signal
    import socket
    import subprocess
    from pathlib import Path

    state = Path(os.environ["DOTDOTS_THEME_STATE"])
    sock = Path(os.environ["DOTDOTS_THEME_SOCKET"])
    dark_foot = """background=1e1e2e
    foreground=cdd6f4
    selection-background=585b70
    selection-foreground=cdd6f4
    regular0=45475a
    regular1=f38ba8
    regular2=a6e3a1
    regular3=f9e2af
    regular4=89b4fa
    regular5=f5c2e7
    regular6=94e2d5
    regular7=bac2de
    bright0=585b70
    bright1=f38ba8
    bright2=a6e3a1
    bright3=f9e2af
    bright4=89b4fa
    bright5=f5c2e7
    bright6=94e2d5
    bright7=a6adc8
    """
    light_foot = """background=eff1f5
    foreground=4c4f69
    selection-background=acb0be
    selection-foreground=4c4f69
    regular0=5c5f77
    regular1=d20f39
    regular2=40a02b
    regular3=df8e1d
    regular4=1e66f5
    regular5=ea76cb
    regular6=179299
    regular7=acb0be
    bright0=6c6f85
    bright1=d20f39
    bright2=40a02b
    bright3=df8e1d
    bright4=1e66f5
    bright5=ea76cb
    bright6=179299
    bright7=bcc0cc
    """

    def emit(mode):
        state.parent.mkdir(parents=True, exist_ok=True)
        state.write_text(mode + "\n")
        foot = Path(os.environ["HOME"]) / ".config/foot/theme.ini"
        foot.parent.mkdir(parents=True, exist_ok=True)
        foot.write_text(dark_foot if mode == "dark" else light_foot)
        try:
            subprocess.run(["dbus-send", "--session", "--type=signal", "/org/dotDots/Theme", "org.dotDots.Theme.Polarity", "string:" + mode], check=False)
        except OSError:
            pass
        try:
            subprocess.run(["gsettings", "set", "org.gnome.desktop.interface", "color-scheme", "prefer-dark" if mode == "dark" else "prefer-light"], check=False)
        except OSError:
            pass
        subprocess.run(["pkill", "-USR1", "-x", "foot"], check=False)
        subprocess.run(["pkill", "-USR1", "-x", "footclient"], check=False)

    def current():
        try:
            value = state.read_text().strip()
            return value if value in ("dark", "light") else "light"
        except FileNotFoundError:
            return "light"

    sock.parent.mkdir(parents=True, exist_ok=True)
    try:
        sock.unlink()
    except FileNotFoundError:
        pass
    emit(current())
    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    server.bind(str(sock))
    os.chmod(sock, 0o600)
    server.listen(4)
    while True:
        connection, _ = server.accept()
        with connection:
            command = connection.recv(32).decode().strip()
        mode = current() if command == "current" else ("light" if current() == "dark" else "dark") if command == "toggle" else command
        if mode in ("dark", "light"):
            emit(mode)
  '';
  dispatcherService = pkgs.writeShellScript "dotdots-theme-dispatcher" ''
    export DOTDOTS_THEME_STATE=${lib.escapeShellArg statePath}
    export DOTDOTS_THEME_SOCKET="''${XDG_RUNTIME_DIR}/dotdots-theme.sock"
    exec ${pkgs.python3}/bin/python ${dispatcher}
  '';
  toggle = pkgs.writeShellScriptBin "theme-toggle" ''
    set -eu
    socket="''${XDG_RUNTIME_DIR}/dotdots-theme.sock"
    command="''${1:-toggle}"
    printf '%s' "$command" | ${pkgs.socat}/bin/socat - "UNIX-CONNECT:$socket"
  '';
  payload = {
    home.packages = [toggle];
    systemd.user.services.dotdots-theme-dispatcher = {
      Unit = {
        Description = "dotDots live theme polarity dispatcher";
        After = ["graphical-session.target"];
        PartOf = ["graphical-session.target"];
      };
      Service = {
        ExecStart = dispatcherService;
        Restart = "on-failure";
        Environment = ["DOTDOTS_THEME_SOCKET=%t/dotdots-theme.sock"];
      };
      Install.WantedBy = ["graphical-session.target"];
    };
    warnings = lib.optional cfg.qt.restartRequired "dotDots Qt theme reaction is marked restartRequired because the installed Qt/Kvantum path has no verified universal live reload interface.";
  };
in {
  options.${top}.resolved.interface.theme = {
    enable = lib.mkOption {
      description = "Enable live system-wide theme polarity management";
      default = user.style.autoSwitch or true;
      type = lib.types.bool;
    };
    autoSwitch = lib.mkOption {
      description = "Allow darkman and the dispatcher to follow automatic polarity triggers";
      default = user.style.autoSwitch or true;
      type = lib.types.bool;
    };
    manualOverride = lib.mkOption {
      description = "Permit theme-toggle to override the automatic polarity";
      default = true;
      type = lib.types.bool;
    };
    dispatcher = {
      enable = lib.mkOption {
        description = "Run the user-session theme polarity dispatcher";
        default = user.style.autoSwitch or true;
        type = lib.types.bool;
      };
      statePath = lib.mkOption {
        description = "Runtime file containing the current dark/light polarity";
        default = "${config.home.homeDirectory}/.cache/dotdots/theme/polarity";
        type = lib.types.str;
      };
      socketPath = lib.mkOption {
        description = "Runtime Unix socket used by theme-toggle";
        default = "%t/dotdots-theme.sock";
        type = lib.types.str;
      };
      foot = {
        enable = lib.mkOption {
          default = true;
          type = lib.types.bool;
        };
        restartRequired = lib.mkOption {
          default = false;
          type = lib.types.bool;
        };
      };
      gtk = {
        enable = lib.mkOption {
          default = true;
          type = lib.types.bool;
        };
        restartRequired = lib.mkOption {
          default = false;
          type = lib.types.bool;
        };
      };
      qt = {
        enable = lib.mkOption {
          default = true;
          type = lib.types.bool;
        };
        restartRequired = lib.mkOption {
          default = true;
          type = lib.types.bool;
        };
      };
    };
  };

  config = lib.mkMerge (mkStaged {
    inherit top payload;
    condition = cfg.enable;
  });
}
