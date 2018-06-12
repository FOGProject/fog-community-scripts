<#
    -----------------------------------------------------------------------------
    Script Name: StartLayoutCreator
    Original Author: JJ Fullmer
    Created Date: 2017-10-04
    Version: 2.2
    -----------------------------------------------------------------------------
#>
function New-StartLayout {
    <#
    .SYNOPSIS
    Create a new start layout object from legacy start menu folders
    
    .DESCRIPTION
    Goes through the current user's or a given path of shortcuts and creates a layout with groups and sub groups based on 
    folders and subfolders.
    Gets the appid of each program and whether it's a desktop or windows store app using the get-startapps cmdlet
    After creating a startlayout you can export-startlayoutxml and then set-startlayout 
    Currently only supports tiles of 2x2 (medium) size. Could be made to work with small tiles, but wide size tiles might be trickier.
    
    .PARAMETER startMenuPath
    the path to the shortcut files desired to become a start layout
    
    .PARAMETER width
    The width of the layout, defaults to 6. Suggest keeping at 6 as 8 can cause issues with applying
    
    .PARAMETER overrideOptions
    The options such as the default 'LayoutCustomizationRestrictionType="OnlySpecifiedGroups"' that makes it so only
    the groups in this layout can't be edited when applied via group policy. Other things can be pinned in custom groups
    
    .PARAMETER startFormat
    The startStr of the xml format for a later to string variable
    
    .PARAMETER endFormat
    The ending strings of the xml format
    
    .PARAMETER groups
    The custom object created by the function that is a list of start group psobjects from Get-StartGroup
    
    .EXAMPLE
    Create a new layout, export it to the default 'C:\startLayoutFromStartMenu.xml' and set it via gpo
    New-StartLayout -startMenuPath "$env:ALLUSERSPROFILE\Microsoft\Windows\Start Menu\Programs" | Export-StartLayoutXml | Set-StartLayout -gpo;
	
	.LINK
		https://github.com/FOGProject/fog-community-scripts/tree/master/PowershellModules/StartLayoutCreator
    
    #>
    [CmdletBinding()]
    param (
        [string]$startMenuPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs",
        [int32]$width = 6,
        $overrideOptions = 'LayoutCustomizationRestrictionType="OnlySpecifiedGroups"',
        $startFormat = @"
<LayoutModificationTemplate xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout" xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout" Version="1" xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification">
    <LayoutOptions StartTileGroupCellWidth="$width" />
    <DefaultLayoutOverride $overrideOptions>
         <StartLayoutCollection>
            <defaultlayout:StartLayout GroupCellWidth="$width">
"@,
        $endFormat = @"
            </defaultlayout:StartLayout>
        </StartLayoutCollection>
    </DefaultLayoutOverride>
</LayoutModificationTemplate>
"@,
        [System.Collections.Generic.List[PSCustomObject]]$groups
    )
    
    begin {
        $groups = New-Object System.Collections.Generic.List[PSCustomObject];
        Write-Verbose 'Creating Layout object...';
        $Layout = [PSCustomObject]@{
            width = $width
            overrideOptions = $overrideOptions
            groups = $groups
            startStr = $startFormat
            endStr = $endFormat
        }
    }
    
    process {
        # get start groups
        Write-Verbose "Searching $startMenuPath for start group folders..."
        # $i = 0;
        (Get-ChildItem -Path $startMenuPath).ForEach({
            # $i++;
            # Write-Progress -Activity "Creating layout object" -Status "$i of $($_.count)" -PercentComplete (($i / $_.Count)  * 100) -Id 1 -CurrentOperation 'searching for start group folders';
            if ($_.Attributes -match 'Directory') {
                if ($_.name -ne 'Startup') {
                    Write-Verbose "Getting start group from folder $($_.FullName)...";
                    $NextGroup = Get-StartGroup -pth $_.FullName -width $width;
                    if($NextGroup -ne $null) {
                        Write-Verbose 'changing group names for built in windows folders...';
                        switch ($NextGroup.name) {
                            Accessibility { $NextGroup.name = 'Windows Ease of Access' }
                            Accessories {$NextGroup.name = 'Windows Accessories' }
                        }
                        $Layout.groups.Add($NextGroup);
                    }
                    else {
                        Write-Verbose "$($_.name) is a empty folder, not adding";
                    }
                }
            }
        });
    }
    
    end {
        Write-Verbose "Layout object $($layout) created";
        return $Layout;
    }
}

