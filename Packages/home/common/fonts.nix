{
  user,
  host,
  ...
}: {
  _module.args.fonts =
    user.interface.style.fonts or host.interface.style.fonts or {
      emoji = "Noto Color Emoji";
      monospace = "Maple Mono NF";
      sans = "Monaspace Radon Frozen";
      serif = "Noto Serif";
      material = "Material Symbols Sharp";
      clock = "Rubik";
    };
}
