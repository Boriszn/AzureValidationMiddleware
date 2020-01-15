############################################################
# Represents Authentication based Azure Managed Identities 
# uses oauth2 protocol based on JWT Tokens etc.
############################################################
class AuthorisationTokenManager
{
    hidden $PrincipalAccountId

    #############################################################
    # JWT Acces token
    # Notice: You can provide key here to use local development
    #############################################################
    hidden $AccessToken #= "<JWT token>"

    AuthorisationTokenManager($principalAccountId)
    {
        $this.PrincipalAccountId = $principalAccountId
    }

    # Retrives the token from managed idenitity server
    [string] GetAccessToken()
    {
        # Build Auth URL parameters
        $apiVersion = "2017-09-01"
        $resourceURI = "https://management.azure.com/"
        $msiEndpoint = $env:MSI_ENDPOINT
        $msiSecret =  $env:MSI_SECRET

        if(-not $msiEndpoint -and -not $msiSecret){
            Write-Host '--- Error: No MSI Enpoint and Secret found ! ---' 
            exit;
        }

        # Build auth token URL
        $tokenAuthURI = $msiEndpoint + "?resource=$resourceURI&api-version=$apiVersion"

        Write-Host "--- Start invoking the MSI with URL: " $tokenAuthURI

        # Get Access token response
        $tokenResponse = Invoke-RestMethod -Method Get -Headers @{"Secret"="$msiSecret"} -Uri $tokenAuthURI
        $tokenResponseAccessToken = $tokenResponse.access_token

        Write-Host $tokenResponseAccessToken

        return $tokenResponseAccessToken;
    }
    
    # Triggers the login process 
    # to perform operations for Azure Resources 
    # uses Principal Account Id and JWT token
    LoginWithAccessToken()
    {
        if(-not $this.AccessToken){
            $this.AccessToken = $this.GetAccessToken();
        }

        Write-Host "---- Start Login. PrincipalAccountId: " $this.PrincipalAccountId 

        # Login account using AccessToken and Principal Id 
        Login-AzAccount -AccessToken $this.AccessToken -AccountId $this.PrincipalAccountId
    }
}