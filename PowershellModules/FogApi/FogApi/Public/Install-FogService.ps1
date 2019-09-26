function Install-FogService {
<#
.SYNOPSIS
Attempts to install the fog service

.DESCRIPTION
Attempts to download and install silently and then not so silently the fog service

.PARAMETER fogServer
the server to download from and connect to

#>

    [CmdletBinding()]
    param (
        $fogServer = ((Get-FogServerSettings).fogServer)
    )
    begin {
        $fileUrl = "http://$fogServer/fog/client/download.php?newclient";
        $fileUrl2 = "http://$fogServer/fog/client/download.php?smartinstaller";
        Write-Host "Making temp download dir";
        mkdir C:\fogtemp;
        Write-Host "downloading installer";
        Invoke-WebRequest -URI $fileUrl -UseBasicParsing -OutFile 'C:\fogtemp\fog.msi';
        Invoke-WebRequest -URI $fileUrl2 -UseBasicParsing -OutFile 'C:\fogtemp\fog.exe';
    }
    process {
        Write-Host "installing fog service";
        Start-Process -FilePath msiexec -ArgumentList @('/i','C:\fogtemp\fog,msi','/quiet','/qn','/norestart') -NoNewWindow -Wait;
        if ($null -eq (Get-Service FogService -EA 0)) {
            & "C:\fogTemp\fog.exe";
            Write-Host "Waiting 10 seconds then sending 10 enter keys"
            Start-Sleep 10
            $wshell = New-Object -ComObject wscript.shell;
            $wshell.AppActivate('Fog Service Setup')            
            $wshell.SendKeys("{Enter}")
            $wshell.SendKeys("{Space}")
            $wshell.SendKeys("{Enter}")
            $wshell.SendKeys("{Enter}")
            $wshell.SendKeys("{Enter}")
            $wshell.SendKeys("{Enter}")
            Write-Host "waiting 30 seconds for service to install"
            Start-Sleep 30
            Write-host "sending more enter keys"
            $wshell.SendKeys("{Enter}")
            $wshell.SendKeys("{Enter}")
            $wshell.SendKeys("{Enter}")
            $wshell.SendKeys("{Enter}")
            $wshell.SendKeys("{Enter}")
        }
    }
    end {
        Write-Host "removing download file and temp folder";
        Remove-Item -Force -Recurse C:\fogtemp;
        Write-Host "Starting fogservice";
        if ($null -ne (Get-Service FogService)) {
            Start-Service FOGService;
        }
        return;
    }

}