function Export-StartLayoutXml {
    <#
    .SYNOPSIS
    A modified version of microsoft's Export-startlayout that uses a custom object made by New-StartLayout
    
    .DESCRIPTION
    A toString kind of function that creates a properly formatted start layout xml and utilizes the desktopapplicationID's or metro app ID's found
    when the object is creating using New-StartLayout.
    The formatting is done with a here-string to make it simple to see what it's doing and easy to edit later when microsoft ineveitably changes the format again
    
    .PARAMETER layout
    The custom ps object that can be passed in the pipeline. Is created by New-StartLayout
    
    .PARAMETER xmlFile
    The path and name of the exported xml, defaults to $xmlFile = 'C:\startLayoutFromStartMenu.xml'
    This path string is the return value of this function and can be passed through the pip to set-startlayout
    
    .EXAMPLE
    # export a new layout from the current user's start menu to the default location and set the layout to the default profile 
    Export-StartLayoutXml -layout $(New-StartLayout) | Set-StartLayout;
	
	.LINK
		https://github.com/FOGProject/fog-community-scripts/tree/master/PowershellModules/StartLayoutCreator
    
    #>
    [CmdletBinding()]
    param (
        [Parameter(
            Position = 0,
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)
        ]
        [PSCustomObject]$layout,
        
        [Parameter(
            Position = 1, 
            Mandatory = $false)
        ]
        [string]
        $xmlFile = 'C:\startLayoutFromStartMenu.xml'
    )
    
    begin {
        Write-Verbose 'exporting start layout xml from provided start menu...';
    }
    
    process {
        if ($layout -eq $null) {
            Write-Verbose 'no layout object provided, creating new one from current user start menu...';
            $layout = New-StartLayout;
        }
        Write-Verbose "Exporting $($layout) to $xmlFile";
        $cnt=1;
        $xml = 
@"
$($layout.startStr)
$($layout.groups | ForEach-Object {
"                <start:Group Name=`"$($_.Name)`">`n"
                    $($_.Folders | ForEach-Object {
"                   <start:Folder Size=`"$($_.Size)`" Column=`"$($_.Column)`" Row=`"$($_.Row)`">`n"
                        $($_.Tiles | ForEach-Object { "                       $(Get-TileString -Tile $_)"})
"                   </start:Folder>`n"})
                    $($_.Tiles | ForEach-Object {"                   $(Get-TileString -Tile $_)"})
"                 </start:Group>"  
$(if($cnt -lt $layout.groups.Count) { $cnt++; "`n" })})
$($layout.endStr)
"@
    }
    
    end {
        Out-File -FilePath $xmlFile -Encoding oem -InputObject $xml;
        Write-Verbose "Exported to xml file $xmlFile...";
        return $xmlFile;
    }
}

