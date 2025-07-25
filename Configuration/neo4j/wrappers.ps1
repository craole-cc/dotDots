function Global:Deploy-Neo4jSourceLink {
  [CmdletBinding()]
  param(

    [Parameter(Mandatory = $false)]
    [Alias( 'name')]
    [string]$Database,

    [Parameter(Mandatory = $true)]
    [Alias('i', 'instance', 'l', 'link')]
    [string]$InstancePath,

    [Parameter(Mandatory = $true)]
    [Alias('data', 's', 'src')]
    [string]$SourcePath
  )

  $importPath = Join-Path -Path $InstancePath -ChildPath 'import'

  if ($Database) {
    $importPath = Join-Path $importPath -ChildPath $Database
  }

  # Create the link
  New-Link -Source $SourcePath -Target $importPath
}

function Global:Deploy-Neo4jIMDB {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $false)]
    [Alias('i', 'instance', 'l', 'link')]
    [string]$InstancePath = $env:NEO4J_SECOND_HOME,

    [Parameter(Mandatory = $false)]
    [Alias('data', 's', 'src')]
    [string]$SourcePath = 'D:\Datasets\IMDB\source'
  )

  # $sources = Get-ChildItem -Path $SourcePath -Filter *.tsv
  $sources = Get-ChildItem -Path 'D:\Datasets\IMDB\source' -Filter *.tsv
  $db = 'imdb'

  foreach ($source in $sources) {
    Deploy-Neo4jSourceLink `
      -SourcePath $source.FullName `
      -InstancePath $InstancePath `
      -Database $db
  }
}
