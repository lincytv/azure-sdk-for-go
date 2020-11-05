# Common Changelog Operations
. "${PSScriptRoot}\logging.ps1"
. "${PSScriptRoot}\SemVer.ps1"

$RELEASE_TITLE_REGEX = "(?<releaseNoteTitle>^\#+.*(?<version>\b\d+\.\d+\.\d+([^0-9\s][^\s:]+)?)(\s(?<releaseStatus>\(Unreleased\)|\(\d{4}-\d{2}-\d{2}\)))?)"
$CHANGELOG_UNRELEASED_STATUS = "(Unreleased)"
$CHANGELOG_DATE_FORMAT = "yyyy-MM-dd"

# Returns a Collection of changeLogEntry object containing changelog info for all version present in the gived CHANGELOG
function Get-ChangeLogEntries {
  param (
    [Parameter(Mandatory = $true)]
    [String]$ChangeLogLocation
  )

  $changeLogEntries = @{}
  if (!(Test-Path $ChangeLogLocation)) {
    Write-Error "ChangeLog[${ChangeLogLocation}] does not exist"
    return $null
  }

  try {
    $contents = Get-Content $ChangeLogLocation
    # walk the document, finding where the version specifiers are and creating lists
    $changeLogEntry = $null
    foreach ($line in $contents) {
      if ($line -match $RELEASE_TITLE_REGEX) {
        $changeLogEntry = New-ChangeLogEntry -Version $matches["version"] -Status $matches["releaseStatus"] `
        -Title $line
        $changeLogEntries[$changeLogEntry.ReleaseVersion] = $changeLogEntry
      }
      else {
        if ($changeLogEntry) {
          $changeLogEntry.ReleaseContent += $line
        }
      }
    }
  }
  catch {
    Write-Host "Error parsing $ChangeLogLocation."
    Write-Host $_.Exception.Message
  }
  return $changeLogEntries
}

# Returns single changeLogEntry object containing the ChangeLog for a particular version
function Get-ChangeLogEntry {
  param (
    [Parameter(Mandatory = $true)]
    [String]$ChangeLogLocation,
    [Parameter(Mandatory = $true)]
    [String]$VersionString
  )
  $changeLogEntries = Get-ChangeLogEntries -ChangeLogLocation $ChangeLogLocation

  if ($changeLogEntries -and $changeLogEntries.ContainsKey($VersionString)) {
    return $changeLogEntries[$VersionString]
  }
  return $null
}

#Returns the changelog for a particular version as string
function Get-ChangeLogEntryAsString {
  param (
    [Parameter(Mandatory = $true)]
    [String]$ChangeLogLocation,
    [Parameter(Mandatory = $true)]
    [String]$VersionString
  )

  $changeLogEntry = Get-ChangeLogEntry -ChangeLogLocation $ChangeLogLocation -VersionString $VersionString
  return ChangeLogEntryAsString $changeLogEntry
}


function ChangeLogEntryAsString($changeLogEntry) {
  if (!$changeLogEntry) {
    return "[Missing change log entry]"
  }
  [string]$releaseTitle = $changeLogEntry.ReleaseTitle
  [string]$releaseContent = $changeLogEntry.ReleaseContent -Join [Environment]::NewLine
  return $releaseTitle, $releaseContent -Join [Environment]::NewLine
}

function Confirm-ChangeLogEntry {
  param (
    [Parameter(Mandatory = $true)]
    [String]$ChangeLogLocation,
    [Parameter(Mandatory = $true)]
    [String]$VersionString,
    [boolean]$ForRelease = $false
  )

  $changeLogEntry = Get-ChangeLogEntry -ChangeLogLocation $ChangeLogLocation -VersionString $VersionString

  if (!$changeLogEntry) {
    Write-Error "ChangeLog[${ChangeLogLocation}] does not have an entry for version ${VersionString}."
    return $false
  }

  Write-Host "Found the following change log entry for version '${VersionString}' in [${ChangeLogLocation}]."
  Write-Host "-----"
  Write-Host (ChangeLogEntryAsString $changeLogEntry)
  Write-Host "-----"

  if ([System.String]::IsNullOrEmpty($changeLogEntry.ReleaseStatus)) {
    Write-Error "Entry does not have a correct release status. Please ensure the status is set to a date '(yyyy-MM-dd)' or '$CHANGELOG_UNRELEASED_STATUS' if not yet released."
    return $false
  }

  if ($ForRelease -eq $True) {
    if ($changeLogEntry.ReleaseStatus -eq $CHANGELOG_UNRELEASED_STATUS) {
      Write-Error "Entry has no release date set. Please ensure to set a release date with format 'yyyy-MM-dd'."
      return $false
    }

    if ([System.String]::IsNullOrWhiteSpace($changeLogEntry.ReleaseContent)) {
      Write-Error "Entry has no content. Please ensure to provide some content of what changed in this version."
      return $false
    }
  }
  return $true
}

function New-ChangeLogEntry {
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]$Version,
    [String]$Status=$CHANGELOG_UNRELEASED_STATUS,
    [String]$Title,
    [String[]]$Content,
    [String]$IgnoreInvalids=$True
  )

  # Validate RelaseStatus
  $Status = $Status.Trim().Trim("()")
  if ($Status -ne "Unreleased") {
    try {
      $Status = ([DateTime]$Status).ToString($CHANGELOG_DATE_FORMAT)
    }
    catch {
        LogWarning "Invalid date [ $Status ] passed as status for Version [$Version]. Please use a valid date in the format '$CHANGELOG_DATE_FORMAT' or use '$CHANGELOG_UNRELEASED_STATUS'"
        if (!$IgnoreInvalids) { exit 1 }
    }
  }
  $Status = "($Status)"

  # Validate Version
  try {
    $Version = ([AzureEngSemanticVersion]::ParseVersionString($Version)).ToString()
  }
  catch {
    LogWarning "Invalid version [ $Version ]."
    if (!$IgnoreInvalids) { exit 1 }
  }

  if (!$Content) { $Content = @() }
  if (!$Title) { $Title = "## $Version $Status" }

  $newChangeLogEntry = [pscustomobject]@{ 
    ReleaseVersion = $Version
    ReleaseStatus  = $Status
    ReleaseTitle   = $Title
    ReleaseContent = $Content
  }

  return $newChangeLogEntry
}

function Set-ChangeLogContent {
  param (
    [Parameter(Mandatory = $true)]
    [String]$ChangeLogLocation,
    [Parameter(Mandatory = $true)]
    $ChangeLogEntries
  )

  $changeLogContent = @()
  $changeLogContent += "# Release History"
  $changeLogContent += ""

  try
  {
    $VersionsSorted = [AzureEngSemanticVersion]::SortVersionStrings($ChangeLogEntries.Keys)
  }
  catch {
    LogError "Problem sorting version in ChangeLogEntries"
    return
  }

  foreach ($version in $VersionsSorted) {
    $changeLogEntry = $ChangeLogEntries[$version]
    $changeLogContent += $changeLogEntry.ReleaseTitle
    if ($changeLogEntry.ReleaseContent.Count -eq 0) {
      $changeLogContent += @("","")
    }
    else {
      $changeLogContent += $changeLogEntry.ReleaseContent
    }
  }

  Set-Content -Path $ChangeLogLocation -Value $changeLogContent
}