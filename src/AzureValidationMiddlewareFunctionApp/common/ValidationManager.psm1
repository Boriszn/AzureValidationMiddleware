#####################################################################
# Contains Validation logic 
# (validates: dabase connnection, database existence, resource existence etc.)
####################################################################
class ValidationManager
{
    [bool] IsDatabaseHasConnection($user, $passwrd, $server, $database)
    {
        Write-Host "--- Try connect to the DB: $database | $server | $user"

        if(-not $user -or -not $passwrd -or -not $server -or -not $database){
            Write-Host "-- Some of database connection options is missing !"
            exit;
        }

        # build secure string password and PSCredenttilaObject
        $secpasswd = ConvertTo-SecureString $passwrd -AsPlainText -Force
        $Credentials = New-Object System.Management.Automation.PSCredential($user, $secpasswd)

        if((Get-Module -Name "SimplySql").Count -eq 0){ 
            Import-Module SimplySql 
        }

       try {
         Open-MySqlConnection -Server $Server -Database $Database -Credential $Credentials
         Write-Host "-Connected-" ;
        } catch {
           $FailMsg = "Error connecting to the database. Exiting..."
           $Message = $FailMsg + "`n" + $error[0].Exception 
           Write-Host $Message            
           return $false   
        }

        return $true
    }
}