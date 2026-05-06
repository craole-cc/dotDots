{lib}: let
  inherit (lib.shells.rust) mkShell;

  mkSuite = {pkgs ? null}: let
    mk = args: mkShell ({inherit pkgs;} // args);
  in {
    rust = mk {};

    #~@ Full suite — with editor
    rust-nightly = mk {channel = "nightly";};
    rust-stable = mk {channel = "stable";};
    rust-beta = mk {channel = "beta";};

    #~@ Lean — full tooling, no editor
    rust-nightly-lean = mk {
      channel = "nightly";
      includeEditor = false;
    };
    rust-stable-lean = mk {
      channel = "stable";
      includeEditor = false;
    };

    #~@ Minimal — toolchain + gcc only, no dev tools, no editor
    rust-nightly-minimal = mk {
      channel = "nightly";
      minimal = true;
    };
    rust-stable-minimal = mk {
      channel = "stable";
      minimal = true;
    };
  };
in {
  inherit mkSuite;
  mkRustSuite = mkSuite;
  mkShells = mkSuite;
}
