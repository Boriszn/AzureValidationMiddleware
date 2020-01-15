#####################################################################
# Represents Storage Queues and contains operations to get queue 
# messages, Create new messages etc.
####################################################################
class QueueManager
{
    hidden $ResourceGroupName 
    hidden $StorageAccountName

    hidden $MainEventQueue 
    hidden $ProcessedQueueName
    hidden $FailedQueueName

    hidden $LastFailedMessage
    hidden $StorageAccount

    ##################################################################
    # Initialize and create Storage account context object 
    # requires Automation Account @Resourc Group, @StorageAccountName,  
    # @MainEventQueue (queue used as EventGrid endpoint/storage)
    ##################################################################
    QueueManager($resourceGroupName, $storageAccountName, $mainEventQueue, $processedQueueName, $failedQueueName)
    {
        $this.ResourceGroupName  = $resourceGroupName
        $this.StorageAccountName = $storageAccountName
        $this.MainEventQueue = $mainEventQueue
        $this.ProcessedQueueName  = $processedQueueName
        $this.FailedQueueName = $failedQueueName

        # Get storage account
        $this.StorageAccount = Get-AzStorageAccount -ResourceGroupName  $this.ResourceGroupName -Name $this.StorageAccountName
    }

    [string] GetQueueMessage()
    {
        # Get storage queue
        $queue = Get-AzStorageQueue –Name $this.ProcessedQueueName –Context $this.StorageAccount.Context

        # Read the message from the queue, then show the contents of the message. Read the other two messages, too.
        $queueMessage = $queue.CloudQueue.GetMessageAsync($null, $null, $null)

        $jsonData = ($queueMessage.Result.AsString | ConvertTo-Json -Depth 100)

        Write-Host $jsonData
        return $jsonData
    }

    [string] GetFailedQueueMessage()
    {
        Write-Host "-- Get Failed Queue Message, Queue -- " $this.FailedQueueName

        # Get storage queue
        $queue = Get-AzStorageQueue –Name $this.FailedQueueName –Context $this.StorageAccount.Context 

        # Set the amount of time you want to entry to be invisible after read from the queue
        # If it is not deleted by the end of this time, it will show up in the queue again
        $invisibleTimeout = [System.TimeSpan]::FromSeconds(2)

        # Read the message from the queue, then show the contents of the message. Read the other two messages, too.
        $queueMessage = $queue.CloudQueue.GetMessageAsync($invisibleTimeout, $null, $null)

        # $jsonData = ($queueMessage.Result.AsString | ConvertTo-Json -Depth 100)

        # Save message
        $this.LastFailedMessage = $queueMessage.Result

        Write-Host "-- Last message id: " $this.LastFailedMessage.Id

        $jsonData = $queueMessage.Result.AsString

        Write-Host "------------- Retry Message payload -----------------------"
        Write-Host $jsonData
        Write-Host "------------------------------------------------------------"

        return $jsonData
    }

    [bool] ProcessMessageQueue($message)
    {
        Write-Host "---- Processing the Message Queue has been Started -----"

        if((Get-Module -Name "Az.Storage").Count -eq 0){ 
            Import-Module Az.Storage 
        }

         # Get storage queue
        $queue = Get-AzStorageQueue –Name $this.ProcessedQueueName –Context $this.StorageAccount.Context 

        # Create a new message using a constructor of the CloudQueueMessage class
        $queueMessage = New-Object -TypeName "Microsoft.Azure.Storage.Queue.CloudQueueMessage,$($queue.CloudQueue.GetType().Assembly.FullName)" `
             -ArgumentList $message
        
        # Add a new message to the queue
        $isProcessed = $queue.CloudQueue.AddMessageAsync($QueueMessage)

        Write-Host $isProcessed
        
        return $true
    }

    [bool] DeleteFailedMessageFromQueue()
    {
        Write-Host "------ Delete Message from Queue -------"

         # Read the message from the queue, then show the contents of the message. Read the other two messages, too.
        $failedQueue = Get-AzStorageQueue –Name $this.FailedQueueName –Context $this.StorageAccount.Context 

        Write-Host "-- Message Id to delete:" $this.LastFailedMessage.Id

        # Delete message
        $failedQueue.CloudQueue.DeleteMessageAsync($this.LastFailedMessage.Id, $this.LastFailedMessage.popReceipt)

        return $true
    }
}