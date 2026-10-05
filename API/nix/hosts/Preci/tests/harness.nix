/**
Shared test harness.

Takes `lix` positionally. Returns the case constructors and the reporter that
`default.nix` uses to fold every suite into one result.

A case is `{ group, name, expected, actual, passed }`. A suite is a list of
cases. `report` takes an attrset of suites keyed by suite name.
*/
lix: let
  inherit (lix.lists) filter length;
  inherit (lix.debug) deepSeq tryEval;

  # Fully evaluate a value, reporting whether doing so threw. `tryEval` only
  # catches `throw` and `assert`: a missing attribute still aborts the run,
  # which is deliberate, since malformed data should be loud.
  attempt = value: tryEval (deepSeq value value);

  makeCase = group: name: actual: expected: let
    outcome = attempt actual;
  in {
    inherit group name expected;
    passed = outcome.success && outcome.value == expected;
    actual =
      if outcome.success
      then outcome.value
      else "<throws>";
  };

  # Passes when evaluating `value` throws.
  makeThrowCase = group: name: value:
    makeCase group name (!(attempt value).success) true;

  # Stamp every case in a suite with the suite it came from.
  stamp = suiteName: suiteCases:
    map (entry: entry // {suite = suiteName;}) suiteCases;

  report = suites: let
    suiteNames = builtins.attrNames suites;
    cases = builtins.concatLists (map (suiteName: stamp suiteName suites.${suiteName}) suiteNames);
    failed = filter (entry: !entry.passed) cases;
    passedCount = length cases - length failed;
    label = entry: "[${entry.suite}] ${entry.group}: ${entry.name}";
  in {
    total = length cases;
    passed = passedCount;
    failed = length failed;
    ok = failed == [];

    summary = "${toString passedCount}/${toString (length cases)} passed, ${toString (length failed)} failed";

    # Per-suite tally, to see at a glance which file is unhappy.
    bySuite =
      builtins.mapAttrs (
        suiteName: suiteCases: let
          suiteFailed = filter (entry: !entry.passed) suiteCases;
        in "${toString (length suiteCases - length suiteFailed)}/${toString (length suiteCases)}"
      )
      suites;

    # One line per case: "PASS [suite] group: name" / "FAIL ...".
    lines =
      map (
        entry: "${
          if entry.passed
          then "PASS"
          else "FAIL"
        } ${label entry}"
      )
      cases;

    # Only the failures, with what was expected and what came back.
    failures =
      map (entry: {
        inherit (entry) suite group name expected actual;
      })
      failed;

    inherit cases;
  };
in {
  inherit attempt makeCase makeThrowCase report;
}
