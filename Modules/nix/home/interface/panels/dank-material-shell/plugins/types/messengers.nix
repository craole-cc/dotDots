{
  inputs,
  lix,
  pkgs,
  ...
}: let
  inherit (lix.modules.construction) mkForce;

  registry = inputs.dms-plugin-registry.packages.${pkgs.stdenv.hostPlatform.system};
  mkChatPlugin = {
    name,
    binary,
    vendorHash,
  }:
    pkgs.buildGoModule {
      pname = "dms-plugin-${name}";
      version = registry.${name}.version;
      src = registry.${name}.src;
      modRoot = "${name}/src";
      inherit vendorHash;
      env.CGO_ENABLED = "0";
      doCheck = false;
      buildPhase = ''
        runHook preBuild
        go build -trimpath -ldflags='-s -w' -o plugin-binary .
        runHook postBuild
      '';
      installPhase = ''
        runHook preInstall
        mkdir -p "$out"
        cp -R "$src/${name}/." "$out/"
        install -Dm755 plugin-binary "$out/bin/${binary}"
        runHook postInstall
      '';
    };
in {
  plugins = {
    chatManager = {
      enable = true;
      src = mkForce (mkChatPlugin {
        name = "chatManager";
        binary = "chat-managerd";
        vendorHash = "sha256-BJ+d4p5HCuR2816YKvRwbHZEWEe0B3rOH7TXWvQzauo=";
      });
    };
    whatsappChat = {
      enable = true;
      src = mkForce (mkChatPlugin {
        name = "whatsappChat";
        binary = "whatsapp-chat-bridge";
        vendorHash = "sha256-RhARfSVPm/HV2T0MIkQSRrigJhWqCqhEzyyW0mPNuwI=";
      });
    };
    dankKDEConnect.enable = true;
  };

  packages = with pkgs; [go kdePackages.kdeconnect-kde];
}
