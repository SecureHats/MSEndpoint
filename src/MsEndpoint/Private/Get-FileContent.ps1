#This script requires User Administrator in the Azure Active Directory
function Get-FileContent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateScript( { (Test-Path -Path $_) -and ($_.Extension -in '.csv') })]
        [System.IO.FileInfo] $filePath
    )

    $content = @()

    switch ($filePath.Extension) {
        ".csv" {
            try {
                $content = Get-Content -Raw $filePath | ConvertFrom-Csv
            }
            catch {
                Write-Verbose $_
                Write-Error -Message 'Unable to import CSV file' -ErrorAction Stop
            }
          }
        ".json" {
            try {
                $content = Get-Content -Raw $filePath | ConvertFrom-Json -Depth 99
            }
            catch {
                Write-Verbose $_
                Write-Error -Message 'Unable to import JSON file' -ErrorAction Stop
            }
        }
        Default {
            Write-Error -Message 'Unsupported extension' -ErrorAction Stop
        }
    }
    return $content
}