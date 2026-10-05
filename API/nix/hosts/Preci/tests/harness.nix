/**
Shared test harness.

Takes `lix` positionally. Returns the case constructors and the reporter that
`default.nix` uses to fold every suite into one result.

A case is `{ group, name, expected, actual, passed }`. A suite is a list of
cases. `report` takes an attrset of suites keyed by suite name.
*/
{
  lix,
  fixtures,
  ...
}: let
  inherit (lix.attrsets) attrNames mapAttrs;
  inherit (lix.lists) concatLists filter length;
  inherit (lix.debug) deepSeq tryEval;
  inherit (lix.strings) concatStringsSep;

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
in
  fixtures // {inherit attempt makeCase makeThrowCase report fixtures;}
