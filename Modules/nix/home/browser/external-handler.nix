{
  lib,
  lix,
  pkgs,
  user,
  ...
}: let
  inherit (lix.attrsets.construction) listToAttrs;
  inherit (lix.applications.registry) resolve;
  inherit (lix.lists.access) head;
  inherit (lix.strings.transformation) escapeShellArg;

  selections = user.packages.browser or ((lix.schema.packages.resolve {record = user;}).browser or []);
  selectedBrowser =
    if selections == []
    then null
    else resolve {
      value = head selections;
      category = "browser";
    };
  command =
    if selectedBrowser == null
    then null
    else selectedBrowser.exec or (selectedBrowser.names.command or null);
  windowClass =
    if selectedBrowser == null
    then ""
    else selectedBrowser.names.class or "";

  browserHandler = pkgs.writeShellApplication {
    name = "dotdots-open-browser";
    runtimeInputs = [pkgs.jq];
    text = ''
      browser=${escapeShellArg command}
      browser_class=${escapeShellArg windowClass}

      if (( $# == 0 )); then
        set -- about:blank
      fi

      if [[ "''${XDG_CURRENT_DESKTOP:-}" != *Hyprland* ]] || ! command -v hyprctl >/dev/null 2>&1; then
        exec "$browser" "$@"
      fi

      browser_client() {
        hyprctl -j clients 2>/dev/null | jq -er --arg class "$browser_class" '
          [ .[] | select(.class == $class and .mapped == true) ]
          | sort_by(.focusHistoryID // 2147483647)
          | .[0] // empty
          | [.address, .workspace.name] | @tsv
        ' 2>/dev/null
      }

      reveal_client() {
        local client_record=$1 address workspace active_workspace scratchpad_name
        IFS=$'\t' read -r address workspace <<<"$client_record"

        if [[ "$workspace" == special:* ]]; then
          scratchpad_name=''${workspace#special:}
          active_workspace=$(hyprctl -j activeworkspace 2>/dev/null | jq -r '.name // empty') || active_workspace=
          if [[ "$active_workspace" != "$workspace" ]]; then
            hyprctl dispatch togglespecialworkspace "$scratchpad_name" >/dev/null
          fi
        fi

        hyprctl dispatch focuswindow "address:$address" >/dev/null
      }

      existing_client=$(browser_client || true)
      if [[ -n "$existing_client" ]]; then
        reveal_client "$existing_client" || true
        "$browser" "$@"
        existing_client=$(browser_client || true)
        [[ -n "$existing_client" ]] && reveal_client "$existing_client" || true
        exit 0
      fi

      quote_argument() {
        local quoted_argument
        printf -v quoted_argument '%q' "$1"
        printf '%s' "$quoted_argument"
      }

      launch_command=$(quote_argument "$browser")
      for argument in "$@"; do
        launch_command+=" $(quote_argument "$argument")"
      done
      if ! hyprctl dispatch exec "[workspace special:browser-primary silent] $launch_command" >/dev/null; then
        exec "$browser" "$@"
      fi

      for _ in {1..50}; do
        sleep 0.1
        existing_client=$(browser_client || true)
        [[ -n "$existing_client" ]] && break
      done
      if [[ -n "$existing_client" ]]; then
        reveal_client "$existing_client" || true
      fi
    '';
  };

  mimeTypes = [
    "application/xhtml+xml"
    "application/x-extension-htm"
    "application/x-extension-html"
    "application/x-extension-shtml"
    "application/x-extension-xht"
    "application/x-extension-xhtml"
    "application/json"
    "text/html"
    "text/plain"
    "x-scheme-handler/about"
    "x-scheme-handler/chrome"
    "x-scheme-handler/http"
    "x-scheme-handler/https"
    "x-scheme-handler/mailto"
    "x-scheme-handler/unknown"
  ];
  mimeAssociations = listToAttrs (map (mimeType: {
      name = mimeType;
      value = "dotdots-browser.desktop";
    })
    mimeTypes);
in
  if selectedBrowser == null || command == null
  then {}
  else {
    home.packages = [browserHandler];

    home.sessionVariables = {
      BROWSER = lib.mkForce "${browserHandler}/bin/dotdots-open-browser";
      BROWSER_PRI = lib.mkForce "${browserHandler}/bin/dotdots-open-browser";
    };

    xdg.desktopEntries.dotdots-browser = {
      name = "dotDots Browser";
      exec = "${browserHandler}/bin/dotdots-open-browser %u";
      terminal = false;
      type = "Application";
      mimeType = mimeTypes;
    };

    xdg.mimeApps.defaultApplications = mimeAssociations;
  }
