# Libraries/nix/lists/enums/data/capabilities.nix
#
# The canonical user capability vocabulary: a flat list of names, plus the
# default detail attrset each capability resolves against.
#
# Same rationale as `functionalities.nix` next to it: a pure data leaf, so the
# `Preci` host schema can validate against the same vocabulary without
# bootstrapping the `_` module system.
#
# A capability is a name on its own. Whether a name carries detail (which
# languages, which tools, which platforms) is expressed by the default below,
# not by the name. `Preci`'s schema keeps the detail: its
# `libraries/schemas/user/capabilities.nix` merges a declared nested attrset
# over these defaults, so `development.languages.rust.channel` survives
# resolution. Splitting the name from the detail is what lets the flat enum
# and the nested schema share one vocabulary.
{
  #~@ The canonical names. `Libraries/nix/lists/enums/user.nix` wraps this
  #~@ in `mkEnum`; the `Preci` schema validates against it directly.
  names = [
    "writing"
    "conferencing"
    "development"
    "creation"
    "analysis"
    "management"
    "gaming"
    "multimedia"
    "administration"
    "automation"
  ];

  #~@ The default detail for each capability. Every key in `names` must appear
  #~@ here; `requireThat` in the Preci schema enforces that.
  detail = {
    writing = {};
    conferencing = {};
    analysis = {};
    creation = {};
    management = {};
    gaming = {};
    multimedia = {};
    administration = {};
    automation = {};
    development = {
      languages = {};
      tools = {};
      platforms = {};
      environment = {};
    };
  };
}
