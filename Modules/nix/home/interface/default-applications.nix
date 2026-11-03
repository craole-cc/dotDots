{
  apps,
  config,
  lix,
  options,
  ...
}: let
  dom = "interface";
  mod = "default-applications";
  context = mkContext {inherit config dom mod;};
  inherit (binariesFor [config.programs.yazi.package]) yazi;
  inherit (context) cfg;
  inherit (lix.attrsets.construction) listToAttrs optionalAttrs;
  inherit (lix.content.emptiness) isNotEmpty;
  inherit (lix.lists.access) head;
  inherit (lix.lists.selection) filter;
  inherit (lix.modules.construction) mkConfig mkContext mkLayer mkMerge;
  inherit (lix.options.construction) mkEnable mkOption;
  inherit (lix.strings.construction) optionalString splitString;
  inherit (lix.strings.transformation) escapeShellArgs;
  inherit (lix.toolkit) binaries binariesFor write;
  inherit (lix.types.combinators) attrsOf listOf;
  inherit (lix.types.predicates) isString;
  inherit (lix.types.primitives) anything str;

  hasApp = category: isNotEmpty apps.${category};
  appFor = category: optionalAttrs (hasApp category) (head apps.${category});

  explorer = appFor "explorer";
  terminal = appFor "terminal";

  toTerminal = let
    command = terminal.command or null;
    execFlag = terminal.wrap.execFlag or "";
  in
    optionalString (hasApp "terminal") (
      if isString command && isNotEmpty command
      then
        if isString execFlag
        then escapeShellArgs ([command] ++ filter isNotEmpty (splitString " " execFlag))
        else throw "default-applications: the selected terminal's wrap.execFlag must be a string"
      else throw "default-applications: the selected terminal must have a non-empty command"
    );

  directoryHandler = write.bin "dotdots-open-directory" ''
    exec ${toTerminal} ${yazi} "$@"
  '';

  defaults = {
    enable = true;
    archiveMimeTypes = map (subtype: "application/${subtype}") [
      "gzip"
      "vnd.rar"
      "x-7z-compressed"
      "x-bzip-compressed-tar"
      "x-bzip2"
      "x-compressed-tar"
      "x-gzip"
      "x-rar-compressed"
      "x-rar"
      "x-tar"
      "x-xz-compressed-tar"
      "x-xz"
      "x-zstd-compressed-tar"
      "zip"
      "zstd"
    ];
    home.packages = [];
    xdg = {
      desktopEntries = {};
      mimeApps = {
        enable = false;
        defaultApplications = {};
      };
    };
  };

  archiveHandler = write.bin "dotdots-open-archive" ''
    status=0
    ${binaries.lsarTree} -- "$@" || status=$?
    ${binaries.gum} confirm 'Close archive viewer?' || true
    exit "$status"
  '';

  mapHandler = let
    mapUrl = write.rust {
      name = "dotdots-map-url";
      src = write.text "dotdots-map-url.rs" ''
        //! ```cargo
        //! [dependencies]
        //! url = "2"
        //! percent-encoding = "2"
        //! ```

        use std::env::args;
        use std::error::Error;
        use url::Url;
        use percent_encoding::percent_decode_str;

        const GOOGLE_MAPS_BASE: &str = "https://www.google.com/maps/";

        fn coordinates_from_path(path: &str) -> String {
          percent_decode_str(path)
            .decode_utf8_lossy()
            .split(';')
            .next()
            .unwrap_or_default()
            .split(',')
            .take(2)
            .collect::<Vec<_>>()
            .join(",")
        }

        fn main() -> Result<(), Box<dyn Error>> {
          let Some(argument) = args().nth(1) else {
            println!("{GOOGLE_MAPS_BASE}");
            return Ok(());
          };

          let geo_url = Url::parse(&argument)?;
          if geo_url.scheme() != "geo" {
            return Err("expected a geo: URI".into());
          }

          //> Prefer an explicit non-empty `q=` parameter; otherwise use lat,lon from the path.
          let query = geo_url
            .query_pairs()
            .find(|(key, val)| key == "q" && !val.is_empty())
            .map(|(_, val)| val.into_owned())
            .unwrap_or_else(|| coordinates_from_path(geo_url.path()));

          if query.is_empty() {
            println!("{GOOGLE_MAPS_BASE}");
            return Ok(());
          }

          let mut destination = Url::parse(GOOGLE_MAPS_BASE)?.join("search/")?;
          destination
            .query_pairs_mut()
            .append_pair("api", "1")
            .append_pair("query", &query);

          println!("{destination}");
          Ok(())
        }
      '';
    };
  in
    write.bin "dotdots-open-map" ''
      url=$(${mapUrl}/bin/dotdots-map-url "$@") || exit $?
      exec ${binaries.xdg-open} "$url"
    '';
