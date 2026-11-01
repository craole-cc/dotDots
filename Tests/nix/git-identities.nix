{lix ? (import ../.. {}).libraries.default}: let
  inherit (lix) lib;
  inherit (lix.lists.access) head;

  resolve = git: let
    user = lix.schema.home.mkUser {
      name = "fixture";
      user = {inherit git;};
    };
    evaluated = lib.evalModules {
      modules = [
        {
          options = import ../../Modules/nix/home/version-control/core/git/options.nix {
            inherit lix user;
            context = null;
            defined = user.git;
          };
        }
      ];
    };
  in {
    normalized = user.git;
    identities = evaluated.config.identities;
  };

  legacy = resolve [
    {
      root = "projects";
      licence = {
        name = "Fixture Author";
        type = "mit";
      };
    }
  ];
  canonical = resolve [
    {
      root = "projects";
      license = {
        author = "Canonical Author";
        default = "apache-2.0";
      };
    }
  ];
  withoutLicense = resolve [{root = "projects";}];
  legacySettings = resolve {
    name = "Legacy Author";
    email = "fixture@example.test";
  };
in
  assert !(head legacy.normalized.identities ? licence);
  assert (head legacy.identities).license
  == {
    author = "Fixture Author";
    default = "mit";
  };
  assert (head canonical.identities).license
  == {
    author = "Canonical Author";
    default = "apache-2.0";
  };
  assert (head withoutLicense.identities).license
  == {
    author = null;
    default = null;
  };
  assert legacySettings.identities == [];
  assert legacySettings.normalized.name == "Legacy Author"; {passed = true;}
