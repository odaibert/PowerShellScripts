Configuration COMPlusContainer
{ 
  	param ([string]$MachineName)

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    
   	Node localhost
    {				
		Write-Warning "Configure RPC limited range port allocation to work with firewalls"
        
        Registry DCOMPorts
		{
			Ensure = "Present"
			Key = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Rpc\Internet"
			ValueName = "Ports"
			ValueData = "64535-65535"
			ValueType = "MultiString"
		}        
		Registry DCOMRpcInternetPortsInternetAvailable
		{
			Ensure = "Present"
			Key = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Rpc\Internet"
			ValueName = "PortsInternetAvailable"
			ValueData = "Y"
			ValueType = "String"
			DependsOn = "[Registry]DCOMPorts"
		}
		Registry DCOMRpcInternetUseInternetPorts
		{
			Ensure = "Present"
			Key = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Rpc\Internet"
			ValueName = "UseInternetPorts"
			ValueData = "Y"
			ValueType = "String"
			DependsOn = "[Registry]DCOMPorts"
		}
  	} 
}

Write-Host "`n Script Loaded `n"

Write-Host "Setup configuration Variables."

COMPlusContainer `
-MachineName $server 
`
$DSCResultLog = "c:\complus\output.log"

do
{
    [bool]$stopLoop = $false
    [int]$attempt = ++$attempt

    Write-Warning "Applying DSC configuration ..."
    
   Start-DscConfiguration –Path C:\complus\COMPlusContainer -ComputerName localhost –Wait –Verbose -Force 4> $DSCResultLog

   Write-Warning "Finished"

    [string[]]$rebootServerCoincidences = Select-String -Pattern "reboot" -Path $DSCResultLog

    if ($rebootServerCoincidences.Length -le 0)
    {
        [bool]$stopLoop = $true
    }
    else
    {
        Write-Warning "Something was judged to need a reboot. Running the configuration again as it will not have completed on the last run."
    }
}
while($stopLoop -eq $false -and $attempt -le $maximumAttempts)

if ($stopLoop -eq $false)
{
    Write-Warning "Max attempts reached"
}

Write-Host "`n Configuration applied. `n"

Write-Host "**************************************"