function Set-StartLayout {
    <#
    .SYNOPSIS
    Set the layout xml file as the start layout via default profile or local gpo
    
    .DESCRIPTION
    uses PolicyFileEntry module for gpos and import-startlayout for profile level
    
    .PARAMETER xmlFile
    The xmlfile to set
    
    .PARAMETER regPol
    the location of the machine pol group policies file, defaults to the default
    $regPol = 'C:\Windows\System32\GroupPolicy\Machine\Registry.pol',
    
    .PARAMETER winPol
    The path to the policy key containing the start layout policy, set as default
    $winPol = 'Software\Policies\Microsoft\Windows\Explorer',
    
    .PARAMETER gpt
    the path to the gpt.ini file to increment the version when updating local gpo
    $gpt = 'C:\WINDOWS\system32\grouppolicy\gpt.ini',
    
    .PARAMETER gpo
    switch param to set via local gpo, defaults to false
    
    .EXAMPLE
    #use import-startlayout
    Set-StartLayout -xmlFile C:\startLayout.xml
    #use local gpo
    Set-StartLayout -xmlFile C:\startLayout.xml -gpo
	
	.LINK
		https://github.com/FOGProject/fog-community-scripts/tree/master/PowershellModules/StartLayoutCreator
    
    #>
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)
        ]
        [string]
        $xmlFile,
        $regPol = 'C:\Windows\System32\GroupPolicy\User\Registry.pol',
        $winPol = 'Software\Policies\Microsoft\Windows\Explorer',
        $gpt = 'C:\WINDOWS\system32\grouppolicy\gpt.ini',
        [switch]$gpo
    )
    
    begin {
        Write-Verbose "Setting the start layout...";
        if ($gpo) { 
            Write-Verbose "GPO specified, installing PolicyFileEditor module...";
            if( (Get-PackageProvider Nuget) -eq $null) {
                Install-PackageProvider Nuget -Force -EA 0;
            }
            Install-Module PolicyFileEditor -Force -EA 0;
            Import-Module PolicyFileEditor -Global -Force;
        }
    }
    
    process {
        Write-Verbose "setting $xmlFile to be the computer's start layout";
        (Get-ChildItem $xmlFile).LastWriteTime = Get-Date;        
        
        Write-Verbose 'Importing startlayout to default profile for new users...';
        Set-Location -Path $env:SystemDrive\;
        Import-StartLayout -LayoutLiteralPath $xmlFile -MountLiteralPath $env:SystemDrive;
        
        if($gpo) {
            Write-Verbose 'setting start layout via user level group policy as well as in the default profile...';
            
            Write-Verbose 'Setting start layout xml policy...'
            # $xmlFile = 'C:\Users\Default\AppData\Local\Microsoft\Windows\Shell\LayoutModification.xml';
            Set-PolicyFileEntry $regPol -Key $winPol -ValueName StartLayoutFile -Data $xmlFile -Type ExpandString;
            Set-PolicyFileEntry $regPol -Key $winPol -ValueName LockedStartLayout -Data 1 -Type DWord;
            Update-GptIniVersion $gpt -PolicyType User;
            
            Write-Verbose 'updating layout xml time stamp in case this was just an update...';
            (Get-ChildItem $xmlFile).LastWriteTime = Get-Date; #update date time stamp on file

            Write-Verbose 'Creating self deleting startup script to restart explorer on first logon...';
            $startup = 'C:\Users\Default\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\restartExplorer.bat';
            $script = @"
@ECHO OFF
@powershell.exe -Command "(Get-Process explorer).Kill();"
del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\restartExplorer.bat" & exit
"@
            $script | Out-File -FilePath $startup -Force -Encoding oem;
        }
        # else {
        #     Write-Verbose 'Importing startlayout to default profile for new users...';
        #     Set-Location -Path $env:SystemDrive\;
        #     Import-StartLayout -LayoutLiteralPath $xmlFile -MountLiteralPath $env:SystemDrive;
        # }
    }
    
    end {
        Write-Verbose "$xmlFile set as start layout for all users on this computer";
        return $xmlFile;
    }
}

function Get-TileString {
    [CmdletBinding()]
    param (
        [PSCustomObject]$Tile,
        $type = $Tile.type,
        $Size = $Tile.Size,
        $col = $Tile.Column,
        $row = $Tile.Row,
        $id = $Tile.id,
        $idType
    )

    begin {
        if($type -eq 'start:Tile') {
            $idType = 'AppUserModelID';            
        }
        else {
            $idType = 'DesktopApplicationID';
        }
    }
    
    process {
        $tileStr ="<$type Size=`"$Size`" Column=`"$col`" Row=`"$row`" $idType=`"$id`" />`n";
    }
    
    end {
        return $tileStr;
    }
}

