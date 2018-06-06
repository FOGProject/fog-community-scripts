function Invoke-FogApi {
    <#
        .SYNOPSIS
           a cmdlet function for making fogAPI calls via powershell
        
        .DESCRIPTION
            takes a few parameters with a default that will get all hosts
            Makes a call to the api of a fog server and returns the results of the call
            The returned value is an object that can then be easily filtered, processed, and otherwise manipulated in poweshell.
            i.e. you could take the return value of the default all hosts and run 
                $(invoke-fogapi).hosts | where name -match "$(hostname)"
            to get the host information for the current computer
        
        .PARAMETER fogApiToken
            a string of your fogApiToken gotten from the fog web ui. Can be set in the function as a default or passed to the function
        
        .PARAMETER fogUserToken
           a string of your fog user token gotten from the fog web ui in the user section. Can be set in the function as a default or passed to the function
        
        .PARAMETER fogServer
            The hostname or ip address of your fogserver, defaults to the default fog-server
        
        .PARAMETER uriPath
            Put in the path of the apicall that would follow http://fog-server/fog/
            i.e. 'host/1234' would access the host with an id of 1234
            
        .PARAMETER Method
          Defaults to 'Get' can also be 
        
        .PARAMETER jsonData
            The jsondata string for including data in the body of a request
        
        .EXAMPLE
            #if you had the api tokens set as default values and wanted to get all hosts and info you could run this, assuming your fogserver is accessible on http://fog-server
            Invoke-FogApi;

        .Example
            #if your fogserver was named rawr and you wanted to put rename host 123 to meow
            Invoke-FogApi -fogServer "rawr" -uriPath "host/123" -Method "Put" -jsonData "{ `"name`": meow }";

        .Link
            https://news.fogproject.org/simplified-api-documentation/
        
        .NOTES
            The online version of this help takes you to the fog project api help page
            
    #>

    [CmdletBinding()]
    param (
        [string]$fogApiToken = '',
        [string]$fogUserToken = '',
        [string]$fogServer = "fog-server",
        [string]$uriPath = "host", #default to get all hosts
        [string]$Method = "Get",
        [string]$jsonData #default to empty
    )
    
    begin {
        # Create headers
        Write-Verbose "Building Headers...";
        $headers = @{};
        $headers.Add('fog-api-token', $fogApiToken);
        $headers.Add('fog-user-token', $fogUserToken);

        # Set the baseUri
        Write-Verbose "Building api call URI...";
        $baseUri = "http://$fogServer/fog";
        $uri = "$baseUri/$uriPath";
    }
    
    process {

        Write-Verbose "$Method`ing $jsonData to/from $uri";
        if ($Method -eq "Get") {
            $result = Invoke-RestMethod -Uri $uri -Method $Method -Headers $headers -ContentType "application/json";            
        }
        else {
            $result = Invoke-RestMethod -Uri $uri -Method $Method -Headers $headers -Body $jsonData -ContentType "application/json";
        }
    }
    
    end {
        Write-Verbose "finished api call";
        return $result;
    }
}
function Get-FogGroup {
    <#
    .SYNOPSIS
    needs to return the group name of the group that isn't the everyone group
    will use groupassociation call to get group id then group id to get group name from group uriPath
    
    .DESCRIPTION
    requires the id of the host you want the groups that aren't the everyone group for
    #>
    [CmdletBinding()]
    param (
        [int]$hostId
    )
    
    begin {
        [bool]$found = $false;
        Write-Verbose 'Getting all fog group associations...';
        $groupAssocs = (Invoke-FogApi -uriPath groupassociation).groupassociations;
        Write-Verbose 'Getting all fog groups...';
        $groups = (Invoke-FogApi -uriPath group).groups;
    }
    
    process {
        Write-Verbose "Finding group association for hostid of $hostId";
        $hostGroups = $groupAssocs | Where-Object hostID -eq $hostId;
        Write-Verbose "filtering out everyone group";
        $hostGroups = $hostGroups | Where-Object groupID -ne 3; #groupID 3 is the everyone group, don't include that
        Write-Verbose "finding group that matches group id of $hostGroups...";
        $group = $groups | Where-Object id -eq $hostGroups.groupID;
        Write-Verbose 'checking if group was found...';
        if($group -ne $null -AND $group -ne "") { $found = $true; Write-Verbose 'group found!'}
    }
    
    end {
        if($found){
            return $group;
        }
        return $found;
    }
}

