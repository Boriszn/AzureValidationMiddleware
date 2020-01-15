############################################################
# Represents logic for Azure Automation account management 
# Functions: Trigger Runbok, Fetching VM info etc   
############################################################
class AutomationRunbookManager
{
    TriggerRunbookWebHook($QueueItem, $webhookUrl, $LabSubscription)
    {
        Write-Host "------ Trigger Automation Account Runbook with WebHook ------"

        if(!$webhookUrl){
            Write-Host "Please provide Webhook URI string"
            exit;
        }

        $ip = $this.GetVmIp($QueueItem, $LabSubscription)

        # Prepare Automation account Webhook payload
        $payload = @{
            "ipaddress" = $ip
         }

        Write-Host "----------- Queue Payload output ---------"

        Write-Host ($payload | ConvertTo-Json -Depth 100) | out-string

        Write-Host "------------------------------------------"
        
        Write-Host "---- Invoking the WebHook : " $webhookUrl;

       # Trigger a webhook
       $request = Invoke-WebRequest -UseBasicParsing `
        -Body (ConvertTo-Json -Compress -InputObject $payload) `
        -Method Post `
        -Uri $webhookUrl
         
        Write-Host "-- Done. Status Code:" $request.StatusCode
    }

    [String] GetVmIp($QueueItem, $LabSubscription)
    { 
        $vmid = "";

        Write-Host "------------ Start getting VM Ip (and other params) --------- "

        # Parse/Get subject URI name from Event Grid payload 
        Foreach ($Value in ($QueueItem.GetEnumerator() | Where-Object {$_.Key -eq "subject"}))
        {
            Write-Host "-------- Subject VM URI: " $Value.value
            $vmid = $Value.value
        }

        # Get Vm name and Resource Group from subject URI string
        $VmName = $vmid.split('/')[8]
        $ResourceGroup = $vmid.split('/')[4]

        Write-Host "-------- VM name: " $VmName " | Resource Group " $ResourceGroup 
   
        # Get Ip by VM Name and Resource Group
        $subscriptionId = (Get-AzContext).Subscription.id
        Write-Host "--- Current Subscription: " $subscriptionId
        Set-AzContext $LabSubscription
        
        $ip = (Get-AzNetworkInterface -Name $VmName -ResourceGroupName $ResourceGroup).IpConfigurations.PrivateIpAddress

        Write-Host "--------- Vm IP: " $ip
        Set-AzContext $subscriptionId

        return $ip;
    }
}