function Get-StartGroup {
    [CmdletBinding()]
    param (
        # start:DesktopApplicationTile Size="2x2" Column="4" Row="0" DesktopApplicationLinkPath
        $pth,
        [int32]$width = 6,
        $Tile = [PSCustomObject]@{
            type = 'start:DesktopApplicationTile'
            Size = '2x2'
            Column = 0
            Row = 0
            id = ''
        },
        $Folder = [PSCustomObject]@{
            Size = '2x2'
            Column = 0
            Row = 0
            Tiles = New-Object System.Collections.Generic.List[PSCustomObject]            
        },
        $group = [PSCustomObject]@{
            Name = Split-Path -Path $pth -Leaf
            Folders = New-Object System.Collections.Generic.List[PSCustomObject]
            Tiles = New-Object System.Collections.Generic.List[PSCustomObject]
        },
        $colCnt,
        $rowCnt
    )
    
    begin {
        $items = Get-ChildItem -Path $pth;
        $colCnt = 0;
        $rowCnt = 0;
    }
    
    process {
        Write-Verbose "Parsing the path $pth for shortcuts to go in the group $($group.Name)...";
        # $i=0;
        $items.ForEach({
            if ($_.Attributes -match 'Directory') {
                Write-Verbose "$_ is a directory, creating folder tile...";
                $group.Folders.Add($(Get-FolderTile -pth $_.FullName -col $colCnt -row $rowCnt));
                $cnts = Set-Counts -rowCnt $rowCnt -colCnt $colCnt -width $width; $rowCnt = $cnts.rows; $colCnt = $cnts.cols;                    
            }
            else {
                Write-Verbose "$_ is a link, creating normal tile...";
                $tile = Get-Tile -pth $_.FullName -col $colCnt -row $rowCnt;
                if($tile -ne $null) {
                    $group.Tiles.Add($tile);
                    $cnts = Set-Counts -rowCnt $rowCnt -colCnt $colCnt -width $width; $rowCnt = $cnts.rows; $colCnt = $cnts.cols;
                }
            }
            # $i++;
            # Write-Progress -Activity "Creating layout object" -Status "$i of $($_.count)" -Id 2 -ParentId 1 -CurrentOperation 'searching for tiles and folders' -PercentComplete (($i / $_.Count)  * 100);            
            
        });
    }
    
    end {
        Write-Verbose "Got group $($group.Name)";
        if ($group.Tiles.count -eq 0) {
            return $null;
        }
        else {
            return $group;
        }
    }
}

function Set-Counts {
    <#
    .SYNOPSIS
    increment row/col count

    .EXAMPLE
    $cnts = Set-Counts -rowCnt $rowCnt -colCnt $colCnt -width $width; $rowCnt = $cnts.rows; $colCnt = $cnts.cols;
    
    .NOTES
    May be a better way to pass references of variables and change them instead of this method.
    #>
    [CmdletBinding()]
    param (
        $rowCnt,
        $colCnt,
        $width
    )
        
    begin {
        $counts = [PSCustomObject]@{
            rows = $rowCnt
            cols = $colCnt
        };
    }
    
    process {
        Write-Verbose "incrementing row/col counters...";
        if (($counts.cols + 2) -lt $width) {
            $counts.cols += 2;
        }
        else {
            $counts.rows += 2;
            $counts.cols = 0;
        }
    }
    
    end {
        return $counts;
    }
}