function Get-FogHost {
    <#
    .SYNOPSIS
    Short description
    
    .DESCRIPTION
    Long description
    
    .PARAMETER uuid
    Parameter description
    
    .PARAMETER hostName
    Parameter description
    
    .PARAMETER macAddr
    Parameter description
    
    .EXAMPLE
    An example
    
    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param (
        [string]$uuid,
        [string]$hostName,
        [string]$macAddr
    )
    
    begin {
        [bool]$found = $false;
        Write-Verbose 'Checking for passed variables'
        if (!$uuid -and !$hostName -and !$macAddr) {
            Write-Verbose 'no params given, getting current computer variables';
            $uuid = (Get-WmiObject Win32_ComputerSystemProduct).UUID;
            $macAddr = ((Get-NetAdapter | Select-Object MacAddress)[0].MacAddress).Replace('-',':');
            $hostName = $(hostname);
        }
        Write-Verbose 'getting all hosts to search...';
        $hosts = (Invoke-FogApi).hosts;
        Write-Verbose "search terms: uuid is $uuid, macAddr is $macAddr, hostname is $hostName";
    }
    
    process {
        Write-Verbose 'finding host in hosts';
        $hostObj = $hosts | Where-Object {
            ($uuid -ne "" -AND $_.inventory.sysuuid -eq $uuid) -OR `
            ($hostName -ne "" -AND $_.name -match $hostName) -OR `
            ($macAddr -ne "" -AND $_.macs -contains $macAddr);
            if  ($uuid -ne "" -AND $_.inventory.sysuuid -eq $uuid) {
                 Write-Verbose "$($_.inventory.sysuuid) matches the uuid $uuid`! host found"; 
                 $found = $true;
            }
            if  ($hostName -ne "" -AND $_.name -match $hostName) {
                Write-Verbose "$($_.name) matches the hostname $hostName`! host found"; 
                $found = $true;
            }
            if ($macAddr -ne "" -AND $_.macs -contains $macAddr) {
                Write-Verbose "$($_.macs) matches the macaddress $macAddr`! host found";
                $found = $true;
            }
        }

    }
    
    end {
        if ($found){
            return $hostObj;
        }
        return $found; #return false if host not found
    }
}

function Remove-UsbMac {
    <#
        .SYNOPSIS
            A cmdlet that uses invoke-fogapi to remove a given list of usb mac address from a host
        
        .DESCRIPTION
            When a wireless device is imaged with a usb ethernet adapter, it should be removed when it's done
        
        .PARAMETER fogServer
            passed to calls of invoke-fogapi within this function see help invoke-fogapi -parameter fogserver
        
        .PARAMETER usbMacs
            a string of mac addresses like this @("01:23:45:67:89:10", "00:00:00:00:00:00")
        
        .PARAMETER fogApiToken
            the apitoken for invoke-fogapi calls
        
        .PARAMETER fogUserToken
            the user api token for invoke-fogapi calls
        
        .PARAMETER hostname
            the hostname to remove the usb macs from, defaults to current hostname
        
        .EXAMPLE
            Remove-UsbMacs -fogServer "foggy" -usbMacs @("01:23:45:67:89:10", "00:00:00:00:00:00")
            
        .Link
            https://forums.fogproject.org/topic/10837/usb-ethernet-adapter-mac-s-for-imaging-multiple-hosts-universal-imaging-nics-wired-nic-for-all-wireless-devices/14
        
        .NOTES
            online version of help goes to fog forum post where the idea was conceived
    #>
    [CmdletBinding()]
    param (
        [string]$fogServer = "fog-server",
        [string[]]$usbMacs = @("00:00:00:00:00:00","00:00:00:00:00:01"), #default usb mac list, can be overridden
        [string]$fogApiToken = '',
        [string]$fogUserToken = '',
        [string]$hostname = "$(hostname)",
        $macId #initialize
    )
    
    begin {
        Write-Verbose "remove usb ethernet adapter from host $hostname on fog server $fogServer ....";
        # get the host id by getting all hosts and searching the hosts array of the returned json for the item that has a name matching the current hostname and get the host id of that item
        $hostId = ( (Invoke-FogApi -fogServer $fogServer -fogApiToken $fogApiToken -fogUserToken $fogUserToken).hosts | Where-Object name -match "$hostname" ).id;
        # With the host id get mac associations that match that host id.
        $macs = (Invoke-FogApi -fogServer $fogServer -fogApiToken $fogApiToken -fogUserToken $fogUserToken -uriPath "macaddressassociation").macaddressassociations |
            Where-Object hostID -match "$hostId"; 

        # Copy the return fixedsize json array collection to a new powershell list variable for add and remove functions
        $macList = New-Object System.Collections.Generic.List[System.Object];
        $macs.ForEach({ $macList.add($_.mac); });
        $result = "no usb adapters found"; #replace string if found
    }
    
    process {
        # Check if any usbmacs are contained in the host's macs
        $usbMacs | ForEach-Object { #loop through list of usbMacs
            if ( $macList.contains($_) ) { # check if the usbMac is contained in the mac list of the host
                # Remove from the list so a new primary can be picked if needed
                $macList.Remove($_);
                
                Write-Verbose "$_ is a $usbMac connected to $hostname, checking if it is the primary...";
                $macItem = ($macs | Where-Object mac -eq $_ );
                
                if ( $macItem.primary -eq 1 ) {
                    Write-Verbose "It is primary, let's fix that and set $($macList[0]) to primary";
                    $macItem.primary = 0; 
                    Invoke-FogApi -fogApiToken $fogApiToken -fogUserToken $fogUserToken `
                        -fogServer $fogServer -jsonData ($macItem | ConvertTo-Json) -Method "Put" `
                        -uriPath "macaddressassociation/$($macItem.id)/edit" -Verbose;
                    
                    Write-Verbose "Primary attribute removed, setting new primary...";
                    $newPrimary = ($macs | Where-Object mac -eq $macList[0] );
                    $newPrimary.primary = 1;
                    Invoke-FogApi -fogApiToken $fogApiToken -fogUserToken $fogUserToken `
                    -fogServer $fogServer -jsonData ($newPrimary | ConvertTo-Json) -Method "Put" `
                    -uriPath "macaddressassociation/$($newPrimary.id)/edit" -Verbose;
                }

                Write-Verbose "Remove the usb ethernet mac association";
                $result = Invoke-FogApi -fogApiToken $fogApiToken -fogUserToken $fogUserToken `
                    -fogServer $fogServer -uriPath "macaddressassociation/$($macItem.id)/delete" `
                    -Method "Delete" -Verbose;
                
                Write-Verbose "Usb macs $usbMacs have been removed from $hostname on the $fogServer";
            }
        }
    }
    
    end {
        return $result;
    }
}

