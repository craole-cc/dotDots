{
  config,
  cfg,
  json,
  lix,
  profile,
  ...
}: let
  inherit (lix.attrsets.access) attrNames;
  inherit (lix.attrsets.construction) listToAttrs;
  inherit (lix.filesystem.access) readDir;
  inherit (lix.filesystem.primitives) concat;
  inherit (lix.lists.aggregation) concatMap;

  mkExtension = extension:
    if extension ? vscodeExtUniqueId
    then [extension.vscodeExtUniqueId]
    else
      attrNames (readDir (concat {
        root = extension;
        stem = ["share" "vscode" "extensions"];
      }));

  mkHome = stem:
    concat {
      inherit stem;
      root = config.home.homeDirectory;
    };

  mkVariant = {
    directories,
    name,
  }: let
    generate = target: tag: json.generate "${name}-${target}.json" profile.${tag};
    files = {
      extension = listToAttrs (
        concatMap (extension:
          map (name: {
            name = "${directories.extension}/${name}";
            value.source = concat {
              root = extension;
              stem = ["share" "vscode" "extensions" name];
            };
          }) (mkExtension extension))
        profile.extensions
      );
      settings = generate "settings" "userSettings";
      keybindings = generate "keybindings" "keybindings";
    };
  in {inherit directories files;};
in
  if cfg.insiders
  then
    mkVariant {
      name = "vscode-insiders";
      directories = {
        extension = mkHome [".vscode-insiders" "extensions"];
        configuration = mkHome [".config" "Code - Insiders" "User"];
      };
    }
  else
    mkVariant {
      name = "vscode";
      directories = {
        extension = mkHome [".vscode" "extensions"];
        configuration = mkHome [".config" "Code" "User"];
      };
    }
