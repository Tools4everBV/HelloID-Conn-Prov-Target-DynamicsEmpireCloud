#################################################
# HelloID-Conn-Prov-Target-Empire-Cloud-Create
# PowerShell V2
#################################################

# Enable TLS1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

function New-AuthorizationHeaders {
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.Dictionary[[String], [String]]])]
    param(
        [parameter(Mandatory)]
        [string]
        $TenantId,

        [parameter(Mandatory)]
        [string]
        $ClientId,

        [parameter(Mandatory)]
        [string]
        $ClientSecret
    )
    try {
        Write-Verbose "Creating Access Token"
        $baseUri = "https://login.microsoftonline.com/"
        $authUri = $baseUri + "$TenantId/oauth2/v2.0/token"
    
        $body = @{
            grant_type    = "client_credentials"
            scope         = "https://api.businesscentral.dynamics.com/.default"
            client_id     = "$ClientId"
            client_secret = "$ClientSecret"
        }
    
        $Response = Invoke-RestMethod -Method POST -Uri $authUri -Body $body -ContentType 'application/x-www-form-urlencoded' 
        $accessToken = $Response.access_token
    
        #Add the authorization header to the request
        Write-Verbose 'Adding Authorization headers'

        $headers = [System.Collections.Generic.Dictionary[[String], [String]]]::new()
        $headers.Add('Authorization', "Bearer $accesstoken")
        $headers.Add('Accept', 'application/json')
        $headers.Add('Content-Type', 'application/json')

        Write-Output $headers  
    }
    catch {
        throw $_
    }
}


#region functions
function Resolve-EmpireError {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [object]
        $ErrorObject
    )
    process {
        $httpErrorObj = [PSCustomObject]@{
            ScriptLineNumber = $ErrorObject.InvocationInfo.ScriptLineNumber
            Line             = $ErrorObject.InvocationInfo.Line
            ErrorDetails     = $ErrorObject.Exception.Message
            FriendlyMessage  = $ErrorObject.Exception.Message
        }
        if (-not [string]::IsNullOrEmpty($ErrorObject.ErrorDetails.Message)) {
            $httpErrorObj.ErrorDetails = $ErrorObject.ErrorDetails.Message
        }
        elseif ($ErrorObject.Exception.GetType().FullName -eq 'System.Net.WebException') {
            if ($null -ne $ErrorObject.Exception.Response) {
                $streamReaderResponse = [System.IO.StreamReader]::new($ErrorObject.Exception.Response.GetResponseStream()).ReadToEnd()
                if (-not [string]::IsNullOrEmpty($streamReaderResponse)) {
                    $httpErrorObj.ErrorDetails = $streamReaderResponse
                }
            }
        }
        try {
            $errorDetailsObject = ($httpErrorObj.ErrorDetails | ConvertFrom-Json)
            # Make sure to inspect the error result object and add only the error message as a FriendlyMessage.
            # $httpErrorObj.FriendlyMessage = $errorDetailsObject.message
            $httpErrorObj.FriendlyMessage = $httpErrorObj.ErrorDetails # Temporarily assignment
        }
        catch {
            $httpErrorObj.FriendlyMessage = $httpErrorObj.ErrorDetails
        }
        Write-Output $httpErrorObj
    }
}
#endregion

