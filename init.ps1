
$expandAppAcrossMonitorsScriptPath = Join-Path -Path $PSScriptRoot -ChildPath 'ExpandWindowAcrossMonitors.Win+Shift+Up.ahk'

Install-BespokeFileLink -Path $expandAppAcrossMonitorsScriptPath `
                        -DestinationDirectory ([Environment]::GetFolderPath('Startup')) `
                        -Invoke
