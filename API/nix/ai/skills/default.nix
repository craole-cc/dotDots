{
  lix,
  pkgs,
  inputs,
  ...
}: let
  inherit (lix.attrsets.access) attrNames;
  inherit (lix.attrsets.construction) listToAttrs;
  inherit (lix.filesystem.access) readDir readFile;
  inherit (lix.filesystem.primitives) concat;
  inherit (lix.lists.transformation) filter;
  inherit (lix.strings.access) stringLength substring;
  inherit (lix.strings.predicates) hasSuffix;

  openai = let
    source =
      (inputs.codex-skills or {
        }).outPath or (pkgs.fetchFromGitHub {
        #? OpenAI's curated skills, pinned. To update:
        #? - bump `rev`,
        #? - set `hash` to lib.fakeHash
        #? - attempt build
        #? - copy the discovered hash Nix reports.
        owner = "openai";
        repo = "skills";
        rev = "49f948faa9258a0c61caceaf225e179651397431";
        hash = "sha256-t4oGnFg0YpxJaQiFpgTiwYhaFoZK6wPDiqvHoG0bXiU=";
      });
    target = name: let
      path = concat {
        root = source;
        stem = ["skills" ".curated" name];
      };
    in
      path;
  in {inherit source target;};

  #> Dynamically collect all custom `.md` skills in this directory.
  entries = readDir ./.;
  local = listToAttrs (
    map (file: {
      name = substring 0 (stringLength file - 3) file;
      value = readFile (./. + "/${file}");
    })
    (
      filter
      (file: entries.${file} == "regular" && hasSuffix ".md" file)
      (attrNames entries)
    )
  );
  hermesSource = (inputs.hermes or inputs.hermes-agent).outPath;
  provenance = pkgs.writeText "hermes-documentation-source.json" (lix.strings.construction.toJSON {
    repository = "https://github.com/NousResearch/hermes-agent";
    revision = (inputs.hermes or inputs.hermes-agent).rev or null;
    source = toString hermesSource;
    documentation = "website/docs";
    officialIndex = "https://hermes-agent.nousresearch.com/docs/llms.txt";
    scope = "Complete pinned documentation tree; no runtime data or credentials.";
  });
  documentation = pkgs.runCommand "hermes-agent-docs-skill" {} ''
    mkdir -p "$out/references"
    cp -R ${./hermes-agent-docs}/. "$out/"
    cp -R ${hermesSource}/website/docs "$out/references/upstream"
    cp ${hermesSource}/LICENSE "$out/references/UPSTREAM-LICENSE"
    cp ${provenance} "$out/references/SOURCE.json"
  '';
in {
  custom = local // {hermes-agent-docs = toString documentation;};
  curated = {
    default = ["gh-fix-ci" "gh-address-comments"];
    inherit (openai) source target;
  };
}