try {
    # Initial Assignments
    $outputContext.AccountReference = 'Currently not available'

    # Validate correlation configuration
    if ($actionContext.CorrelationConfiguration.Enabled) {
        $correlationProperty = $actionContext.CorrelationConfiguration.accountField
        $correlationValue = $actionContext.CorrelationConfiguration.accountFieldValue
    
        if ([string]::IsNullOrEmpty($correlationProperty)) {
            Write-Warning "Correlation is enabled but not configured correctly."
            Throw "Correlation is enabled but not configured correctly."
        }
    
        if ([string]::IsNullOrEmpty($correlationValue)) {
            Write-Warning "The correlation value for [$correlationProperty] is empty. This is likely a scripting issue."
            Throw "The correlation value for [$correlationProperty] is empty. This is likely a scripting issue."
        }
    }
    else {
        $outputContext.AuditLogs.Add([PSCustomObject]@{
                Message = "Configuration of correlation is mandatory."
                IsError = $true
            })
        Throw "Configuration of correlation is mandatory."
    }

    # Setup authentication headers
    $splatParamsAuthorizationHeaders = @{
        TenantID = $actionContext.Configuration.TenantID
        Clientid=$($actionContext.Configuration.AppId)
        Clientsecret=$($actionContext.Configuration.AppSecret)
    }
    $authHeaders = New-AuthorizationHeaders @splatParamsAuthorizationHeaders

    Write-Verbose "Created authorization headers."

    #endregion Create authorization headers
    $environment = $($actionContext.Configuration.Environment)   
    $baseurl      = "https://api.businesscentral.dynamics.com/v2.0/$($actionContext.Configuration.TenantID)/$environment"
    
    # Get Users (with paging) & Filter on correlation fields
    $company = [uri]::EscapeDataString($actionContext.Configuration.DefaultCompany)
    $nextLink = "$baseurl/api/microsoft/automation/v2.0/users?company=$company"
    $Users = [System.Collections.Generic.List[object]]::new()

    do {
        $splatGetUsers = @{
            Uri     = $nextLink
            Method  = 'GET'
            Headers = $authHeaders
        }
        $response = Invoke-RestMethod @splatGetUsers

        foreach ($empireUser in $response.value) {
            $Users.Add($empireUser)
        }
        $nextLink = $response.'@odata.nextLink'
    } while (-not [string]::IsNullOrEmpty($nextLink))

    $User = $null
    if ($Users.Count -gt 0) {
        $Result = $Users | Group-Object $correlationProperty -AsHashTable
        $User = $Result[$correlationValue]
    }

    if (($user | measure-object).count -gt 1) {
        $auditMessage = "Multiple users found for [$($personContext.Person.DisplayName)] with correlationValue [$correlationValue]"
        Throw $auditMessage
    }
    elseif (($user | measure-object).count -eq 1) {
        $correlatedAccount = $user[0]
        $action = 'CorrelateAccount'
    }
    else {
        $action = 'NotFound'
    }

    # Process
    switch ($action) {
        'CorrelateAccount' {
            Write-Information 'Correlating Empire account'

            $outputContext.Data.userSecurityID = $($correlatedAccount.UserSecurityID)
            $outputContext.Data.Fullname = $($correlatedAccount.Displayname)
            $outputContext.Data.userName = $($correlatedAccount.Username)
            
            $accountRef = [PSCustomObject]@{
                UserSecurityID  = $outputContext.Data.UserSecurityID
                Fullname = $outputContext.Data.Fullname
                UserName    = $outputContext.Data.UserName
            }

            $outputContext.AccountReference = $accountRef
            $outputContext.Success = $true
        
            $outputContext.AuditLogs.Add([PSCustomObject]@{
                    Action  = 'CorrelateAccount'
                    Message = "Correlated account: [$($outputContext.Data.Username)]. UserSecurityID is: [$($outputContext.AccountReference.UserSecurityID)]"
                    IsError = $false
                })

            # Update is handled in the update script
            $outputContext.AccountCorrelated = $True
            break
        }

        'NotFound' {
            $outputContext.Success = $false
            $outputContext.AuditLogs.Add([PSCustomObject]@{
                    Action  = 'CorrelateAccount'
                    Message = "Correlate account was unsuccessful. User has not been found in Empire"
                    IsError = $true
                })

            break
        }
    }
}
catch {
    $outputContext.Success = $false
    $ex = $PSItem
    if ($($ex.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') -or
        $($ex.Exception.GetType().FullName -eq 'System.Net.WebException')) {
        $errorObj = Resolve-EmpireError -ErrorObject $ex
        $auditMessage = "Could not create or correlate Empire account. Error: $($errorObj.FriendlyMessage)"
        Write-Warning "Error at Line '$($errorObj.ScriptLineNumber)': $($errorObj.Line). Error: $($errorObj.ErrorDetails)"
    }
    else {
        $auditMessage = "Could not create or correlate Empire account. Error: $($ex.Exception.Message)"
        Write-Warning "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"
    }
    $outputContext.AuditLogs.Add([PSCustomObject]@{
            Message = $auditMessage
            IsError = $true
        })
}
