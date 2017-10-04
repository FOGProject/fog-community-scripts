* Installation
    * Download this folder as a zip, then unzip it.
    * Copy the contents to a new folder located at C:\Program Files\WindowsPowerShell\Modules\StartLayoutCreator
    * Open powershell and run 'Import-Module StartLayoutCreator'

* Notes
    * Setting the start layout to local gpo requires another module that the module will attempt to install. It's called policyfileeditor and is found here https://www.powershellgallery.com/packages/PolicyFileEditor/3.0.0 and here https://github.com/dlwyatt/PolicyFileEditor
    * A few links on windows 10 start screen customization used while designing this
        * https://docs.microsoft.com/en-us/windows/configuration/customize-windows-10-start-screens-by-using-group-policy
        * https://docs.microsoft.com/en-us/windows/configuration/customize-and-export-start-layout
        * https://docs.microsoft.com/en-us/windows/configuration/start-layout-xml-desktop
        * https://docs.microsoft.com/en-us/powershell/module/startlayout/import-startlayout?view=win10-ps
        * https://docs.microsoft.com/en-us/powershell/module/startlayout/get-startapps?view=win10-ps
    * I intend to add getting taskbar pins to add to the layout as well as setting a given string of programs to pin in the layout for a more dynamic approach.

* Description
    * There are 3 main functions for creating, exporting, and setting a new startlayout from a legacy startmenu. (i.e. the place where all the programs you install automatically add a shortcut and where you probably put shortcuts if you make silent installers for provisioning "%APPDATA%\Microsoft\Windows\Start Menu\Programs" is the default of the current user)
    * New-StartLayout
        * Creates a custom ps object from a start menu path
    * Export-StartLayoutXml
        * Creates a string of the layoutxml format and exports it to a xmlfile
    * Set-StartLayout
        * Sets the created layout xml file

* You can see the following help info in powershell with 'help function-name'...

* New-StartLayout
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
    
* Export-StartLayoutXml
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

* Set-StartLayout
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