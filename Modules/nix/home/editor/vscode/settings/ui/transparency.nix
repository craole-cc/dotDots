# Surface transparency is owned by the launcher (see build/style.nix), not by
# an extension: custom-ui-style only re-patches on settings-driven reloads, so
# its stylesheet went stale after every declarative rebuild.
_: {
  name = "transparency";
  description = "Wallpaper-backed editor surfaces injected by the launcher";
  # The feature must still declare a config key: the settings loader only
  # recognises entries that carry settings/extensions/keybindings, and the
  # launcher reads this toggle to decide whether to inject the stylesheet.
  settings = {};
}
