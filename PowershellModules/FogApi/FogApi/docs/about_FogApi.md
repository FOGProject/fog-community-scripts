# FogApi

## about_FogApi

# SHORT DESCRIPTION
A module for managing FOG operations via powershell

# LONG DESCRIPTION

To install this module you need at least powershell v3, was created with 5.1 and intended to be cross platform compatible with powershell v6
To Install this module follow these steps
* Easiest method: Install from PSGallery https://www.powershellgallery.com/packages/FogApi `Install-Module -name fogApi` 

* Manual Method:
* download the zip of this repo https://github.com/FOGProject/fog-community-scripts/archive/master.zip and extract it
    * Or clone the repo using your favorite git tool, you just need the FogApi Folder this readme is in
* Copy the FogApi folder this Readme file is in to...
    * For Windows Powershell v3-v5.1
        * C:\Program Files\WindowsPowershell\Modules
    * For Windows Powershell v6+
        * C:\Program Files\PowerShell\6-preview\Modules
            * 6-Preview may need to be replaced with whatever current version you have installed
    * For Linux Powershell v6+
        * /opt/microsoft/powershell/6.1.0-preview.2/Modules
            * 6.1.0-preview.2 may need to be replaced with whatever current version you have installed
    * For Mac Powershell v6+ (untested)
        * /usr/local/microsoft/powershell/6.x/Modules
            * 6.x should be replaced with whatever most current version you are using
            * I haven't tested this on a mac, the module folder may be somewhere else
            this is based on where it is in other powershell 6 installs
* Open a powershell command prompt (I always run as admin, unsure if it's required)
* Run `Import-Module FogApi`

The module is now installed. 
The first time you try to run a command the settings.json file will automatically open
in notepad on windows, nano on linux, or TextEdit on Mac
You can also open the settings.json file and edit it manually before running your first command.
The default settings are explanations of where to find the proper settings since json can't have comments

Once the settings are set you can have a jolly good time utilzing the fog documentation 
found here https://news.fogproject.org/simplified-api-documentation/ that was used to model the parameters

i.e.

Get-FogObject has a type param that validates to object, objectactivetasktype, and search as those are the options given in the documentation.
Each of those types validates (which means autocompletion) to the core types listed in the documentation.
So if you typed in `Get-FogObject -Type object -Object  h` and then started hitting tab, it would loop through the possible core objects you can get from the api that start with 'h' such as history, host, etc.

Unless you filter a get with a json body it will return all the results into a powershell object. That object is easy to work with to create other commands. Note: Full Pipeline support will come at a later time 
 i.e.

 `$hosts = Get-FogObject -Type Object -CoreObject Host `# calls get on http://fog-server/fog/host to list all hosts
 Now you can search all your hosts for the one or ones you're looking for with powershell
 maybe you want to find all the hosts with 'IT' in the name  (note '?' is an alias for Where-Object)
`$ITHosts = $hosts.hosts | ? name -match 'IT';`

Now maybe you want to change the image all of these computers use to one named 'IT-Image'
You can edit the object in powershell with a foreach-object ('%' is an alias for foreach-object)
`$updatedITHosts = $ITHosts | % { $_.imagename = 'IT-image'}`

Then you need to convert that object to json and pass each object into one api call at a time. Which sounds complicated, but it's not, it's as easy as
```
$updateITHosts | % { 
    $jsonData = $_ | ConvertTo-Json;
    Update-FogObject -Type object -CoreObject host -objectID $_.id -jsonData $jsonData;
    #successful result of updated objects properties 
    #or any error messages will output to screen for each object
} 
```

This is just one small example of the limitless things you can do with the api and powershell objects.

see also the fogforum thread for the module https://forums.fogproject.org/topic/12026/powershell-api-module/2 
