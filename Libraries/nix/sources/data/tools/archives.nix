{
  mkAliasFamily,
  mergeDisjoint,
  mkSource,
  ...
}: {
  ouch = mkSource {
    categories = ["archives" "scripting"];
    description = "unified archive compressor and decompressor for tar, zip, 7z, gz, xz, zst, and more";
    aliases = mergeDisjoint [
      (mkAliasFamily "ouch" {
        aliasPrefix = "";
        lsar = {
          args = ["list"];
          description = "list archive contents";
        };
        lsarTree = {
          args = ["list" "--tree"];
          description = "list archive contents as a tree";
        };
        pack = {
          args = ["compress"];
          description = "compress files into an archive";
        };
        packYes = {
          args = ["compress" "--yes"];
          description = "compress files, overwriting existing output without asking";
        };
        unpack = {
          args = ["decompress"];
          description = "decompress an archive";
        };
        unpackTo = {
          args = ["decompress" "--dir"];
          description = "decompress into a caller-specified directory";
        };
        unpackYes = {
          args = ["decompress" "--yes"];
          description = "decompress, overwriting existing files without asking";
        };
      })
    ];
  };
}
