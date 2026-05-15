{_, ...}: let
  meta = let
    doc = ''
      #TODO: Add relevant file documentation
    '';
    functions = {inherit mkNix mkClean;};
    exports = {
      local = functions;
      alias = functions;
    };
  in {inherit doc exports functions;};

  inherit (_.attrsets.access) attrValues;
  inherit (_.attrsets.transformation) filterAttrs;
  inherit (_.attrsets.predicates) hasAttr;
  inherit (_.lists.construction) optionals;
  inherit (_.modules.construction) mkForce;
  inherit (_.sources.predicates) lockFileHas;
  inherit (_.strings.predicates) hasInfix;

  mkNix = {
    host,
    pkgs,
    ...
  }: let
    kernelRequested = host.packages.kernel or null;
    isCachy = kernelRequested != null && (hasInfix "cachyos" kernelRequested);
    isChaotic = kernelRequested != null && hasAttr kernelRequested pkgs;

    requiresNyx = isCachy || isChaotic;
    requiresNumtide = lockFileHas {
      path = host.paths.dots;
      field = "owner";
      value = "numtide";
    };

    userCaches = host.caches or {};

    autoCaches =
      optionals requiresNumtide [
        {
          sub = "https://cache.numtide.com";
          key = "cache.numtide.com-1:dGZlQILjUw6nfhbyU3aRjVm4iklknCKEIh5+OR2TXVY=";
        }
      ]
      ++ optionals (
        requiresNyx
        && !(hasAttr "nyx" userCaches || hasAttr "chaotic" userCaches)
      ) [
        {
          sub = "https://nyx.chaotic.cx/";
          key = "nyx.chaotic.cx-1:CNZOSlPJO5F0utqsPzkZbHkkD7YzNDWHGG6PqS30wMc=";
        }
      ];

    allCaches =
      attrValues (filterAttrs (_: c: c.enable or true) userCaches)
      ++ autoCaches;
  in {
    system.stateVersion = host.stateVersion or "25.11";

    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "pipe-operators"
      ];
      max-jobs = host.specs.cpu.cores or "auto";
      trusted-users = ["@wheel"];
      substituters = map (c: c.sub) allCaches;
      trusted-public-keys = map (c: c.key) allCaches;
    };

    systemd.services.nix-daemon.serviceConfig.LimitNOFILE = mkForce "65536 1048576";
  };

  mkClean = {host, ...}: {
    programs.nh = {
      enable = true;
      clean = {
        enable = true;
        extraArgs = "--keep-since 3d --keep 5";
      };
      flake = host.paths.dots;
    };
  };
in
  meta.exports.local
  // {
    __docs = meta.doc;
    __rootAliases = meta.exports.alias;
  }
