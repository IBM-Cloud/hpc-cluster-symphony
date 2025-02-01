###################################################
# Copyright (C) IBM Corp. 2023 All Rights Reserved.
# Licensed under the Apache License v2.0
###################################################

#ps1_sysnative

Function Write-Log {
    <#
    .SYNOPSIS
        Writes log message to log file.
    .DESCRIPTION
        This function accepts a log message and optional log level,
        then adds a timestamped log message to the log file.
    .PARAMETER $Message
        Message string that will be added to the log file.
    .PARAMETER $Level
        Optional log level parameter that must be "Error", "Warn", or "Info".
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Error", "Warn", "Info")]
        [string]
        $Level
    )

    $LevelValue = @{Error = "Error"; Warn = "Warning"; Info = "Information"}[$Level]
    $LogFile = "$HOME\Desktop\WindowsWorker.log"
    $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
    Add-Content $LogFile -Value "$Stamp $LevelValue $Message"
}

Function Edit-EgoConfigFile {

    <#
    .SYNOPSIS
        Update the ego config file with Cluster Management Node List
    #>

    [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [System.IO.FileInfo]$NFSHostsFolderPath,

            [Parameter(Mandatory = $true)]
            [System.IO.FileInfo]$EgoConfigFilePath,

            [Parameter(Mandatory = $true)]
            [string]$ContentToReplace,

            [Parameter(Mandatory = $true)]
            [string]$NumExpectedManagementHosts
        )

    try{
        Write-Log -Level Info "Source Folder: $NFSHostsFolderPath Config Path: $EgoConfigFilePath Management Nodes: $NumExpectedManagementHosts"
        $ManagementNodes = @()
        while ($ManagementNodes.count -ne $NumExpectedManagementHosts)
        {
            Write-Log -Level Info "Waiting for management node list to be available $($ManagementNodes.count)/$NumExpectedManagementHosts"
            Start-Sleep 60
            foreach($f in (Get-ChildItem $NFSHostsFolderPath)) {
                if ($ManagementNodes -notcontains $f.Name) {
                    $ManagementNodes += $f.Name
                }
            }
        }

        $ManagementNodeList = $ManagementNodes -join ' '
        Write-Log -Level Info "ManagementNodeList to write to Ego Config is $ManagementNodeList"
        Write-Log -Level Info "Getting Content of Ego Config file and replacing $ContentToReplace with $ManagementNodeList"

        $EgoConfigContent = (Get-Content -path $EgoConfigFilePath).replace($ContentToReplace, $ManagementNodeList)
        Set-Content -Path $EgoConfigFilePath -Value $EgoConfigContent
        Write-Log -Level Info "Updated ManagementNodeList in ego CONF file $EgoConfigFilePath"
    } catch {
        Write-Log -Level Error $_
    }
}



