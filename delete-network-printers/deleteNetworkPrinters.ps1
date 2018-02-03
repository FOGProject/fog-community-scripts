
Get-WmiObject -ComputerName localhost -Class Win32_printer | where { $_.portname -like '10.**' -or $_.portname -like '10.***' -and $_.local -eq 'TRUE'} | Select -ExpandProperty Name | ForEach-Object { rundll32 printui.dll,PrintUIEntry /dl /n "$_" } 

Remove-PrinterPort -Name "10.*"
