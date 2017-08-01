param(
	[string]$PackageVersion = $(Throw "You must supply a value for PackageVersion")
)

Configuration FullCreditBaseTier
{ 
  	param (
        [string]$MachineName,
        [string]$SxsSources,
		[string]$DSCDependenciesDirectory,
		[string]$MachineConfigsVersionNumber
    )

	Import-DscResource -ModuleName PSDesiredStateConfiguration

  	Node localhost 
  	{
		#shared
		Write-Host "Install .NET 3.5/3.0/2/0"
    	WindowsFeature DotNet35 
    	{ 
      		Ensure = "Present"
      		Name = "NET-Framework-Core"
    	} 

    	Write-Host "Install .NET 4.5"
    	WindowsFeature DotNet45 
    	{ 
      		Ensure = "Present"
      		Name = "NET-Framework-45-Core"
    	}

		Write-Host "Install ASP.NET 3.5"
    	WindowsFeature ASPNet35
    	{ 
    	  	Ensure = "Present"
      		Name = "Web-Asp-Net" 
    	}

		Write-Host "Install .NET Extensibility 3.5"
    	WindowsFeature ASPNet35Ext
    	{ 
    	  	Ensure = "Present"
      		Name = "Web-Net-Ext" 
    	}

		Write-Host "Install ASP.NET 4.5"
    	WindowsFeature ASPNet45
    	{ 
    	  	Ensure = "Present"
      		Name = "Web-Asp-Net45" 
    	}

		Write-Host "Install .NET Extensibility 4.5"
    	WindowsFeature ASPNet45Ext
    	{ 
    	  	Ensure = "Present"
      		Name = "Web-Net-Ext45" 
    	}
		#HACK
    	Write-Host "Set up the Net TCP Port Sharing Service configuration"
    	Script ConfigureNetTcpPortSharingUser
    	{ 
	        GetScript = {
				Import-Module "C:\DSC\Modules\TcpPortSharingSetup.psm1" -Force
            	Get-TcpPortSharingSetup
        	}
        	TestScript = {
				Import-Module "C:\DSC\Modules\TcpPortSharingSetup.psm1" -Force
	            Test-TcpPortSharingSetup
        	}
        	SetScript = {
				Import-Module "C:\DSC\Modules\TcpPortSharingSetup.psm1" -Force
	            Set-TcpPortSharingSetup
        	}
    	}
		
		Write-Host "Configure RPC limited range port allocation to work with firewalls "
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

$RunningScriptDirectory = (Split-Path $script:MyInvocation.MyCommand.Path)
$PackageModuleDirectory = Join-Path $RunningScriptDirectory "Modules"
$DependenciesDirectory 	= Join-Path $RunningScriptDirectory "Dependencies"
#$SimDirectory = Join-Path $DependenciesDirectory "ServerIntegrationManagement"
		
$DSCDirectory = "C:\DSC"
$DSCDependenciesDirectory = Join-Path $DSCDirectory "Dependencies"
$DscDependenciesCertDirectory = Join-Path $DSCDependenciesDirectory (Join-Path "Certificates" $CertSourceDirName)

#Write-Host "Preparing Server Integration Management folder"
#$ServerIntegrationDirectory = "C:\ServerIntegrationManagement"
#
#if(Test-Path $ServerIntegrationDirectory)
#{
#	Write-Host "Removing old ServiceIntegrationManagement directory"
#	Remove-Item	-Path $ServerIntegrationDirectory -Force -Recurse 
#}
#
#Write-Host "Move ServiceIntegrationManagement to a known location"
#Move-Item -Path $SimDirectory -Destination $ServerIntegrationDirectory -Force

Write-Host "Preparing DSC folder"
if(Test-Path $DSCDirectory)
{
	Write-Host "Removing old DSC directory"
	Remove-Item	-Path $DSCDirectory -Force -Recurse 
}

Write-Host "Copy Modules to a known location"
Copy-Item -Path $PackageModuleDirectory -Destination (Join-Path $DSCDirectory "Modules") -Recurse -Force

Write-Host "Copy Dependencies to a known location"
Copy-Item -Path $DependenciesDirectory -Destination $DSCDependenciesDirectory -Recurse -Force

#$sysinfo = Get-WmiObject -Class Win32_ComputerSystem
#$server = "{0}.{1}" -f $sysinfo.Name, $sysinfo.Domain
$server = "$env:ComputerName" # not in domain, so does not resolve with original method

FullCreditBaseTier `
    –MachineName $server `
    -SxsSources "c:\InstallArtifacts\sxs" `
	-DSCDependenciesDirectory $DSCDependenciesDirectory `
	-MachineConfigsVersionNumber $PackageVersion

Write-Host "`n MOF Files Generated `n"

# For some reason XML 3 and 4 keep saying they need a reboot - I don't believe this is a real requirement.
# Unfortunately the require reboot stops the rest of the configuration from being run. This code should make
# it try again and hopefully get past the VC7 install (which when not done makes the CallReport deployment fail)

[int]$maximumAttempts = 5
[int]$attempt = 0
[string]$DSCResultLog = "C:\temp\DSCLog.log"

do
{
    [bool]$stopLoop = $false
    [int]$attempt = ++$attempt

    Start-DscConfiguration –Path .\FullCreditBaseTier –Wait –Verbose -Force 4> $DSCResultLog

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
