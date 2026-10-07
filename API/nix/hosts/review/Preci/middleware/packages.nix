{
  lix,
  host,
  ...
}: let
  inherit (lix.attrsets) optionalAttrs;
  inherit (lix.types.host.kernel) resolve isBetterThan;
  inherit (lix.packages) mkNixPkgs mkSets;
  inherit (host) system;

  # The one nixpkgs instance for this host, built from the host's own
  # `system`. Every pool below is resolved against it, and every consumer
  # reaches it either through `packages.nixpkgs` or the sibling `pkgs` binding.
  #
  # All overlays are applied unconditionally. Nix is lazy: an overlay whose
  # attributes are never looked up never evaluates, so listing every overlay
  # costs nothing and removes the "which overlays does this host want" question
  # from the middleware. The gating is on *selection* (see forKernel), not on
  # the overlay list.
  pkgs = mkNixPkgs {inherit system;};

  # The pool table: every registry source resolved against `pkgs`, plus
  # `pkgs` itself under the key `nixpkgs`.
  #
  #   {
  #     zen-browser    = { zen-beta = …; zen-twilight = …; };
  #     cachyos-kernel = { linux-cachyos-zen4 = …; … };
  #     hermes-agent   = { default = …; };
  #     llm-agents     = { claude-code = …; };
  #     nixpkgs        = <pkgs>;
  #   }
  #
  # This is the value `principals.nix` searches and the table `forKernel`
  # indexes. It is NOT a nixpkgs extension: nothing here is layered onto
  # `pkgs`, and no pool attribute appears at `pkgs.zen-browser`.
  packages = mkSets pkgs;

  # Kernel resolution. Gated on the resolved vendor, which `resolve` derives
  # from `host.kernel` (current) or `host.packages.kernel` (legacy). The
  # cachyOS pool is forced only when the host actually wants a cachy kernel,
  # so a nixpkgs-kernel host never builds the 96 cachyOS derivations.
  forKernel = let
    kernel = resolve {inherit host;};
    wantsCachyOS = kernel.vendor == "cachyos";

    kernels = optionalAttrs wantsCachyOS packages.cachyos-kernel;

    package =
      kernels.${kernel.name}
      or (pkgs.${kernel.name}
      or (throw "resolve host '${host.name}': kernel '${kernel.name}' was found neither in the cachyOS pool nor in nixpkgs"));
  in {
    inherit package;
    inherit (kernel) name level vendor warnings;
    alternatives = isBetterThan kernel.level;
  };
in {
  inherit pkgs packages;
  pools = removeAttrs packages ["nixpkgs"];
  # The resolved kernel record, plus the derivation it names.
  #
  # `name`, `level`, `vendor`, and `warnings` come straight from `resolve`;
  # `package` is the derivation looked up in the cachyOS pool or nixpkgs;
  # `alternatives` is the ladder above the resolved level.
  kernel = forKernel;

  # Findings as data, for a module to feed into NixOS `warnings`.
  inherit (forKernel) warnings;
}
