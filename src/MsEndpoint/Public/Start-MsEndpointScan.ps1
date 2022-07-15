function Start-MsEndpointFullScan {
    <#
    .Synopsis
        Intitiate Update for MDE Signatures
    .DESCRIPTION
        This function forces and update of the MDE signatures for a given device.
    .PARAMETER DeviceName [string]
    Enter the Name of the Device to update the signatures for.
    .PARAMETER ApplicationSecret [string]
    Enter the Device Object Id of the device to update the signature for.
    .PARAMETER InputFile [string]
    A valid CSV file containing the devices to update the signatures for.
    .EXAMPLE
    This will start a quickscan for one device based on the deviceId.
    Start-MsEndpointScan deviceId '81ac766b-b462-4c62-95db-5dc94669758a'
    .EXAMPLE
    This will start a quickscan for one device based on the deviceName.
    Start-MsEndpointScan deviceName 'LAP1900'
    .EXAMPLE
    This will start a quickscan for one device based on the deviceName.
    Start-MsEndpointScan deviceName 'LAP1900'
    .EXAMPLE
    This will start a Full scan for one device based on the deviceName.
    Start-MsEndpointScan deviceName 'LAP1900' -FullScan
    .EXAMPLE
    This will start a quickscan for one device based on the named pipe values from an PsCustomObject.
    $devices = Get-MsEndpointDevices -filter 'Windows'
    $devices | Start-MsEndpointScan deviceName 'LAP1900'
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$DeviceName,

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string]$DeviceId,

        [parameter(Mandatory = $false)]
        [ValidateScript( { (Test-Path -Path $_) -and ($_.Extension -in '.csv', '.json') })]
        [System.IO.FileInfo] $InputFile,

        [parameter(Mandatory = $false)]
        [switch]$FullScan
    )

    begin {
        Get-AccessToken

        #CONSTANTS
        $baseUri = 'https://graph.microsoft.com/beta/deviceManagement/managedDevices'
    }
    process {
        if ([string]::IsNullOrEmpty($DeviceId)) {
            $deviceObjectId = (Invoke-RestMethod @aadRequestHeader -Uri "$baseUri/?`$filter=deviceName eq '$DeviceName'").value.id
        } else {
            $deviceObjectId = $DeviceId
        }

        $uri = '{0}/{1}/windowsDefenderScan' -f $baseUri, $deviceObjectId
        $payload = @{
            "quickScan" = $FullScan
        }
        try {
             Write-Verbose "Starting QuickScan for endpoint [$($uri)]"
             Invoke-RestMethod @aadRequestHeader -Method POST -uri $uri -Body ($payload | ConvertTo-Json -Compress) -ContentType 'application/json' -ErrorVariable ErrMsg
        }
        catch {
            $ErrMsg
            Write-Error ((($ErrMsg.ErrorRecord) | ConvertFrom-Json).error.message -split ("`r"))[0]
        }
    }
}