Function sync-cos {
    <#
    .SYNOPSIS
        sync cos bucket to local
    #>

    [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [string]$access_key_id,

            [Parameter(Mandatory = $true)]
            [string]$secret_access_key,

            [Parameter(Mandatory = $true)]
            [string]$endpoint,

            [Parameter(Mandatory = $true)]
            [string]$location_constraint,

            [Parameter(Mandatory = $true)]
            [string]$bucket_name
        )

    try {

# Install rconfig
# Set variables
# Set TLS to use version 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$downloadUrl = "https://downloads.rclone.org/v1.68.1/rclone-v1.68.1-windows-amd64.zip"
$zipFilePath = "$env:TEMP\rclone-v1.68.1-windows-amd64.zip"
$extractPath = "$env:TEMP\rclone-extract"
$destinationPath = "C:\rclone"

# Create destination directory if it doesn't exist
if (-Not (Test-Path -Path $destinationPath)) {
    New-Item -ItemType Directory -Path $destinationPath

}

# Download the zip file
Write-Host "Downloading rclone..."
Invoke-WebRequest -Uri $downloadUrl -OutFile $zipFilePath -TimeoutSec 360

# Extract the zip file
Write-Host "Extracting rclone..."
Expand-Archive -Path $zipFilePath -DestinationPath $extractPath -Force

# Copy the rclone.exe to the destination folder
Write-Host "Copying rclone.exe to destination folder..."
Copy-Item -Path "$extractPath\rclone-v1.68.1-windows-amd64\rclone.exe" -Destination $destinationPath

# Clean up (optional)
Remove-Item -Path $zipFilePath
Remove-Item -Path $extractPath -Recurse

Write-Host "rclone setup complete!"

# Define the config file path
$configFilePath = "C:\Users\Administrator.HPCC-SYMPHONY-W\AppData\Roaming\rclone\rclone.conf"
$configFilePath_egouser = "C:\Users\egoadmin\AppData\Roaming\rclone\rclone.conf"

# Check if the folder exists, if not, create it
$folderPath = "C:\Users\Administrator.HPCC-SYMPHONY-W\AppData\Roaming\rclone"
$folderPath_egouser = "C:\Users\egoadmin\AppData\Roaming\rclone"
if (-not (Test-Path -Path $folderPath)) {
    New-Item -Path $folderPath -ItemType Directory
    Write-Host "Folder created at: $folderPath"
} else {
    Write-Host "Folder already exists: $folderPath"
}

if (-not (Test-Path -Path $folderPath_egouser)) {
    New-Item -Path $folderPath_egouser -ItemType Directory
    Write-Host "Folder created at: $folderPath_egouser"
} else {
    Write-Host "Folder already exists: $folderPath_egouser"
}


# Define the content of the config file with variables
$configContent = @"
[Symphony-windows]
type = s3
provider = IBMCOS
env_auth = true
access_key_id = $access_key_id
secret_access_key = $secret_access_key
region = other-v2-signature
endpoint = $endpoint
location_constraint = $location_constraint
acl = public-read
"@

# Create the config file with the defined content
$configContent | Out-File -FilePath $configFilePath -Encoding UTF8
# Create the config file with the defined content
$configContent | Out-File -FilePath $configFilePath_egouser -Encoding UTF8
# Output the result
$configContent | Out-File -FilePath "C:\rclone\rclone.conf" -Encoding UTF8

Write-Host "Config file generated at: $configFilePath"

##Sync the contents
New-Item -Path C:\NFSShare -ItemType Directory
Start-Sleep -Seconds 10
Set-Location -Path C:\rclone\
Invoke-Expression "C:\rclone\rclone sync Symphony-windows:$bucket_name C:\NFSShare"

} catch {
        Write-Log -Level Error $_
        throw $_
    }
}




Function RegisterPasswordForWindowsExecutionUser {
    <#
    .SYNOPSIS
        Registering password for windows execution user.
    #>
    [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [string]$EgoUserName,

            [Parameter(Mandatory = $true)]
            [string]$EgoPass
        )
    try {
        #Check if LIM Service is Started, Start if Stopped
        $LIMServiceStatus = (Get-Service -Name "LIM").Status

        if ($LIMServiceStatus -eq "Stopped") {
            Start-Service -Name "LIM"
            (Get-Service -Name "LIM").WaitForStatus("Running", $(New-TimeSpan -seconds 15))
        }

        $LIMServiceStatus = (Get-Service -Name "LIM").Status
        Write-Log -Level Info "LIM Status: $LIMServiceStatus"

        egosh user logon -u Admin -x Admin

        Write-Log -Level Info "Registering Password for windows execution user"

        $result = egosh ego execpasswd -u .\$EgoUserName -x $EgoPass -noverify | Out-String

        Write-Log -Level Info "Registered Password for windows execution user: $result"

    } catch {
        Write-Log -Level Error $_
    }
}

Function Restart-LIMService {
    <#
    .SYNOPSIS
        Restart the LIM service
    #>
    try {
        Write-Log -Level Info "Restarting LIM Service"

        Restart-Service -Name "LIM"

        Write-Log -Level Info "LIM Service Restarted"
    } catch {
        Write-Log -Level Error $_
    }
}

Function ModifyComputerName {
    <#
    .SYNOPSIS
        Since implementation uses custom images which comes with hostname,
        so changing the windows hostname to match cluster node's
        Updating the ethernet adapter DNS domain name to the DNS domain name
    #>
    [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [string]$ComputerName,

            [Parameter(Mandatory = $true)]
            [string]$DomainName
        )
    try {
        $CurrentComputerName = hostname
        Write-Log -Level Info "Modifying the Computer Name from $CurrentComputerName to $ComputerName.$DomainName"
        (Get-NetworkAdapterConfiguration).SetDNSDomain($DomainName)
        $Output = ECHO Y | NETDOM RENAMECOMPUTER $CurrentComputerName /NewName:$ComputerName
        $OutputString = Out-String -InputObject $Output
        Write-Log -Level Info $OutputString
    } catch {
        Write-Log -Level Error $_
    }
}

