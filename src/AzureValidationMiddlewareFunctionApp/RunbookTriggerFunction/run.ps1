using namespace System.Net
Using module ".\..\common\ValidationManager.psm1" 
Using module ".\..\common\AuthorisationTokenManager.psm1" 
Using module ".\..\common\QueueManager.psm1" 
Using module ".\..\common\Configuration.psm1"

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Start from entry point funcion
[RunBookQueueManagerFunction]::new().Main($Request)

class RunBookQueueManagerFunction
{
    hidden $SecurityToken
    hidden $ValidationManager
    hidden $QueueManager
    hidden $authorisationTokenManager
    hidden $Configuration

    RunBookQueueManagerFunction()
    {
        $this.Configuration = [ConfigurationMapper]::new()
        $this.ValidationManager = [ValidationManager]::new()
        $this.AuthorisationTokenManager = [AuthorisationTokenManager]::new($this.Configuration.PrincipalAccountId)
        $this.QueueManager = [QueueManager]::new(
            $this.Configuration.ResourceGroupName, 
            $this.Configuration.StorageAccountName, 
            $this.Configuration.MainEventQueue,
            $this.Configuration.ProcessedEventQueue,
            $this.Configuration.FailedQueueName
            )

        $this.SecurityToken = $this.Configuration.SecurityToken
    }

    [void] Main($Request)
    {
        Write-Host "--- PowerShell HTTP trigger function processing a request ----"

        #1. Authentication
        $this.AuthorisationTokenManager.LoginWithAccessToken();

        # Get Queue
        $queueMessage = $this.QueueManager.GetQueueMessage();
        $this.ProcessRequest($Request, $queueMessage)

        # Validation 
        $this.Validate($queueMessage);
    }

    hidden Validate($queueMessage)
    {
        $password = $this.Configuration.DbSqlPassword  
        
        if($password -eq "")
        {
            Write-Host "--- Getting DB password ---"
            #3. Get db password from keyvault
            $password = (Get-AzKeyVaultSecret -VaultName $this.Configuration.DevCloudDevSharedVaultName `
                         -Name $this.Configuration.DbSqlPasswordSecret).SecretValueText
        }

        if(-not $password)
        {
            Write-Host "-- ERORR: Password field is empty !"
            exit;
        }

        if($this.ValidationManager.IsDatabaseHasConnection(
            $this.Configuration.DatabaseUserToValidate, 
            $password, 
            $this.Configuration.DatabaseServerToValidate, 
            $this.Configuration.DatabaseToValidate))
        {
            Write-Host "DB is reacheble."
            
            # 4. Put message to proccessd queue
            $this.QueueManager.ProcessMessageQueue($queueMessage);

            # 5. Delete message 
            $this.QueueManager.DeleteFailedMessageFromQueue()
        }
        else 
        {
            Write-Host "-- DB is not reacheble --"
        }
    }

    hidden ProcessRequest($Request, $message)
    {
        # Interact with query parameters or the body of the request.
        $token = $Request.Query.Token
        if (-not $token) {
            $token = $Request.Body.token
        }
        
        # Validate Security token
        if ($token -eq $this.SecurityToken) {
            $body = $message;
            $status = [HttpStatusCode]::OK
        }
        else {
            $status = [HttpStatusCode]::BadRequest
            $body = "Please pass the valid security token in the query string or in the request body."
        }

        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = $status
            Body = $body
        })
    }
}
