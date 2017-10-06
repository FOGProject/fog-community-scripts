<#
    -----------------------------------------------------------------------------
    Script Name: StartLayoutCreator
    Original Author: JJ Fullmer
    Created Date: 2017-10-04
    Version: 1.6
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
        Set-Location -Path $env:SystemDrive;
        Import-StartLayout -LayoutLiteralPath $xmlFile -MountLiteralPath $env:SystemDrive;
        
        if($gpo) {
            Write-Verbose 'setting start layout via user level group policy as well as in the default profile...';
            
            Write-Verbose 'Setting start layout xml policy...'
            Set-PolicyFileEntry $regPol -Key "$winPol" -ValueName StartLayoutFile -Data $xmlFile;
            Set-PolicyFileEntry $regPol -Key $winPol -ValueName LockedStartLayout -Data 1 -Type DWord;            
            Update-GptIniVersion $gpt -PolicyType Machine;
            
            Write-Verbose 'updating layout xml time stamp in case this was just an update...';
            (Get-ChildItem $xmlFile).LastWriteTime = Get-Date; #update date time stamp on file
        }
        # else {
            # Write-Verbose 'Importing startlayout to default profile for new users...';
            # Set-Location -Path 'C:\';
            # Import-StartLayout -LayoutLiteralPath $xmlFile -MountLiteralPath $env:SystemDrive;
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
# MIILfwYJKoZIhvcNAQcCoIILcDCCC2wCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUZhjt+Cu/z0876SFSKZjFyN+2
# +36gggfmMIIH4jCCBcqgAwIBAgITXQAAABVJ1Fje5/wFegAAAAAAFTANBgkqhkiG
# 9w0BAQsFADBLMRMwEQYKCZImiZPyLGQBGRYDY29tMR8wHQYKCZImiZPyLGQBGRYP
# YXJyb3doZWFkZGVudGFsMRMwEQYDVQQDEwpBcnJvd1NlY0NhMB4XDTE3MDIxMzE5
# MjA1MFoXDTE4MDIxMzE5MjA1MFowgacxEzARBgoJkiaJk/IsZAEZFgNjb20xHzAd
# BgoJkiaJk/IsZAEZFg9hcnJvd2hlYWRkZW50YWwxFjAUBgNVBAsMDU5ldHdvcmtf
# VXNlcnMxCzAJBgNVBAsTAklUMR8wHQYDVQQLExZPdGhlciBTcGVjaWFsIEFjY291
# bnRzMRowGAYDVQQLExFJVCBBZG1pbiBBY2NvdW50czENMAsGA1UEAxMESm1pbjCC
# AiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAMTCoDNP23H/JC7gWE7JezMZ
# vW8Ju+xYS1n7rdEEqc4+t0MKBjdMNTSqCoNlgIbO+dsIFFjlM2HmLmbDeDHDtekb
# DrK9QbeSdSqQHCLM99T+b0jrKr9zz1/GnfWlK3Vaozd+nHhLH8WZq/+esf2AIv5W
# lw8y08gomBxsogPWIXaQhYuimbDCz2g6mxYxZWCEJ2QR0YFwYeLd4d8t6woTq25U
# q4xmHGDBTVztmfZSSlaAoHdfJ3qYi+Qa7nuFraP+Y+aby4F3ZBdZ4BZuIcjQLIJj
# 6kIgtD/+P88BXKJWfYDXr0AVN010PhWUOeVhsT5dTOqxPLJ24W+dJ8c8sml4tqsQ
# lpsfbNdsMB1XrMUv22lRJu67p7LSKW6PdOQN8pyghawSWjobRSZ9iIoTPBid7I3Z
# M6pmmoSg6J+0HBP4myjIapP2wVeCiXvyT03tzxQCmskrMdOjksTwWVCxVqlRIMQH
# QU6Uc1tLLDHa5YwxmVXHgu51EEsIuze2JRhx5+ml0qA7wn8vnCGuobv7NNNHCAca
# a/7/2f3M1jG2/WQ/JhuJOl924xabXkb6LVnAXysBzvDlNELE+J59Q6zREtqjQKl2
# 4JmtIF8/QgEh8+10czMpaks7ILF9JQLYfoQFzlqtAEtFcl64x0leAODIK7yP4a43
# 6SbSpM1y5O+8NPS/6PoVAgMBAAGjggJgMIICXDAdBgNVHQ4EFgQUTh7DQLh9ahO8
# rtzC1RaURTzwqvUwHwYDVR0jBBgwFoAUUVk537Vv3WyyDq8JiPiXIoo4Q+UwgdEG
# A1UdHwSByTCBxjCBw6CBwKCBvYaBumxkYXA6Ly8vQ049QXJyb3dTZWNDYSxDTj1h
# cnJvd3NlYyxDTj1DRFAsQ049UHVibGljJTIwS2V5JTIwU2VydmljZXMsQ049U2Vy
# dmljZXMsQ049Q29uZmlndXJhdGlvbixEQz1hcnJvd2hlYWRkZW50YWwsREM9Y29t
# P2NlcnRpZmljYXRlUmV2b2NhdGlvbkxpc3Q/YmFzZT9vYmplY3RDbGFzcz1jUkxE
# aXN0cmlidXRpb25Qb2ludDCBxAYIKwYBBQUHAQEEgbcwgbQwgbEGCCsGAQUFBzAC
# hoGkbGRhcDovLy9DTj1BcnJvd1NlY0NhLENOPUFJQSxDTj1QdWJsaWMlMjBLZXkl
# MjBTZXJ2aWNlcyxDTj1TZXJ2aWNlcyxDTj1Db25maWd1cmF0aW9uLERDPWFycm93
# aGVhZGRlbnRhbCxEQz1jb20/Y0FDZXJ0aWZpY2F0ZT9iYXNlP29iamVjdENsYXNz
# PWNlcnRpZmljYXRpb25BdXRob3JpdHkwJQYJKwYBBAGCNxQCBBgeFgBDAG8AZABl
# AFMAaQBnAG4AaQBuAGcwDgYDVR0PAQH/BAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUF
# BwMDMDMGA1UdEQQsMCqgKAYKKwYBBAGCNxQCA6AaDBhqbWluQGFycm93aGVhZGRl
# bnRhbC5jb20wDQYJKoZIhvcNAQELBQADggIBACHxW3k5NPK2Kh0YbjV6gVUFmUMV
# OmHOg6AAV7DUuUSld7m5/TOsNWI9Jlv3KzMVKK0VPma0j6joC3nDqD+XlIFC6XV9
# UF4bAxlOqsa3jesluRSAdUxEH1aZ5F4aAfaMqMRa0y9t5tkJPaZroiK7VeBfhP1B
# 72GdZ1aqW8u1JTumjR+ePgOIUjvzzFkkuzViQ2pJqigDK3m0bXcWB2KGOKrJ1wGc
# dqXSj4PEhakueHpo+A2Chgvhn2vShPDVIpx+lZBhdYF/2b89FDqKIAgzvkq633MB
# IXJX4S1GBwMpjtBRXqE/jT47ErCfjrO1TFtevfTPbdDe/OP6kSFYsg0GT5Hhm2cr
# zd8evrvMQ/S9vEENaYWxrBns2aL39AO8vRPgycNR//9s9NMAtZi2hGdq5CW0GNxD
# Cz2IG8SSqD1d+cX7wC1O7J/nNcfSnKHr71HwVHLqHC8lj5MBKzAvzWg45h6meIvs
# Ih30ujO7hHl1MOi6symJ+j68SixyArI8Ao+fVNG6H2P4Tbdb722XOt7VYNPbqNjo
# CIrz0nyFiQBvOZxHL7cxQkRwc/RIhlvLS/Yq2EBBnYbh5KLUwd2LkSyNKQt0nqqr
# VQC6pkG++Tt3dg6t6gOe/c/eGhX4k3ZsVAoU+D+W5DrNJ52sahvf2VRYzXLJDMI5
# G5HF2BXWg/xZl6p/MYIDAzCCAv8CAQEwYjBLMRMwEQYKCZImiZPyLGQBGRYDY29t
# MR8wHQYKCZImiZPyLGQBGRYPYXJyb3doZWFkZGVudGFsMRMwEQYDVQQDEwpBcnJv
# d1NlY0NhAhNdAAAAFUnUWN7n/AV6AAAAAAAVMAkGBSsOAwIaBQCgeDAYBgorBgEE
# AYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwG
# CisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBRUqK05
# PG1EkqyU78ToQvu+s7DyLjANBgkqhkiG9w0BAQEFAASCAgBQRXC8aGsE9yYfC/qB
# +ufrlfHpVbGtXg5AYZSr1V4/JG2c5GTd1Te9dfh7rvjnNeJaHZMTf3xQnQfLqNty
# elccdA+RQ92LkQQPcqE40xEt4msXNsVYN7Xrmas1R7vV5maOxLBreq2UV8szlrKK
# WdQyAz/wyLoOY7fIjCGa4A2lhesvmEiV/AbmDJUMqKpf7H82sN2XecxQzC13HqXD
# gbiG8VUOJ80nZ6Gzzuh+b523ZUBBjIAAwyqFHBrxWcC5/77/yUc5D0QUknv78XnX
# scS5L8cFASRup8QxMIe30ADN4waE6yP6SKF+W3frRAKmY1oWqLyI+klTSD3pLkXX
# dEd5qW7hBObbSLDWQmtw7pqW6UzUhhwOKx+t/z4/ghPNnwJ63yGM2C8gXurIM1vg
# qVyDj3PKn890LA6BeI/j4NHjV1eFEiL6ppXimzfC/IJYRnehCXCX5Nx0fUJegPiS
# JxgYrqBVBEYaJ5LJjoF+H8CTCzSqbVoZ3C49ftr8Iqmv1L0QOVpMykcT8kl0Sk89
# 1+s+f4mFxHgd8BP7pGs0Y8IbT3Qi7tlTYc1JvmhbVkX6qtpbDyKbrdi/kf2lV76p
# NSLpyM+kWJGm6XQOhj/YWBeTvGKiOwnAI8YrTKOslmf3UwFW2L7lsGtiDz0CbWog
# TlodNabnCcEopssP/0lDKgDzUg==
# SIG # End signature block
