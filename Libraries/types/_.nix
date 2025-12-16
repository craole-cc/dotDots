{_, ...}: let
  exports = _.types.predicates;
in
  exports
# // {
#   _rootAliases = {inherit enums;};
#   _tests = runTests {
#     #? Test structure exists
#     hasValues = mkTest true (hasAttrByPath ["enums" "developmentLanguages" "values"] _);
#     hasValidator = mkTest true (hasAttrByPath ["enums" "developmentLanguages" "validator"] _);
#     hasRootAlias = mkTest true (hasAttrByPath ["enums" "developmentLanguages"] _);
#     #? Test actual functionality
#     validatorWorks = mkTest true (_.enums.developmentLanguages.validator.check "rust");
#     valuesIsList = mkTest true (isList (_.enums.developmentLanguages.values or null));
#     #? Test multiple enums exist
#     hasAllCategories = mkTest true (
#       true
#       && hasAttrByPath ["enums" "developmentLanguages"] _
#       && hasAttrByPath ["enums" "hostFunctionalities"] _
#       && hasAttrByPath ["enums" "userRoles"] _
#       && hasAttrByPath ["enums" "bootLoaders"] _
#       && hasAttrByPath ["enums" "shells"] _
#     );
#     # Test enum count
#     hasExpectedEnumCount = mkTest 14 (length (attrNames enums));
#   };
# }
