Write-Warning("Creating Application User  ")

$ApplicationUser = "OrderUser"
$UserPassword = "@windowsPhone7"

New-LocalUser $ApplicationUser -Password (ConvertTo-SecureString -AsPlainText $UserPassword -Force) -FullName "Order COM Plus" -Description "Local Administrator"

$comAdmin = New-Object -comobject COMAdmin.COMAdminCatalog
$apps = $comAdmin.GetCollection("Applications")
$apps.Populate();

$newComPackageName = "Service Fabric COM+ Example"

$appExistCheckApp = $apps | Where-Object {$_.Name -eq $newComPackageName}

if($appExistCheckApp)
{
    $appExistCheckAppName = $appExistCheckApp.Value("Name")
    "This COM+ Application already exists : $appExistCheckAppName"
}
Else
{
    $newApp1 = $apps.Add()
    $newApp1.Value("Name") = $newComPackageName
    $newApp1.Value("AccessChecksLevel") = 0
    $newApp1.Value("ApplicationAccessChecksEnabled") = $false
     <# https://msdn.microsoft.com/en-us/library/windows/desktop/ms686107(v=vs.85).aspx#applicationaccesschecksenabled #>
   

    $newApp1.Value("Identity") = $ApplicationUser 
    $newApp1.Value("Password") = $UserPassword

    $saveChangesResult = $apps.SaveChanges()
    
    "Results of the SaveChanges operation : $saveChangesResult"

}

$ContainerFolder = "C:\complus\"

Write-Warning ("Installing the .dll on Application " + $newComPackageName)
$comAdmin.InstallComponent($newComPackageName, $ContainerFolder + "COMPlusDotNet.dll", $null, $null)

Write-Warning("Exporting the Application Proxy for Application " + $newComPackageName)
$comAdmin.ExportApplication($newComPackageName, $ContainerFolder + "COMPlusDotNetProxy.msi", 2)