in
  mkConfig {
    inherit context defaults;
    options = {
      enable = mkEnable {
        inherit context;
        condition = defaults.enable;
      };
      archiveMimeTypes = mkOption {
        description = "Archive MIME types handled by the terminal archive viewer";
        default = defaults.archiveMimeTypes;
        type = listOf str;
      };
      home.packages = mkOption {
        description = "Packages installed for default application handlers";
        default = defaults.home.packages;
        inherit (options.home.packages) type;
      };
      xdg = {
        desktopEntries = mkOption {
          description = "Desktop entries for default application handlers";
          default = defaults.xdg.desktopEntries;
          type = attrsOf (attrsOf anything);
        };
        mimeApps = {
          enable = mkEnable {
            description = "MIME associations for default application handlers";
            condition = defaults.xdg.mimeApps.enable;
          };
          defaultApplications = mkOption {
            description = "Default desktop entries for each handled MIME type";
            default = defaults.xdg.mimeApps.defaultApplications;
            inherit (options.xdg.mimeApps.defaultApplications) type;
          };
        };
      };
    };
    resolutions = mkMerge (map (mkLayer 1000) [
      (
        optionalAttrs (hasApp "terminal") {
          home.packages = [archiveHandler];
          xdg = {
            desktopEntries.dotdots-archive = {
              name = "Ouch Archive Viewer";
              exec = "${toTerminal} ${archiveHandler}/bin/dotdots-open-archive %F";
              icon = "package-x-generic";
              terminal = false;
              categories = ["Utility" "Archiving"];
              mimeType = cfg.archiveMimeTypes;
            };
            mimeApps = {
              enable = true;
              defaultApplications = listToAttrs (
                map (mimeType: {
                  name = mimeType;
                  value = "dotdots-archive.desktop";
                })
                cfg.archiveMimeTypes
              );
            };
          };
        }
      )
      (
        optionalAttrs (hasApp "terminal" && hasApp "explorer" && ((explorer.name or null) == "yazi")) {
          home.packages = [directoryHandler];
          xdg = {
            desktopEntries.dotdots-yazi = {
              name = "Yazi";
              exec = "${directoryHandler}/bin/dotdots-open-directory %F";
              icon = "utilities-terminal";
              terminal = false;
              categories = ["System" "FileTools" "FileManager"];
              mimeType = ["inode/directory"];
            };
            mimeApps.defaultApplications."inode/directory" = "dotdots-yazi.desktop";
          };
        }
      )
      (
        optionalAttrs (hasApp "browser") {
          home.packages = [mapHandler];
          xdg = {
            desktopEntries.dotdots-maps = {
              name = "Google Maps";
              exec = "${mapHandler}/bin/dotdots-open-map %u";
              icon = "maps";
              terminal = false;
              categories = ["Network" "Maps"];
              mimeType = ["x-scheme-handler/geo"];
            };
            mimeApps = {
              enable = true;
              defaultApplications."x-scheme-handler/geo" = "dotdots-maps.desktop";
            };
          };
        }
      )
    ]);
    outputs = {inherit (cfg) home xdg;};
  }