function Get-Tile {
    [CmdletBinding()]
    param (
        $pth,
        $name,
        $col,
        $row,
        $size = '2x2',
        $Tile = [PSCustomObject]@{
            type = 'start:DesktopApplicationTile'
            Size = $size
            Column = $col
            Row = $row
            id = ''
        }
    )
    
    begin {
        $name = (Split-Path -Path $pth -Leaf).Replace('.lnk','');
        Write-Verbose "creating tile for $name...";
    }
    
    process {
        Write-Verbose "getting id...";
        $Tile.id = (Get-StartApps | Where-Object Name -eq $name).AppID;
        if ($Tile.id -match '!') {
            Write-Verbose 'Adding uwa tile change type...'
            $Tile.type = 'start:Tile';
            $Tile.id = $Tile.id.Where({ $_ -match '!'});        
        }
        Write-Verbose "tile id is $($Tile.id)";
    }
    
    end {
        Write-Verbose "Tile created for $name... $Tile"
        if ($Tile.id -eq $null -OR $Tile.id -eq "" -OR $Tile.id -match '!!') {
            Write-Verbose 'Tile has no id or invalid id, cannot be pinned, return null';
            return $null; 
        }
        return $Tile;
    }
}

function Get-FolderTile {
    [CmdletBinding()]
    param (
        $pth,
        $col,
        $row,
        $Tile = [PSCustomObject]@{
            type = 'start:DesktopApplicationTile'
            Size = '2x2'
            Column = 0
            Row = 0
            id = ''
        },
        $Folder = [PSCustomObject]@{
            Size = '2x2'
            Column = $col
            Row = $row
            Tiles = New-Object System.Collections.Generic.List[PSCustomObject]            
        },
        $colCnt,
        $rowCnt
    )
    
    begin {
        Write-Verbose "Creating start folder from $pth....";
        $items = Get-ChildItem -Path $pth -Recurse;
        $colCnt = 0;
        $rowCnt = 0;
    }
    
    process {
        Write-Verbose "Parsing $items for start folder...";
        $items.ForEach({       
            if ($_.Attributes -notmatch 'Directory') {
                Write-Debug "StartFolder tile is $($_.FullName)";
                $tile = Get-Tile -pth $_.FullName -col $colCnt -row $rowCnt;
                if($tile -ne $null){
                    $Folder.Tiles.Add($tile);
                    $cnts = Set-Counts -rowCnt $rowCnt -colCnt $colCnt -width $width; $rowCnt = $cnts.rows; $colCnt = $cnts.cols;
                }
            }
        });
    }
    
    end {
        Write-Verbose "Folder created, contents are $Folder";
        return $Folder
    }
}

Export-ModuleMember -Function *;
return;

