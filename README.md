
![logo header](https://raw.githubusercontent.com/Boriszn/AzureValidationMiddleware/master/src/assets/img/logo-header.jpg  "logo header")

# Azure Validation Middleware  

Azure Validation Middleware solution which build using Azure Functions, Azure Event Grid and Azure Queue demonstrates power of Event Driven Architecture.
Solution was build using PowerShell Classes and uses OOP approach.  

Solution includes following azure resources:
- Azure EventGrid - as main event processor 
- Azure Queue Storage - as event storage
- Azure Function - as microservice which contains all validation and message processing logic

Below the use case where current solution/architecture: 

Subscription contains:
- Virtual Machines which grouped by recourse group or DevTestLab 
- Automation account's runbook - which setups some tools on VM
(perform VM hardening process) which requires connection on one or several Databases 

Current solution validates if required DB is exist and if yes it will trigger runbook otherwise it will retry/check N times 
and if it doesn't work after retries it will trigger alert within Log Analytics.

Also following solution recommended to use in following cases: 

- SSL certificate management (check certificate expiration time, log and inform, update certificate automatically)
- Create custom logic to build cloud expense reports  
- Cloud resources backup, check availability and log using Log Analytics   
- Resource clean up management 

## Hight-level Architecture 

![Azure Validation Middleware](https://raw.githubusercontent.com/Boriszn/AzureValidationMiddleware/master/src/assets/img/event-driven-architecture-main.jpg   "Azure Validation Middleware")

### Azure function's workflow  

![Azure function's workflow](https://raw.githubusercontent.com/Boriszn/AzureValidationMiddleware/master/src/assets/img/event-queue-functions-workflow.jpg   "Azure function's workflow")

![Runbook workflow triggering](https://raw.githubusercontent.com/Boriszn/AzureValidationMiddleware/master/src/assets/img/event-queue-functions-workflow-runbook.jpg  "Runbook workflow triggering")

## Contributing

1. Fork it!
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request