Using module ".\..\common\ValidationManager.psm1" 
Using module ".\..\common\QueueManager.psm1"
Using module ".\..\common\AuthorisationTokenManager.psm1"
Using module ".\..\common\Configuration.psm1"

# Input bindings are passed in via param block.
param($Timer)

# Creates a Retry timer function object and Run Entry point functton
[RetryTimerFunction]::new().Main($Timer)

# The Timer Function class
class RetryTimerFunction
{
    $ValidationManager
    $QueueManager
    $authorisationTokenManager
    $Configuration

    RetryTimerFunction()
    {
        # Inititalise configuration
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
    }

    ## Entry point for RetryTimerFunction
    [void] Main($Timer)
    {
        Write-Host "--------- Started Timer function ----------"

        # 1. Authentication
        $this.AuthorisationTokenManager.LoginWithAccessToken();

        # 2. Get message from failed event queue 
        $failedQueueMessage = $this.QueueManager.GetFailedQueueMessage(); 
        
        if(!$failedQueueMessage){
            Write-Host "-- No new messages in the Failed Queue --"
            exit;
        }

        # 3. Validate
        $this.Validate($failedQueueMessage);
    }

    ## 3. Triggers Validation process
    ## TODO: Move to Function common module
    hidden Validate($failedQueueMessage)
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
            Write-Host "-- DB is reacheble, send to Processed"

            # 4. Put message to proccessd queue
            $this.ProcessMessageQueue($failedQueueMessage);

            # 5. Delete message 
            $this.QueueManager.DeleteFailedMessageFromQueue();

            # Write-Host "-- Getting Az Key Vault Secret " $this.Configuration.MangedIdentityWebhookSecret
            # Get webhook from the key vault
            # $webHookName = (Get-AzKeyVaultSecret -VaultName $this.Configuration.SharedKeyVaultName `
            #                      -Name $this.Configuration.MangedIdentityWebhookSecret).SecretValueText

            Write-Host "-- Web hook name: " $this.Configuration.DbSyncNewVmWebhook

            # 6. Trigger automation account
            $this.AutomationRunbookManager.TriggerRunbookWebHook($failedQueueMessage, 
                    $this.Configuration.DbSyncNewVmWebhook, 
                    $this.Configuration.LabSubscription)
        }
        else
        {
            Write-Host "--- Database is not reacheble ---"
        }
    }
    
    ## Proccess messages (Put messages to the processed Queue)
    hidden [void] ProcessMessageQueue($QueueItem)
    {
        Write-Host "------- Processing the Message"

        Push-OutputBinding -Name processedQueueItem -Value $QueueItem

        Write-Host "-- Message was processed --"
    }
}