{pkgs, ...}: let
  inherit
    (pkgs)
    fetchFromGitHub
    makeWrapper
    openssl
    pkg-config
    stdenv
    ;
  inherit (pkgs) lib;
  version = "0.1.0";
in
  stdenv.mkDerivation {
    pname = "openclaw";
    inherit version;

    src = fetchFromGitHub {
      owner = "your-org";
      repo = "openclaw";
      rev = "v${version}";
      # Replace with the real sha256 after running `nix-prefetch-github`.
      # STUB — update before production use.
      sha256 = "sha256-STUB0000openclaw000000000000000000000000000=";
    };

    nativeBuildInputs = [
      pkg-config
      makeWrapper
    ];

    buildInputs = [openssl];

    #? Standard GNU make build; adjust if upstream uses cmake/meson/cargo/etc.
    buildPhase = ''
      runHook preBuild
      make -j"$NIX_BUILD_CORES"
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      install -Dm755 openclaw "$out/bin/openclaw"
      runHook postInstall
    '';

    meta = {
      description = "OpenClaw — a hardened NixOS service";
      homepage = "https://github.com/your-org/openclaw";
      license = lib.licenses.mit;
      maintainers = [];
      platforms = lib.platforms.linux;
      mainProgram = "openclaw";
    };
  }