Function Get-NetworkAdapterConfiguration {
    <#
    .SYNOPSIS
        Find and return the network adapter configuration
    .DESCRIPTION
        Find and return the ethernet network adapter configuration using WMI
    #>

    $AdapterName = "Red Hat VirtIO Ethernet Adapter"
    $WmiParams = @{'class' = 'win32_networkadapterconfiguration'}
    return  (Get-WmiObject @WmiParams | ? {$_.Description -like $AdapterName})
}

Function Test-RebootRequired {
    <#
    .SYNOPSIS
        Checks to see if a reboot is required.
    .DESCRIPTION
        This function checks the registry to determine if a reboot is required before installation can occur.
        If the "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"
        registry key exists then a reboot is pending.
    #>

    return Test-Path -path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"
}

Function Write-Environment {
    <#
    .SYNOPSIS
        Writes header to the log file.
    .DESCRIPTION
        This function writes a header to the log file to capture general information about the
        script execution environment.
    #>
    Write-Log -Level Info "----------------------------------------"
    Write-Log -Level Info "Started executing $($MyInvocation.ScriptName)"
    Write-Log -Level Info "----------------------------------------"
    Write-Log -Level Info "Script Version: 2022.12.22"
    Write-Log -Level Info "Current User: $env:username"
    Write-Log -Level Info "Hostname: $env:computername"
    Write-Log -Level Info "Domain Name: $((Get-NetworkAdapterConfiguration).DNSDomain)"
    Write-Log -Level Info "DNS Search Order: $((Get-NetworkAdapterConfiguration).DNSServerSearchOrder)"
    Write-Log -Level Info "The OS Version is $((Get-CimInstance Win32_OperatingSystem).version)"
    Write-Log -Level Info "Host Version $($Host.Version)"
    Write-Log -Level Info "PowerShell version/build $($PSVersionTable.PSVersion)/$($PSVersionTable.BuildVersion)"
    $DotNet = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full"
    Write-Log -Level Info ".NET version/release $($DotNet.version)/$($DotNet.release)"
    if (Test-RebootRequired) {
        Write-Log -Level Info "Reboot required"
    }
}

$ShareName = "data"
$MountPoint = "C:\NFSShare"
$StorageIP = "${storage_ip}"
$cluster_id = "${cluster_id}"
$NFSHostsFolderPath = "$MountPoint\$cluster_id\hosts"
$ComputerName = "${computer_name}"
$DomainName = "${dns_domain_name}"
$ContentToReplace = "hpcc-symphony-windows-primary-0 hpcc-symphony-windows-secondary-0"
$EgoConfigFilePath = "C:\Program Files\IBM\SpectrumComputing\kernel\conf\ego.conf"
$EgoUserName = "${EgoUserName}"
$EgoPass = "${EgoPassword}"
$NumExpectedManagementHosts="${mgmt_count}"
$bucket_name="${bucket_name}"
$access_key_id="${access_key_id}"
$secret_access_key="${secret_access_key}"
$endpoint="${endpoint}"
$location_constraint="${location_constraint}"

Write-Environment
$HostName = hostname
if ($HostName -ne $ComputerName) {
    ModifyComputerName -ComputerName $ComputerName -DomainName $DomainName
    Write-Log -Level Info "Modified the computer name to $ComputerName.$DomainName, restart and execute the script again (exit 1003)"
    exit 1003
}

Write-Log -Level Info "Computer Name is $ComputerName, continuing configuration after reboot"


#Mount-NFS -StorageIP $StorageIP -ShareName $ShareName -MountPoint $MountPoint
sync-cos  -bucket_name $bucket_name  -access_key_id $access_key_id -secret_access_key $secret_access_key  -endpoint $endpoint -location_constraint  $location_constraint
##schedule job
# Define the action to run the rclone command in PowerShell
$action = New-ScheduledTaskAction -Execute "C:\rclone\rclone.exe" -Argument "sync Symphony-windows:$bucket_name C:\\NFSShare"
# Define the trigger to run every minute
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 1)
# Define the principal to run the task as an Administrator user (replace with actual username)
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
# Register the task in Task Scheduler (you will be prompted for the Administrator password)
Register-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -TaskName "RcloneSyncEveryMinuteAsSystem" -Description "Runs rclone sync every minute as SYSTEM to sync with Symphony-windows"



Edit-EgoConfigFile `
    -NFSHostsFolderPath $NFSHostsFolderPath `
    -EgoConfigFilePath $EgoConfigFilePath `
    -ContentToReplace $ContentToReplace `
    -NumExpectedManagementHosts $NumExpectedManagementHosts

RegisterPasswordForWindowsExecutionUser -EgoUserName $EgoUserName -EgoPass $EgoPass

Restart-LIMService
