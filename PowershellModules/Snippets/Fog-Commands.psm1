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