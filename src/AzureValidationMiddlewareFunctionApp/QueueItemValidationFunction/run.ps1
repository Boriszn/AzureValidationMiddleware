Using module ".\..\common\ValidationManager.psm1" 
Using module ".\..\common\AutomationRunbookManager.psm1" 
Using module ".\..\common\AuthorisationTokenManager.psm1"
Using module ".\..\common\Configuration.psm1"

# Input bindings are passed in via param block.
param([System.Collections.Hashtable] $QueueItem, $TriggerMetadata)

#1. Create object of ValidationFunction class and trigger Main enrty function
[ValidationFunction]::new().Main($QueueItem, $TriggerMetadata)

#2. function class declaration
class ValidationFunction
{
    $ValidationManager
    $AutomationRunbookManager
    $AuthorisationTokenManager
    $Configuration

    ValidationFunction()
    {
        # Init dependent objects
        $this.Configuration = [ConfigurationMapper]::new()
        $this.ValidationManager = [ValidationManager]::new()
        $this.AutomationRunbookManager = [AutomationRunbookManager]::new()
        $this.AuthorisationTokenManager = [AuthorisationTokenManager]::new($this.Configuration.PrincipalAccountId)
    }

    [void] Main([System.Collections.Hashtable] $QueueItem, $TriggerMetadata)
    {
        Write-Host "----- Main Queue Processor Function Started. Queue item insertion time: $($TriggerMetadata.InsertionTime) ---- \n" 

        # 1. Authentication
        $this.AuthorisationTokenManager.LoginWithAccessToken();

        # 2. Display event grid payload data
        $this.DisplayQueueItemData($QueueItem)

        # 4. Validate
        $this.Validate($QueueItem);
    }

    ## 3. Triggers Validation process
    ## TODO: Move to Function common module
    hidden Validate($QueueItem)
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
            
            # 5. Put message to proccessd queue
            $this.SendToProcessedQueue($QueueItem)

            # Get webhook from the key vault
            # $webHookName = (Get-AzKeyVaultSecret -VaultName $this.Configuration.SharedKeyVaultName `
            #                      -Name $this.Configuration.MangedIdentityWebhookSecret).SecretValueText

            Write-Host "-- Web hook name: " $this.Configuration.DbSyncNewVmWebhook

            # 6. Trigger automation account
            $this.AutomationRunbookManager.TriggerRunbookWebHook($QueueItem, 
                    $this.Configuration.DbSyncNewVmWebhook, 
                    $this.Configuration.LabSubscription)
        }
        else
        {
            Write-Host "--- Database is not reacheble ---" 
            # 4. Put message to retry queue
            $this.SendToRetryQueue($QueueItem)
        }
    }

    hidden [void] SendToRetryQueue($QueueItem)
    {
        Push-OutputBinding -Name retryQueueItem -Value $QueueItem
    }

    hidden [void] SendToProcessedQueue($QueueItem)
    {
        Push-OutputBinding -Name processedQueueItem -Value $QueueItem
    }

    [void] DisplayQueueItemData($QueueItem)
    {
        Write-Host "--- Event grid payload data ----"

        $QueueItem.GetEnumerator() | ForEach-Object {
            $message = "{0} : {1} " -f $_.key, $_.value
            Write-Host $message
        }
    }
}