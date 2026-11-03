{
  paths,
  lix,
  ...
}: let
  inherit (lix.options.construction) mkOption mkStrOption mkTrue;
  inherit (lix.types.combinators) listOf submodule;
  inherit (lix.attrsets.aggregation) recursiveUpdate;
  inherit (lix.lists.aggregation) concatMap;
  inherit (lix.types.predicates) isString;

  sourceType = submodule {
    options = {
      enable = mkTrue "Whether this source is active.";

      type = mkStrOption {
        example = "wallhaven";
        description = ''
          Variety source type: favorites, fetched, folder, bing, apod,
          earthview, unsplash, unsplash-search, wallhaven, artstation,
          flickr, ...
        '';
      };
      location = mkStrOption {
        example = "waterfalls";
        description = ''
          Depends on the type: a path, a URL, a search query, or just a
          label for sources that take no configuration.
        '';
      };
    };
  };

  #? Core defaults for every single wallpaper configuration source
  defaultProperties = {enable = true;};

  #? Direct operational wrapper function without nested binding overhead
  source = type: locationOrConfig:
    recursiveUpdate defaultProperties (
      {inherit type;}
      // (
        if isString locationOrConfig
        then {location = locationOrConfig;}
        else locationOrConfig
      )
    );

  #? Search block managing keyword queries across engines cleanly
  search = let
    keywords = [
      "abstract"
      "animals"
      "architecture"
      "art"
      "astronomy"
      "autumn"
      "beaches"
      "birds"
      "black-and-white"
      "cars"
      "cities"
      "clouds"
      "disaster"
      "flowers"
      "food"
      "forests"
      "landscapes"
      "marvel"
      "minimalism"
      "mountains"
      "movies"
      "nature"
      "nba"
      "ocean"
      "portraits"
      "rivers"
      "space"
      "street"
      "sunsets"
      "textures"
      "waterfalls"
      "wildlife"
      "winter"
    ];

    engines = [
      "unsplash-search"
      "wallhaven"
    ];

    #> Declaratively generate search providers without repeating manual list increments
    generated =
      concatMap
      (engine: map (tag: source engine tag) keywords)
      engines;
  in {inherit keywords engines generated;};

  #? Artisan block managing RSS streams via artist handles (Fixed Slashes)
  artisan = let
    handles = [
      "leimin" # Stylized landscape/lighting studies
      "kos_reed" # Cinematic 3D concepts and compositions
      "snatti" # Cosy interiors and ambient color palettes
      "moxuanzhang" # Epic moody fantasy environments
    ];

    generated = map (handle:
      source "artstation" "https://www.artstation.com/${handle}.rss")
    handles;
  in {inherit handles generated;};

  #? Flickr block managing pools, groups, and explicit users
  flickr = let
    groups = [
      "minimalist_photography"
      "landscape_photography"
    ];

    users = [
      "peter-levi/;user_id:93647178@N00"
    ];

    generated =
      (map (group: source "flickr" "group:https://www.flickr.com/groups/${group}/") groups)
      ++ (map (handle: source "flickr" "user:https://www.flickr.com/photos/${handle};") users);
  in {inherit groups users generated;};
in {
  sources = mkOption {
    type = listOf sourceType;
    description = "Wallpaper sources, written as src1, src2, ... in order.";
    default =
      [
        (source "favorites" "The Favorites folder")
        (source "fetched" "The Fetched folder")
        (source "bing" "Bing Photo of the Day")
        (source "earthview" "Google Earth View Wallpapers")
        (source "unsplash" "High-resolution photos from Unsplash.com")

        (source "apod" {
          location = "NASA's Astronomy Picture of the Day";
          enable = false;
        })
      ]
      ++ map (source "folder") paths.wallpapers.folders
      ++ flickr.generated
      ++ artisan.generated
      ++ search.generated;
  };
}