Export-ModuleMember -Function *;
# download this file, copy it to a new folder you make in  C:\Program Files\WindowsPowerShell\Modules i.e C:\Program Files\WindowsPowerShell\Modules\Fog-Commands
# then in a powershell prompt you can run import-module Fog-Commands; You can also just run ipmo 'download\path\Fog-Commands.psm1'; but that's more keystrokes each time...
# SIG # Begin signature block
# MIIQpgYJKoZIhvcNAQcCoIIQlzCCEJMCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUX3d+e4dYcTwXNcaTdpMcxUMJ
# 4RSggg0NMIIFiTCCA3GgAwIBAgIQN1osf+GqS6BH6tcXABgA1DANBgkqhkiG9w0B
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
# ARUwIwYJKoZIhvcNAQkEMRYEFFZ11Uc0vBUFkagcpvXw+kasea62MA0GCSqGSIb3
# DQEBAQUABIICAIrqF1TbEIwxnYQGhaq8mejM3Ei2O0p49cWE2aM7ujC3Pr2H2kWG
# RMWkq2tQcCuWhrOuy64j43ZU+E+3KFQ1Omp4hQTzdldW1L0VHjYqX7+DPV0df+1F
# DUJ9UOVVIezhHnhQdD5+/fOlFQAZbFrl7mKu8od0m9kG2nFO420JIZsWvJrkLwgk
# NUG9CY9hr2RTDhaeXrEta6HSQt0dKBt/TMJ7nx+c4h5r2O6s0jALscs7MIdQp8Dc
# fcGa8htBCR8FlW/czMPYdJVSBy+J00CieNVoT5lfBsPMi1MuFxmma7HnZCx3e3Ly
# v2c+2QZITc+oyRuABGqizZ/RdMBz0i2yjfudW7N5/w92OE2MWN00Ie9InPFFIH26
# Yaw0/Q0qxqpWKC6SFBn2WD25fvf+DNVs/sd+C9a+74JW0blKU2rr9qRXq5e4e4+i
# 6FLPu+NVuhgQymYbjZvI0588PuzFv6r8qs1tCAFCHJTt5Lhgvx42uFTHBaEH/wBV
# T6ZIA0k+si8fojMOq6BDf7vLX6BpyPQm3i8C4r8cE/zdf7+UJYNKLU/W4+rA7m1Y
# GGqwhwqtWliuyl7B0l23V68hUQjR/z+IbxG7pNpbvPWbb6EC3p/xGLl3GlG70zuv
# ONZrsbeTI91V6Yc4LIZ6IE+BNewlnPg595SY9u50oKnFwSq7uFRKtW7G
# SIG # End signature block
