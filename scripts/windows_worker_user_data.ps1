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

Function Set-WindowsHostsFileWithNFSHostFilesContent {
    <#
    .SYNOPSIS
        Set the Windows hosts file content with NFS Hosts File Content.
    #>

    [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [System.IO.FileInfo]$NFSHostsFolderPath,

            [Parameter(Mandatory = $true)]
            [System.IO.FileInfo]$WindowsHostsFilePath,

            [Parameter(Mandatory = $true)]
            [string]$ComputerName
        )

    try {
        Write-Log -Level Info "Setting Windows hosts file with NFS host files content"
        Get-ChildItem $NFSHostsFolderPath | 
        ForEach-Object {
            $Content = Get-Content $NFSHostsFolderPath\$_
            Add-Content -Path $WindowsHostsFilePath -Value $Content
        }

        $LocalIPV4Address = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias Ethernet).IPv4Address
        
        # Commenting the below line and not adding the IPV6 address to the hosts file as per the request and will be commented out when required
        #$LocalIPV6Address = (Get-NetIPAddress -AddressFamily IPv6 -InterfaceAlias Ethernet).IPv6Address

        $IPAddressArray = @($LocalIPV4Address, $LocalIPV6Address)

        #Foreach ($IPAddress in $IPAddressArray) {
            #Add-Content -Path $WindowsHostsFilePath -Value $IPAddress
        #}
        Add-Content -Path $WindowsHostsFilePath -Value "$($IPAddressArray[0]) `t $($ComputerName).ibm.com `t $($ComputerName)"
       

        Write-Log -Level Info "Write to hosts file is Successful, Hosts file path: $WindowsHostsFilePath"
    } catch {
        Write-Log -Level Error $_
        throw $_
    }
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
            [string]$ContentToReplace
        )

    try{
        $ManagementNodeList = ""
        Get-ChildItem $NFSHostsFolderPath |
        ForEach-Object {
            if ($ManagementNodeList -eq "") {
                $ManagementNodeList = $_.Name
            } else {
                $ManagementNodeList = $ManagementNodeList + " " + $_.Name
            }
        }
        Write-Log -Level Info "ManagementNodeList to write to Ego Config is $ManagementNodeList"
        Write-Log -Level Info "Getting Content of Ego Config file and replacing $ContentToReplace with $ManagementNodeList"

        $EgoConfigContent = (Get-Content -path $EgoConfigFilePath).replace($ContentToReplace, $ManagementNodeList)
        Set-Content -Path $EgoConfigFilePath -Value $EgoConfigContent
        Write-Log -Level Info "Updated ManagementNodeList in ego CONF file $EgoConfigFilePath"
    } catch {
        Write-Log -Level Error $_
    }
}

Function Mount-NFS {
    <#
    .SYNOPSIS
        Create SymbolicLink to NFS.
    #>

    [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [string]$StorageIP,
            
            [Parameter(Mandatory = $true)]
            [string]$ShareName,

            [Parameter(Mandatory = $true)]
            [string]$MountPoint
        )

    try {

        #Install NFS-Client to Mount NFS
        Write-Log -Level Info "Installing Windows Feature - NFS-Client"
        Install-WindowsFeature NFS-Client
        Write-Log -Level Info "Windows Feature - NFS-Client Installed successfully"
        Write-Log -Level Info "Creating SymbolicLink for NFS with IP $StorageIP to this Server"
        New-Item -Path $MountPoint -ItemType SymbolicLink -Target \\$StorageIP\$ShareName 
        if ($lastExitCode -eq 0) { 
            Write-Log -Level Info "Created SymbolicLink for NFS mount Successful"
        } else {
            Write-Log -Level Error "SymbolicLink creation for NFS failed, ExitCode: $lastExitCode"
        } 
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
        }

        egosh user logon -u Admin -x Admin

        Write-Log -Level Info "Registering Password for windows execution user"

        egosh ego execpasswd -u .\$EgoUserName -x $EgoPass -noverify

        Write-Log -Level Info "Registered Password for windows execution user"
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
        Since implementation uses custom images which comes with hostname, so changing the windows hostname to match cluster node's
    #>
    [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [string]$ComputerName
        )
    try {
        $CurrentComputerName = hostname
        Write-Log -Level Info "Modifying the Computer Name to $ComputerName"
        $Output = ECHO Y | NETDOM RENAMECOMPUTER $CurrentComputerName /NewName:$ComputerName
        $OutputString = Out-String -InputObject $Output
        Write-Log -Level Info $OutputString
    } catch {
        Write-Log -Level Error $_
    }
}

$ShareName = "data"
$MountPoint = "C:\NFSShare" 
$StorageIP = "${storage_ip}"
$cluster_id = "${cluster_id}"
$NFSHostsFolderPath = "$MountPoint\$cluster_id\hosts" 
$WindowsHostsFilePath = "$env:windir\system32\drivers\etc\hosts"
$ComputerName = "${computer_name}"
$ContentToReplace = "hpcc-symphony-windows-primary-0 hpcc-symphony-windows-secondary-0"
$EgoConfigFilePath = "C:\Program Files\IBM\SpectrumComputing\kernel\conf\ego.conf"
$EgoUserName = ${EgoUserName}
$EgoPass = ${EgoPassword}

$HostName = hostname
if ($HostName -ne $ComputerName) {
    ModifyComputerName -ComputerName $ComputerName
    Write-Log -Level Info "Modified the computer name, restart and execute the script again (exit 1003)"
    exit 1003
} else {
    Write-Log -Level Info "Computer Name is $ComputerName, executing the remaining logic after the reboot"

    Mount-NFS -StorageIP $StorageIP -ShareName $ShareName -MountPoint $MountPoint

    Set-WindowsHostsFileWithNFSHostFilesContent -NFSHostsFolderPath $NFSHostsFolderPath -WindowsHostsFilePath $WindowsHostsFilePath -ComputerName $ComputerName

    Edit-EgoConfigFile -NFSHostsFolderPath $NFSHostsFolderPath -EgoConfigFilePath $EgoConfigFilePath -ContentToReplace $ContentToReplace 

    RegisterPasswordForWindowsExecutionUser -EgoUserName $EgoUserName -EgoPass $EgoPass

    Restart-LIMService
}
