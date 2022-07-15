function Update-WindowsDefenderUpdateSignatures {
    <#
    .Synopsis
        Intitiate Update for MDE Signatures
    .DESCRIPTION
        This function forces and update of the MDE signatures for a given device.
    .PARAMETER DeviceName [string]
    Enter the Name of the Device to update the signatures for.
    .PARAMETER DeviceId [string]
    Enter the Device Object Id of the device to update the signature for.
    .PARAMETER InputFile [string]
    A valid CSV file containing the devices to update the signatures for.
    .EXAMPLE
    This will update the MDE signatures for one device.
    Update-WindowsDefenderUpdateSignatures -DeviceName 'exampleDevice'
    .EXAMPLE
    This will update the MDE signatures for one device.
    Update-WindowsDefenderUpdateSignatures DeviceObjectId '81ac766b-b462-4c62-95db-5dc94669758a'
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    param (
        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string]$DeviceName,

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string]$DeviceId,

        [parameter(Mandatory = $false)]
        [ValidateScript( { (Test-Path -Path $_) -and ($_.Extension -in '.csv', '.json') })]
        [System.IO.FileInfo] $InputFile
    )

    begin {
        Get-AccessToken

        #CONSTANTS
        $baseUri = 'https://graph.microsoft.com/beta/deviceManagement/managedDevices'
    }
    process {
        if (![string]::IsNullOrEmpty) {
            Write-Output "Collecting information from [$($InputFile)]"
            Get-FileContent -filePath $InputFile}

        if ([string]::IsNullOrEmpty($DeviceId)) {
            $deviceObjectId = (Invoke-RestMethod @aadRequestHeader -Uri "$baseUri/?`$filter=deviceName eq '$DeviceName'").value.id
        } else {
            $deviceObjectId = $DeviceId
        }
        $updateUri = '{0}/{1}/windowsDefenderUpdateSignatures' -f $baseUri, $deviceObjectId
        try {
            Write-Verbose "Update signatures for endpoint [$($updateUri)]"
            Invoke-RestMethod @aadRequestHeader -Method POST -uri $updateUri -ErrorVariable ErrMsg
        }
        catch {
            Write-Error ((($ErrMsg.ErrorRecord) | ConvertFrom-Json).error.message -split ("`r"))[0]
        }
    }
}
