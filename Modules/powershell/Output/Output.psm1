#@ Load functions
. $PSScriptRoot/Command.ps1
. $PSScriptRoot/Context.ps1
. $PSScriptRoot/Pout.ps1
. $PSScriptRoot/Verbosity.ps1

#@ Run tests
# Test-GetContext
# Test-WriteOutput
Test-InvokeProcess
