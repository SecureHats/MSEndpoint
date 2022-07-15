#requires -module @{ModuleName = 'Az.Accounts'; ModuleVersion = '2.7.2'}
#requires -version 6.2

function Get-AccessToken {
    <#
    .Synopsis
        Creates an Access token for Microsoft Graph
    .DESCRIPTION
        This function can be used to create an Access Token to query the Microsoft Graph API.
    .PARAMETER ApplicationId [string]
    Enter the Application ID
    .PARAMETER ApplicationSecret [string]
    Enter the Application Secret
    .PARAMETER TenantId [string]
    Enter the tenant id which looks like a guid
    .EXAMPLE
    This will request the access token on behalf of the current user and create a http header called $aadRequestHeader
    Get-AccessToken
    Invoke-RestMethod -Uri https://graph.microsoft.com/beta/users @aadRequestHeader
    .EXAMPLE
    This will request the access token for an App Registration and create a http header called $aadRequestHeader
    Get-AccessToken -ApplicationId 'MyApplicationId' -ApplicationSecret 'MySecretValue' -TenantId '3efd0d14-d94c-4cd2-8fe9-cef8616e3703'
    Invoke-RestMethod -Uri https://graph.microsoft.com/beta/users @aadRequestHeader
#>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$ApplicationId,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$ApplicationSecret,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$TenantId,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [switch]$SecurityGraph
    )
    begin {
        Write-Verbose "[+] Get-AccessToken : Checking if the Access Token in not expired "
        $startDate = (Get-Date).ToLocalTime()

        if(!([string]::IsNullOrEmpty($endDate))) {
            $valid = (New-TimeSpan –Start $startDate –End $endDate).Minutes
        }


        if ($valid -le 5) {
            Write-Verbose "[-] Get-AccessToken : The access token has been expired"
            $invalidToken = $true
        }
        else {
            Write-Verbose "[-] Get-AccessToken : Access token is valid until $endDate"
            $invalidToken = $false
        }
    }
    process {
        if ($invalidToken) {
            if (-not($ApplicationId)) {
                # Get Access Token from current context
                Write-Verbose "[-] Get-AccessToken : Get access token from current context"
                $graphToken = Get-AzAccessToken -ResourceTypeName MSGraph

                $script:endDate = ($graphToken.ExpiresOn).LocalDateTime
                $script:aadRequestHeader = @{
                    "Token"          = ($graphToken.Token | ConvertTo-SecureString -AsPlainText -Force)
                    "Authentication" = $graphToken.Type
                    "Method"         = 'GET'
                }
            }
            else {
                Write-Verbose "[-] Get-AccessToken : Get access token from App Registration"
                if ([string]::IsNullOrEmpty($ApplicationId) -or [string]::IsNullOrEmpty($ApplicationSecret) -or [string]::IsNullOrEmpty($TenantId)) {
                    Write-Error "Not all required parameters are provided"
                    return
                }

                $payload = @{
                    Grant_Type    = "client_credentials"
                    client_id     = "$ApplicationId"
                    client_secret = "$ApplicationSecret"
                }

                if ($SecurityGraph) {
                    $authUri = "https://login.windows.net/2d53d994-12d9-4e67-8d6e-e4f1677950fa/oauth2/token"
                    $payload.resource = 'https://api.security.microsoft.com'
                } else {
                    $authUri = "https://login.microsoftonline.com/2d53d994-12d9-4e67-8d6e-e4f1677950fa/oauth2/v2.0/token"
                    $payload.scope = 'https://graph.microsoft.com/.default'
                }
                try {
                    Write-Verbose "[-] Get-AccessToken : Requesting token from the Azure Active Directory"
                    $graphToken = Invoke-RestMethod -Uri $authUri -Method POST -Body $payload -ErrorVariable ErrMsg

                    $script:endDate = (Get-Date).AddSeconds($graphToken.expires_in)
                    $script:aadRequestHeader = @{
                        "Token"          = ($graphToken.access_token | ConvertTo-SecureString -AsPlainText -Force)
                        "Authentication" = $graphToken.token_type
                        "Method"         = 'GET'
                    }
                    Write-Verbose "[-] Get-AccessToken : Succesfully created access token"
                }
                catch {
                    Write-Error ((($ErrMsg.ErrorRecord | ConvertFrom-Json).error_description) -split ("`r"))[0]
                }
            }
        }
    }
}