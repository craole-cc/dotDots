{_, ...}: let
  __exports = {
    internal = all;
    external.applicationRegistry = all;
  };

  inherit (_.attrsets.transformation) mapAttrs;
  inherit (_.lists) filter head init last length;
  inherit (_.strings.construction) concatStringsSep indentedForError;
  inherit (_.applications.enums.constants) categories channels families;
  data = _.filesystem.importers.importAllMerged ./.data/common {};

  listCategories = indentedForError {
    title = "Valid Categories";
    items = categories.allValues;
  };
  listChannels = indentedForError {
    title = "Valid Channels";
    items = channels.allValues;
  };
  listFamilies = indentedForError {
    title = "Valid Families";
    items = families.allValues;
  };

  normalizeOptional = val:
    if val == null || val == "" || val == "none"
    then null
    else val;

  all = mapAttrs (name: app: let
    channel = normalizeOptional (app.channel or null);
    family = normalizeOptional (app.family  or null);
    app' = app // {inherit channel family;};

    invalidCats = filter (c: !categories.validator.check c) app'.categories;
    catCount = length invalidCats;
    quotedCats = map (c: "'${c}'") invalidCats;
    humanJoin = items:
      if catCount == 1
      then head items
      else "${concatStringsSep ", " (init items)} and ${last items}";
  in
    if invalidCats != []
    then
      throw "${humanJoin quotedCats} ${
        if catCount == 1
        then "is an invalid category"
        else "are invalid categories"
      }. ${listCategories}"
    else if !channels.validator.check app'.channel
    then throw "'${name}' has invalid channel '${toString app'.channel}'. ${listChannels}"
    else if !families.validator.check app'.family
    then throw "'${name}' has invalid family '${toString app'.family}'. ${listFamilies}"
    else app')
  data;
in
  __exports.internal // {_rootAliases = __exports.external;}
