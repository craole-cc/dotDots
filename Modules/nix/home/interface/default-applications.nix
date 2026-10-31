{
  apps,
  config,
  lix,
  pkgs,
  ...
}: let
  inherit (lix.attrsets.construction) listToAttrs;
  inherit (lix.lists.access) head;
  inherit (lix.modules.construction) mkIf mkMerge;
  inherit (lix.strings.transformation) escapeShellArg;

  terminal = head apps.terminal;
  terminalCommand = "${escapeShellArg terminal.command} ${escapeShellArg terminal.wrap.execFlag}";
  directoryHandler = pkgs.writeShellApplication {
    name = "dotdots-open-directory";
    text = ''
      exec ${terminalCommand} ${config.programs.yazi.package}/bin/yazi "$@"
    '';
  };

  archiveMimeTypes = [
    "application/zip"
    "application/x-7z-compressed"
    "application/vnd.rar"
    "application/x-rar"
    "application/x-rar-compressed"
    "application/x-tar"
    "application/gzip"
    "application/x-gzip"
    "application/x-bzip2"
    "application/x-xz"
    "application/zstd"
    "application/x-compressed-tar"
    "application/x-bzip-compressed-tar"
    "application/x-xz-compressed-tar"
    "application/x-zstd-compressed-tar"
  ];
  archiveHandler = pkgs.writeShellApplication {
    name = "dotdots-open-archive";
    runtimeInputs = [pkgs.ouch];
    text = ''
      status=0
      ouch list --tree -- "$@" || status=$?
      printf '\nPress Enter to close.'
      read -r _ || true
      exit "$status"
    '';
  };
  mapUrl = pkgs.writeText "dotdots-map-url.py" ''
    import sys
    from urllib.parse import parse_qs, unquote, urlencode, urlsplit

    if len(sys.argv) == 1:
        print("https://www.google.com/maps/")
    else:
        location = urlsplit(sys.argv[1])
        if location.scheme != "geo":
            sys.exit("Expected a geo: location")
        query = parse_qs(location.query).get("q", [None])[0]
        if not query:
            query = ",".join(unquote(location.path).split(";", 1)[0].split(",")[:2])
        print("https://www.google.com/maps/search/?" + urlencode({"api": "1", "query": query}))
  '';
  mapHandler = pkgs.writeShellApplication {
    name = "dotdots-open-map";
    runtimeInputs = [pkgs.python3 pkgs.xdg-utils];
    text = ''
      url=$(python3 ${mapUrl} "$@")
      exec xdg-open "$url"
    '';
  };
in
  mkMerge [
    (mkIf (apps.terminal != []) {
      home.packages = [archiveHandler];
      xdg.mimeApps.enable = true;
      xdg.desktopEntries.dotdots-archive = {
        name = "Ouch Archive Viewer";
        exec = "${terminal.command} ${terminal.wrap.execFlag} ${archiveHandler}/bin/dotdots-open-archive %F";
        icon = "package-x-generic";
        terminal = false;
        categories = ["Utility" "Archiving"];
        mimeType = archiveMimeTypes;
      };
      xdg.mimeApps.defaultApplications = listToAttrs (map (mimeType: {
          name = mimeType;
          value = "dotdots-archive.desktop";
        })
        archiveMimeTypes);
    })
    (mkIf (apps.terminal != [] && apps.explorer != [] && (head apps.explorer).name == "yazi") {
      home.packages = [directoryHandler];
      xdg.desktopEntries.dotdots-yazi = {
        name = "Yazi";
        exec = "${directoryHandler}/bin/dotdots-open-directory %F";
        icon = "utilities-terminal";
        terminal = false;
        categories = ["System" "FileTools" "FileManager"];
        mimeType = ["inode/directory"];
      };
      xdg.mimeApps.defaultApplications."inode/directory" = "dotdots-yazi.desktop";
    })
    (mkIf (apps.browser != []) {
      home.packages = [mapHandler];
      xdg.mimeApps.enable = true;
      xdg.desktopEntries.dotdots-maps = {
        name = "Google Maps";
        exec = "${mapHandler}/bin/dotdots-open-map %u";
        icon = "maps";
        terminal = false;
        categories = ["Network" "Maps"];
        mimeType = ["x-scheme-handler/geo"];
      };
      xdg.mimeApps.defaultApplications."x-scheme-handler/geo" = "dotdots-maps.desktop";
    })
  ]