# SIG # Begin signature block
# MIIQpgYJKoZIhvcNAQcCoIIQlzCCEJMCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUX3NkolblSt7EMZ6kKLxvVTij
# lkOggg0NMIIFiTCCA3GgAwIBAgIQN1osf+GqS6BH6tcXABgA1DANBgkqhkiG9w0B
# AQsFADBLMRMwEQYKCZImiZPyLGQBGRYDY29tMR8wHQYKCZImiZPyLGQBGRYPYXJy
# b3doZWFkZGVudGFsMRMwEQYDVQQDEwpBcnJvd1NlY0NhMB4XDTE3MDIwNzIxNTg1
# MFoXDTIyMDIwNzIyMDg0MlowSzETMBEGCgmSJomT8ixkARkWA2NvbTEfMB0GCgmS
# JomT8ixkARkWD2Fycm93aGVhZGRlbnRhbDETMBEGA1UEAxMKQXJyb3dTZWNDYTCC
# AiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAMhkMlfIR+4RxhLYnlPRHxIp
# NDa2/xRM1tlJM9EH+4+OuMO0EQMFZyYQOBCoJtsEgwGAPQ8sakSeYNE2Tjt4Tyou
# abr6kOHdY6OIQPEf5cIqoTi2unlQLWnC/2tx5MBXmKFZV2ZkPeZRghJwnHByZXFn
# bX31f+BRk3Bx+/PPW7h7oJTwufLo7uJAoRNJkKfTsgijyASiVqmkh5C0Vg5o5C9G
# gv9DAMarhcSa1+ShF+EtxKWM4m3/MloAhb/rNPZUCUuyjqFEDQV8PdBrQh56oBZL
# Q+If2pYoPPxxn8H+WPJfVTj9lkZG0IJe2ca6hmBa7dymYjQSUIBEQFC8tK2bE2er
# 1vj61rORZPoxargJXTaF0SV+Hq0frPBD4GkIOQWGKbuaCfIo6nVnrPZuQ7trEAvN
# 4S2mvzHvJ+nwX1CQhwcCsRW0GaLXxrfyeBsfZW67UgHcGK1tXV5h6+DR0bSPFPaa
# l3kI+8rf+9NVyDAZrCm2i0Lw4NW4cxL6JBKPQPKtFV3UouwWOac9MEoqibbpYVJ3
# rYcNyNeps1oekiVKN8jydfZ3AqKXQfLzqTJdB16YWbFYs5Yn1liiJfAWT7AaxfAE
# HJ67Oqr9IzGxGEM//IxqBJQeIf5/5CcMJH2UeksHZ3z3wR6VpkA/v/1rJEDfgKY/
# GJPDMv8GPbCDu3ElADbpAgMBAAGjaTBnMBMGCSsGAQQBgjcUAgQGHgQAQwBBMA4G
# A1UdDwEB/wQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBRRWTnftW/d
# bLIOrwmI+JciijhD5TAQBgkrBgEEAYI3FQEEAwIBADANBgkqhkiG9w0BAQsFAAOC
# AgEAw8bm2JLVfX4caZHQ52YZB5Td/6XAoznPTAmdycOTyvCmTyUjv9A8Ftc1OexN
# v2IPFRD7bL95Ms3mBfE2IBWpk/h5Mm/8ZN+6AuLXkc6200zhgbMnjvGb5s8YgSUM
# nPNHnyFBA1V+P66HBc5emJKLHY50aHyI+vk0udaMHYNrfMvlopvUzpMiumWSgp3M
# Y9GfiMmC2h3tjJ7E8JwNh+FSqUi63kZLqaK0B/mjtBG4DXaWLk5kSXxnntgX9oLs
# 3iX9U/I0rolonjt3UVOJeRPOGiRqcCH376lgkI/FRf4aFAKf3H6WHAqgbyx+vN2h
# e1uwbMQdX0gl3mok5aZoSI9znJbVIjBsZrjglvd3fXyPGbMUWCRVmOSlFwDO+zm1
# s8f5cFDtVnzMr8W+TOXd6+oxbplAMJ6XdKQPrvZTBBN55eB3WadXa/BdSXBxnBhn
# SwLq+o0H9W205eXFRZNCnH3KJlnsEIsMvLiNAw9/qVYo+2nU91x4lRrPa19DqmF2
# 5D/Eh0XkubjUa4b954jX+JpffObTyc5CvpL5gUODVlyMX0a40y74zubi7Zq9+xXj
# lOeOnOWpgDmWJD6iJbayIdyfZBlf/B9h3c9eFBWeCyFSuCpu8uBzmHUtem/JjF2t
# MTiJ4Cvmw1eNC8MqQrXDx3s1G5qpVNE3DWNzlCJs+QfHdJIwggd8MIIFZKADAgEC
# AhNdAAAATLgu1IttudRNAAAAAABMMA0GCSqGSIb3DQEBCwUAMEsxEzARBgoJkiaJ
# k/IsZAEZFgNjb20xHzAdBgoJkiaJk/IsZAEZFg9hcnJvd2hlYWRkZW50YWwxEzAR
# BgNVBAMTCkFycm93U2VjQ2EwHhcNMTgwNjAxMTY1OTA5WhcNMjAwNjAxMTcwOTA5
# WjBFMR0wGwYDVQQKExRBcnJvd2hlYWQgRGVudGFsIExhYjEkMCIGA1UEAxMbQXJy
# b3doZWFkIElUIFNjcmlwdCBNb25rZXlzMIICIjANBgkqhkiG9w0BAQEFAAOCAg8A
# MIICCgKCAgEAxwDOE86sYxKM8czHZg4dq/8Aj7U2S6WZRmOWW80ghFQms5n8GQVo
# tciKCij53oGVb6ckXLt3fWqJdyTth48oJl9Wa2+vbaq4s79W5szYS2HJdMzg9xh2
# u0F5E0XjpcHy0abU4IVTtYb/ert9GNyLJKkW8beh6+U2vlcl31A17rDVhg1Yl+tm
# xOwxwxNffWcR5HZCFUrIXDTIyMgkt4KFlP75+L9D7PXJVCk3TVmCNfWYKYsmJBtr
# XVKV6wb7Mm55uGbq6182zkrlhT0WHZmwEJejOgyz4g3rzevy37JE/sG723n4G2Jr
# 3kzLwveLbXX3NDoeMCYkYWeVGqfoC0FOP0WM7v7ogxRFlcWaV6UOFVirThTwEE0X
# se/Jw4y6vS2BgqC94rhiZk0HoGoFT8nIWVtUc5QpKC2kowkM8v13Yq8AGIWIBqBc
# nOdqlGSXoZc97lSLxmLaXYJR2a9SRjk65SJ/REO2Cdw/PNZ2zCv7YJFlp8d6c9zc
# UB2SxwQxA0jSyUST0p334m/QEXGSXFskOlbf+NM1CcUazmc6Q1jS7fqg40viw+Sf
# 5IyKkw9lsOXX7+FmcMhIWw91LFGboPEb7Iaf9vCulCCVMx9YhQOy3OKh8YJ9RcXC
# zGwchTQJ2/XQ66atF9rvrOgOtTzedHFmUlDrajyQ/fHGe+2hVGLxPLECAwEAAaOC
# Al0wggJZMDoGCSsGAQQBgjcVBwQtMCsGIysGAQQBgjcVCIebo3WFgvZBhYEMg66D
# aITGtVl41fZAiK1AAgFkAgEDMBMGA1UdJQQMMAoGCCsGAQUFBwMDMA4GA1UdDwEB
# /wQEAwIGwDAbBgkrBgEEAYI3FQoEDjAMMAoGCCsGAQUFBwMDMB0GA1UdDgQWBBRg
# qGvxaPgg3QnSqjNzfAdD3Zk5iTAfBgNVHSMEGDAWgBRRWTnftW/dbLIOrwmI+Jci
# ijhD5TCB0QYDVR0fBIHJMIHGMIHDoIHAoIG9hoG6bGRhcDovLy9DTj1BcnJvd1Nl
# Y0NhLENOPWFycm93c2VjLENOPUNEUCxDTj1QdWJsaWMlMjBLZXklMjBTZXJ2aWNl
# cyxDTj1TZXJ2aWNlcyxDTj1Db25maWd1cmF0aW9uLERDPWFycm93aGVhZGRlbnRh
# bCxEQz1jb20/Y2VydGlmaWNhdGVSZXZvY2F0aW9uTGlzdD9iYXNlP29iamVjdENs
# YXNzPWNSTERpc3RyaWJ1dGlvblBvaW50MIHEBggrBgEFBQcBAQSBtzCBtDCBsQYI
# KwYBBQUHMAKGgaRsZGFwOi8vL0NOPUFycm93U2VjQ2EsQ049QUlBLENOPVB1Ymxp
# YyUyMEtleSUyMFNlcnZpY2VzLENOPVNlcnZpY2VzLENOPUNvbmZpZ3VyYXRpb24s
# REM9YXJyb3doZWFkZGVudGFsLERDPWNvbT9jQUNlcnRpZmljYXRlP2Jhc2U/b2Jq
# ZWN0Q2xhc3M9Y2VydGlmaWNhdGlvbkF1dGhvcml0eTANBgkqhkiG9w0BAQsFAAOC
# AgEAlvrurKxXSVEi60zuh1FaHBCR+cMchAwZYm5/k4iVbGNUUeOGtBlZDLwSYuoM
# Hej3ENdqE0b3V/0BZ9KPD2WZhld7oTvRn0HjS97i35jI1XPVpBfktzbIBqZJfbQy
# 2aY/xdfcL4bVGIgVZdgZhCvFcM3H1gQLKB+3DcijggBC/S91AmRi3+cUX2M1fOUU
# 9hmlX6Ly7s8sMjAG2YndoyqPfmQScPTuiiNm3ARla3XgvgkbIClMKK8CH5NNTb24
# +nVrFDG6MLSH3QbKN8zVEzlj25Rgxwde9fx/2hAQ93P2wgRRjpM55BA/9oKN3xMn
# Qb4wO87UEjmcrAMJbnKxyRAgbpuwDW1BRuXUwmPQK4ft8aNJUe884wWq1fL1B+zR
# O8jc2xAkG7ctnCkzj3Pi0v3IZtfEzQiBNKF0cWX75cdB7siWQWaTmCkVMoRcDgCZ
# WHQ28UkDUR0hYr/jGsfgp3hVCCMtyHhl35EYeajzOe3LHfXKQxiwc42Telh6ZtUE
# DRndUfB8bpyt/9rcvU+S+YFcv/RXHtimPC1308OIYtPY+LRefNqz3gyr24uIAEcc
# xQjUHDsAttQC7O1nLws8USgVef6KT6LOEqGP5mxIXiXmH6ZRL6G/qaRIaJ5ku6e8
# BkRiqKzjzDgmGfbPDbcsQE37BS+Ms2oGIfLEUoJMuTVHLGoxggMDMIIC/wIBATBi
# MEsxEzARBgoJkiaJk/IsZAEZFgNjb20xHzAdBgoJkiaJk/IsZAEZFg9hcnJvd2hl
# YWRkZW50YWwxEzARBgNVBAMTCkFycm93U2VjQ2ECE10AAABMuC7Ui2251E0AAAAA
# AEwwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZI
# hvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcC
# ARUwIwYJKoZIhvcNAQkEMRYEFOyS9cPEtKNGLZ8ez1NVcVpJxUj8MA0GCSqGSIb3
# DQEBAQUABIICAEx4zLlfwYgSQnv41xCVVIbTZHbbzWkOz+KBqHeD4iNC1DbDRfZ1
# NmW+37w61y/Q3BiBnX5zQbEruaH0yzSXIodss+vWY1F1mjoyC1+mFj+YrNZCLt4+
# lDuar6NIRImhIzakYM9MXhmeUgRCWfYqEtBDjaB6F/9uaZv5KCueatn279qPRz3j
# 3jPs3iOM7dKHRWw33SpsjoLDaN3d7GhS+LAkQpIux4oyz2ATMsuwOGNAfaQqzh06
# TDOZaGVo3jh/Eq7fH6TXAc/e69P/ab4Xa9n+YpLhi9D/bZZXwYBaxZg4cxQvru0n
# 3XPhnzPGpSqvzEFeb2RdjXsJ9fD1W/ZH3jziUJ1/GGQ+r3JvtY0Jr4T18JjmLmwV
# Evh0nYu51Uc6JTxz6DijWeO/niDZTeOHaz/ngwaZAtwV7iVDAYTvPq0/1jIn5j4K
# uF9I1IuqsSqD9xKKUCoVNdlHarCfYzYVL1oxJhZRYNct8tkcOEY76OACUTRe/1g3
# VUFuyn9HGiS2fbdkxNzG10hhIuXuL3GPgdzGoebCLqMuNgW2j65Zed5FcBun1Cqo
# FMYlJBxaBkpTwr2MMrSC9exXGqh+aN4HLbJtVLei6x0tGmYlC/flDGCevzp9Gb3O
# x2BB5na6P1gld+Ts2LqJLNdOw9BJ/FzSnbWj5Gj7A5CskFp7m+kywgcn
# SIG # End signature block
