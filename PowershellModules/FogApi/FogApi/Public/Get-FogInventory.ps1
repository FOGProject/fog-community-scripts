function Get-FogInventory {
<#
    .SYNOPSIS
    Gets a local computer's inventory with wmi and returns 
    a json object that can be used to set fog inventory

    .DESCRIPTION
    Uses various wmi classes to get every possible inventory item to set in fog

    .PARAMETER hostObj
    the host to get the model of the inventory object from

#>

    [CmdletBinding()]
    param (
        $hostObj = (Get-FogHost)
    )

    begin {
        $comp = Get-WmiObject -Class Win32_ComputerSystem;
        $compSys = Get-WmiObject -Class Win32_ComputerSystemProduct;
        $cpu = Get-WmiObject -Class Win32_processor;
        $bios = Get-WmiObject -Class Win32_Bios;
        $hdd = Get-WmiObject -Class Win32_DiskDrive | Where-Object DeviceID -match '0'; #get just drive 0 in case of multiple drives
        $baseBoard = Get-WmiObject -Class Win32_BaseBoard;
        $case = Get-WmiObject -Class Win32_SystemEnclosure;
        $info = Get-ComputerInfo;
    }

    process {
        $hostObj.inventory.hostID        = $hostObj.id;
        # $hostObj.inventory.primaryUser   =
        # $hostObj.inventory.other1        =
        # $hostObj.inventory.other2        =
        $hostObj.inventory.createdTime   = $((get-date -format u).replace('Z',''));
        # $hostObj.inventory.deleteDate    = '0000-00-00 00:00:00'
        $hostObj.inventory.sysman        = $compSys.Vendor; #manufacturer
        $hostObj.inventory.sysproduct    = $compSys.Name; #model
        $hostObj.inventory.sysversion    = $compSys.Version;
        $hostObj.inventory.sysserial     = $compSys.IdentifyingNumber;
        if ($compSys.UUID -notmatch "12345678-9012-3456-7890-abcdefabcdef" ) {
            $hostObj.inventory.sysuuid       = $compSys.UUID;
        } else {
            $hostObj.inventory.sysuuid       = ($compSys.Qualifiers | Where-Object Name -match 'UUID' | Select-Object -ExpandProperty Value);
        }
        $hostObj.inventory.systype       = $case.chassistype; #device form factor found chassistype member of $case but it references a list that hasn't been updated anywhere I can find. i.e. returns 35 for a minipc but documented list only goes to 24
        $hostObj.inventory.biosversion   = $bios.name;
        $hostObj.inventory.biosvendor    = $bios.Manufacturer;
        $hostObj.inventory.biosdate      = $(get-date $info.BiosReleaseDate -Format d);
        $hostObj.inventory.mbman         = $baseBoard.Manufacturer;
        $hostObj.inventory.mbproductname = $baseBoard.Product;
        $hostObj.inventory.mbversion     = $baseBoard.Version;
        $hostObj.inventory.mbserial      = $baseBoard.SerialNumber;
        $hostObj.inventory.mbasset       = $baseBoard.Tag;
        $hostObj.inventory.cpuman        = $cpu.Manufacturer;
        $hostObj.inventory.cpuversion    = $cpu.Name;
        $hostObj.inventory.cpucurrent    = "Current Speed: $($cpu.currentClockSpeed) MHz";
        $hostObj.inventory.cpumax        = "Max Speed $($cpu.MaxClockSpeed) MHz";
        $hostObj.inventory.mem           = "MemTotal: $($comp.TotalPhysicalMemory) kB";
        $hostObj.inventory.hdmodel       = $hdd.Model;
        $hostObj.inventory.hdserial      = $hdd.SerialNumber;
        $hostObj.inventory.hdfirmware    = $hdd.FirmareRevision;
        $hostObj.inventory.caseman       = $case.Manufacturer;
        $hostObj.inventory.casever       = $case.Version;
        $hostObj.inventory.caseserial    = $case.SerialNumber;
        $hostObj.inventory.caseasset     = $case.SMBIOSAssetTag;
        $hostObj.inventory.memory        = "$([MATH]::Round($(($comp.TotalPhysicalMemory) / 1GB),2)) GiB";
    }

    end {
        $jsonData = $hostObj.inventory | ConvertTo-Json;
        return $jsonData;
    }

}
