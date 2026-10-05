/**
Test collector + shared test harness.

Takes the shared args (`{lix, host, context, api}`) positionally, builds the
harness, discovers every suite under this directory and returns one report.

  nix-repl> :p tests.summary
  nix-repl> :p tests.bySuite
  nix-repl> :p tests.failures
  nix-repl> :p tests.lines
  nix-repl> :p tests.skipped

The tree mirrors the source: the test for `libraries/types/host/kernel.nix` is
`tests/libraries/types/host/kernel.nix`, and a directory's `default.nix` tests
that directory's own `default.nix`.

A suite is a file that is a function `args: harness: [cases]`. Any other `.nix`
file, such as a fixture sitting beside the tests that use it, is not run and
is listed in `tests.skipped` so it is never silently lost. This file,
`harness.nix` (if present) and `fixtures/` are ignored at the top level;
fixtures reach the suites as `harness.fixtures`.

--- Harness ---

A case is `{ group, name, expected, actual, passed }`. A suite is a list of
cases. `report` takes an attrset of suites keyed by suite name.
*/
args: let
  inherit (args) lix;

  inherit (lix.attrsets) attrNames mapAttrs;
  inherit (lix.lists) concatLists elem filter foldl' head length;
  inherit (lix.debug) deepSeq tryEval;
  inherit (lix.filesystem) readDir;
  inherit (lix.strings) concatStringsSep match;
  inherit (lix.trivial) isFunction;

  #~@ Harness

  fixtures = import ./fixtures;

  #> Fully evaluate a value, reporting whether doing so threw.
  #? `tryEval` only catches `throw` and `assert`:
  #? a missing attribute still aborts the run, since malformed data should be loud.
  attempt = value: tryEval (deepSeq value value);

  makeCase = group: name: actual: expected: let
    outcome = attempt actual;
  in {
    inherit group name expected;
    passed = with outcome; success && (value == expected);
    actual =
      if outcome.success
      then outcome.value
      else "<throws>";
  };

  #> Passes when evaluating `value` throws.
  makeThrowCase = group: name: value:
    makeCase group name (!(attempt value).success) true;

  #> Stamp every case in a suite with the suite it came from.
  stamp = suite: suites:
    map (case: case // {inherit suite;}) suites;

  report = suites: let
    cases = concatLists (
      map
      (name: stamp name suites.${name})
      (attrNames suites)
    );
    failed = filter (entry: !entry.passed) cases;
    passed = length cases - length failed;
    label = entry: "[${entry.suite}] ${entry.group}: ${entry.name}";
  in {
    inherit passed;
    total = length cases;
    failed = length failed;
    ok = failed == [];

    summary = concatStringsSep " " [
      "${toString passed}/${toString (length cases)} passed"
      ", ${toString (length failed)} failed"
    ];

    #> Per-suite tally, to see at a glance which file is unhappy.
    bySuite =
      mapAttrs (
        _: suites:
          concatStringsSep " " [
            (toString (
              (length cases)
              - (length (filter (entry: !entry.passed) suites))
            ))
            (toString (length suites))
          ]
      )
      suites;

    #> Display one line per case: "PASS [suite] group: name" / "FAIL ...".
    lines =
      map (
        entry: "${
          if entry.passed
          then "PASS"
          else "FAIL"
        } ${label entry}"
      )
      cases;

    #> Display only the failures, with what was expected and what came back.
    failures =
      map (entry: {
        inherit (entry) suite group name expected actual;
      })
      failed;

    inherit cases;
  };

  harness =
    fixtures
    // {
      inherit attempt makeCase makeThrowCase report fixtures;
    };

  #~@ Collector
  exclude = ["default.nix" "harness.nix" "fixtures" "review"];
  discover = directory: relative: let
    entries = readDir directory;
    names =
      filter
      (name: !(relative == "" && elem name exclude))
      (attrNames entries);

    visit = found: name: let
      path = directory + "/${name}";
      key =
        if relative == ""
        then name
        else "${relative}/${name}";
      stem = match "(.*)\\.nix" key;
      inner = discover path key;
    in
      if entries.${name} == "directory"
      then {
        suites = found.suites // inner.suites;
        skipped = found.skipped ++ inner.skipped;
      }
      else if stem == null
      then found
      else if isFunction (import path)
      then
        found
        // {
          suites = found.suites // {${head stem} = import path args harness;};
        }
      else found // {skipped = found.skipped ++ [key];};
  in
    foldl' visit {
      suites = {};
      skipped = [];
    }
    names;

  found = discover ./. "";
in
  harness.report found.suites // {inherit (found) skipped;}
