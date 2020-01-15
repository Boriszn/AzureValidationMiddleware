#####################################################################
# Uploads the Configuration Options which stored on settings.json
# local.settings.json - configuration related to local development
# template.settings.json - configuration template file used 
# for CI/CD pipelines (configuration data will be replaces during 
# pipeline deployment)
####################################################################
class ConfigurationMapper 
{

    hidden [string]$configurationLocalFilePath = ".\local.settings.json"
    hidden [string]$configurationTemplateFilePath = ".\template.settings.json"

    ## Authentication
    $PrincipalAccountId
    ## Key Vault
    $SharedKeyVaultName
    $MangedIdentityWebhookSecret
    ## Queue manager
    $ResourceGroupName
    $StorageAccountName
    $MainEventQueue
    $ProcessedQueueName
    $FailedQueueName
    ## DB settings
    $DatabaseToValidate
    $DatabaseServerToValidate
    $DevCloudDevSharedVaultName
    $DbSqlPasswordSecret
    $DatabaseUserToValidate
    $DbSqlPassword
    $LabSubscription
    $DbSyncNewVmWebhook

    ## HTTP otions
    $SecurityToken

    ConfigurationMapper() 
    {
        Write-Host "----- Start reading the configuration ------"
       
        $data = { }
        
        try {
            if ([System.IO.File]::Exists($this.configurationLocalFilePath)) {
                $data = Get-Content -Raw -Path $this.configurationLocalFilePath | ConvertFrom-Json
            }
            else {
                $data = Get-Content -Raw -Path $this.configurationTemplateFilePath | ConvertFrom-Json
            }
        }
        catch {
            Write-Host "File reading error"
        }
      
        if ($data -eq { }) {
            Write-Host "- Error: No configuration data found"
            exit;
        }

        Write-Host "-- Configuration data: " ($data | ConvertTo-Json)

        ## Confiration Mappings
        $this.PrincipalAccountId = $data.principalAccountId
        $this.SharedKeyVaultName = $data.sharedKeyVaultName
        $this.MangedIdentityWebhookSecret = $data.mangedIdentityWebhookSecret
        $this.ResourceGroupName = $data.resourceGroupName
        $this.StorageAccountName = $data.storageAccountName
        $this.MainEventQueue = $data.mainEventQueue
        $this.ProcessedQueueName = $data.processedQueueName
        $this.FailedQueueName = $data.failedQueueName
        $this.SecurityToken = $data.securityToken
        ## DB settings
        $this.DatabaseToValidate = $data.databaseToValidate
        $this.DatabaseServerToValidate = $data.databaseServerToValidate
        $this.DevCloudDevSharedVaultName = $data.devcloudDevSharedVaultName
        $this.DbSqlPasswordSecret = $data.dbSqlPasswordSecret
        $this.DatabaseUserToValidate = $data.DatabaseUserToValidate
        $this.DbSqlPassword = $data.dbSqlPassword
        $this.LabSubscription = $data.labSubscription
        $this.DbSyncNewVmWebhook = $data.DbSyncNewVmWebhook
    }
}