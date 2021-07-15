
$Host.PrivateData.VerboseForegroundColor = [ConsoleColor]::DarkCyan
$Host.PrivateData.DebugForegroundColor = [ConsoleColor]::DarkGray

$InformationPreference = 'Continue'

$lastLocationFilePath = Split-Path -Parent -Path $profile
$lastLocationFileName = Split-Path -Leaf -Path $profile.CurrentUserCurrentHost
$lastLocationFilePath = Join-Path $lastLocationFilePath ('{0}-LastLocation.txt' -f $lastLocationFileName)


$gitInstalled = $true
if( -not (Get-Command -Name 'git' -ErrorAction Ignore) )
{
    $gitInstalled = $false
    $msg = 'Git isn''t installed or is not in your path. We can''t check for changes to your initialization scripts.'
    Write-Warning -Message $msg
}

if( $gitInstalled )
{
    if( (Get-Module -Name 'posh-git' -ListAvailable) )
    {
        Import-Module -Name 'posh-git'
    }
    else
    {
        Write-Warning -Message 'PoshGit PowerShell module isn''t installed. We can''t customize your prompt.'
    }
}

$isAdmin = $false

$identity = $null
$errCount = $Global:Error.Count
try
{
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
}
catch [PlatformNotSupportedException]
{
    for( $idx = 0; $idx -lt ($Global:Error.Count - $errCount); ++$idx )
    {
        $Global:Error.RemoveAt(0)
    }
}
 
if( $identity )
{             
    $hasElevatedPermissions = $false
    foreach ( $group in $identity.Groups )
    {
        if ( $group.IsValidTargetType([Security.Principal.SecurityIdentifier]) )
        {
            $groupSid = $group.Translate([Security.Principal.SecurityIdentifier])
            if ( $groupSid.IsWellKnown("AccountAdministratorSid") -or $groupSid.IsWellKnown("BuiltinAdministratorsSid"))
            {
                $isAdmin = $true
            }
        }
    }
}

$promptChar = '$'
if( $isAdmin )
{
    $promptChar = '#'
}

function prompt
{
    Set-StrictMode -Version 'Latest'

    $realLastExistCode = $global:LASTEXITCODE
    $errorsAtStart = $Global:Error.Count
    try
    {
    	# The at sign creates an array in case only one history item exists.
	    $history = @( get-history )
	    if($history.Count -gt 0)
	    {
		    $lastItem = $history[$history.Count - 1]
		    $lastId = $lastItem.Id
	    }

	    $nextCommand = $lastId + 1
	    $currentDirectory = Get-Location
        Get-Location | Select-Object -ExpandProperty Path | Out-File -FilePath $lastLocationFilePath -Encoding OEM

        if( (git rev-parse HEAD 2>$null) )
        {
            Write-VcsStatus
        }

        Write-Host ''
        Write-Host -NoNewline ' '
        Write-Host $nextCommand -NoNewline -ForegroundColor Gray
        Write-host ' ' -NoNewline
        Write-Host($pwd.ProviderPath) -nonewline -ForegroundColor DarkCyan
        Write-Host ' ' -NoNewline
        Write-Host $promptChar -NoNewline -ForegroundColor Gray
        return ' '
    }
    finally
    {
        for( $idx = $errorsAtStart; $idx -lt $Global:Error.Count; ++$idx )
        {
            $Global:Error.RemoveAt(0)
        }
        $global:LASTEXITCODE = $realLastExistCode
    }
}

function colors 
{
	$colors = @( "Black", "DarkBlue", "DarkGreen", "DarkCyan", "DarkRed", "DarkMagenta", "DarkYellow", "Gray", "DarkGray", "Blue", "Green", "Cyan", "Red", "Magenta", "Yellow", "White")
	foreach( $fgColor in $colors )
	{
		foreach( $bgColor in $colors )
		{
			write-host "$fgColor on $bgColor" -foregroundcolor $fgColor -backgroundcolor $bgColor
		}
		write-host
	}
}

function Invoke-SetLocation
{
    param(
        [Parameter(Mandatory=$true)]
        $Path
    )

    Push-Location
    Set-Location $Path
}

Set-Alias -Name cd -Value Invoke-SetLocation -Force -Option AllScope

function Set-FavoriteLocation
{
	param(
		[Parameter(Position=0,Mandatory=$true)]
		[string]
        # The name of the favorite to use.
		$Name
	)

    $favorites = @{ 
        'a' =   'C:\Build\Arc';
        'b' =   'C:\Build\Blade';
        'c' =   'C:\Build\Carbon';
        'cc' =  'C:\Build\CCNet';
		'cm' =  'C:\Build\CM'; 
        'g' =   'C:\Build\Geography';
        'p' =   'C:\Build\PHM';
        'ph' =  'C:\Build\PHM\HealthCoaching';
        'pi' =  'C:\Build\PHM\Integrations';
        'pa' =  'C:\Build\PHM\Arc';
        'pc' =  'C:\Build\PHM\Content';
		'pd' =  'C:\Build\ProviderDirectory';
		'pdc' = 'C:\Build\ProviderDirectory\CM';
        'pr' =  'C:\Build\PHMResources';
        'q' =   'C:\Build\WQS';
        'qc' =  'C:\Build\WQS\CM';
        'r' =   'C:\Build\Rivet';
        's' =   'C:\Build\Silk';
        't' =   'C:\Build\Pest';
    }
    
	if( -not $favorites.ContainsKey($Name) )
	{
		Write-Warning "Unknown favorite '$Name'."
	}
	else
	{
		Invoke-SetLocation $favorites[$Name]
	}
}
Set-Alias -Name cdw -Value cd
Set-Alias -Name cdf -Value Set-FavoriteLocation
Set-Alias -Name grep -Value Select-String


function Get-CSProj
{
	param(
		[Parameter(Position=0,Mandatory=$true)]
		[string[]]
		$Path
	)
	get-childitem $Path *.csproj -Recurse
}

function Start-JobHere
{
    param(
        [scriptblock]
        $ScriptBlock
    )
    $job = Start-Job -ArgumentList (Get-Location),$ScriptBlock { Set-Location $args[0]; Invoke-Expression $args[1] }
}

function Invoke-NotepadPlusPlus
{
	param(
		[string[]]
		$Path
	)
	
    Get-ChildItem -Path $Path |
	    ForEach-Object { & 'C:\Program Files\Notepad++\notepad++.exe' $_.FullName }
}
Set-Alias -Name npp -Value Invoke-NotepadPlusPlus 

function Enter-WhsPSSession
{
    param(
        $ComputerName,
        [Switch]
        $CredSsp
    )
    
    $optionalArgs = @{ }
    if( $CredSsp )
    {
        $optionalArgs.Authentication = 'Credssp'
    }
    Enter-PSSession -ComputerName $ComputerName -Authentication NegotiateWithImplicitCredential -UseSSL
}
Set-Alias -Name login -Value Enter-WhsPSSession

function grepps
{
    param(
        [string[]]
        $Path = (Resolve-Path .),
        
        [Parameter(Mandatory=$true,Position=0)]
        $Needle,
        
        [Switch]
        $SimpleMatch,

        [Switch]
        $NoArc,

        [Switch]
        $SkipBuildScripts,

        [Switch]
        $Edit,

        [int]
        $Context
    )

    Set-StrictMode -Version 'Latest'
    
    $selectStringArgs = @{ }
    if( $SimpleMatch )
    {
        $selectStringArgs.SimpleMatch = $true
    }

    $include = @( '*.ps*1*', '*.help.txt' )
    if( -not $SkipBuildScripts )
    {
        $include += @( '*.msbuild','*.targets','*.props','*.imports', '*.json', '*.yml' )
    }

    if( $Context )
    {
        $selectStringArgs['Context'] = $Context
    }

    Get-ChildItem -Path $path -Include $include -Recurse |
        Where-Object { $_.FullName -notlike '*\.hg\*' } |
        Where-Object { $_.FullName -notlike '*\.git\*' } |
        Where-Object { 
            if( $NoArc )
            {
                return ($_.FullName -notlike '*\Build\*\CM\*' -and $_.FullName -notlike '*\Build\*\Arc\*')
            }
            return $true
        } |
        Select-string $Needle @selectStringArgs |
        ForEach-Object {
            if( $Edit )
            {
                if( Test-Path -Path 'function:psedit' )
                {
                    psedit $_.Path
                }
                else
                {
                    ise $_.Path
                }
            }
            $_
        }
}

function grepcs
{
    param(
        $Path = (Resolve-Path .),
        
        [Parameter(Mandatory=$true,Position=0)]
        $Needle,
        
        [Switch]
        $SimpleMatch
    )
    
    $selectStringArgs = @{ }
    if( $SimpleMatch )
    {
        $selectStringArgs.SimpleMatch = $true
    }
    dir $path -Include *.cs,*.sql,*.prc,*.viw,*.aspx,*.ascx,*.config,*.config.*,*.udf  -Recurse | 
        Select-string $Needle @selectStringArgs
}

function Measure-Path
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [EnvironmentVariableTarget]$Target
    )

    Set-StrictMode -Version 'Latest'

    $systemPaths = 
        [Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::Machine) -split ';' |
        ForEach-Object { $_.TrimEnd('\', '/') }

    $extensionFilter = $env:PATHEXT -split ';' | ForEach-Object { "*$($_)" }
    $originalPaths = 
        [Environment]::GetEnvironmentVariable('Path', $Target) -split ';' |
        Where-Object { $_ } |
        ForEach-Object { 
            [pscustomobject]@{ 
                'Path' = $_.TrimEnd('\', '/');
                'State' = '';
            }
        }

    $seenPaths = @{}
    foreach( $path in $originalPaths )
    {
        $path.State = 'Ok'

        if( $Target -eq [EnvironmentVariableTarget]::User -and $systemPaths -contains $path.Path )
        {
            $path.State = 'In System Path'
            continue
        }

        if( $seenPaths.ContainsKey($path.Path) )
        {
            $path.State = 'Duplicate Path'
            continue
        }
        $seenPaths[$path.Path] = $true

        if( -not (Test-Path -Path $path.Path -PathType Container) )
        {
            $path.State = 'Not Found'
            continue
        }

        if( -not (Get-ChildItem -Path (Join-Path -Path $path.Path -ChildPath '*') -Include $extensionFilter) )
        {
            $path.State = 'No Executables'
            continue
        }
    }

    $originalPaths | Write-Output
}

function Set-Path
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Object]$InputObject,

        [Parameter(Mandatory)]
        [EnvironmentVariableTarget]$Target
    )

    begin
    {
        $paths = [Collections.ArrayList]::New()
    }

    process
    {
        $path = $InputObject.Path
        if( -not $path )
        {
            return
        }

        [void]$paths.Add($path)
    }

    end
    {
        $newPathValue = $paths -join ';'

        if( $newPathValue.Length -gt 1920 )
        {
            $msg = "New Path value is $('{0:#,###}' -f $newPathValue.Length) characters long. Paths longer than 1,920 " +
                'characters won''t be merged into a process''s Path variable (i.e., user Path variable will be ' +
                'missing).'
            Write-Warning -Message $msg

        }
        elseif( $newPathValue.Length -gt 2047 )
        {
            $msg = "New Path value is $('{0:#,###}' -f $newPathValue.Length) characters long. Paths longer than 2,047 " +
                'characters can''t be edited by the environment variable Windows UI and user Path variables won''t be ' +
                'merged into a process''s Path variable (i.e., user Path variable will be missing).'
            Write-Warning -Message $msg
        }

        if( $PSCmdlet.ShouldProcess("$($Target)-level ""Path"" environment variable", 'set') )
        {
            [Environment]::SetEnvironmentVariable('Path', $newPathValue, $Target)
        }
    }
}

if( (Test-Path -Path $lastLocationFilePath -PathType Leaf) )
{
    cd (Get-Content -Path $lastLocationFilePath -ReadCount 1)
}

function Enable-DebugOutput
{
    $Global:DebugPreference = 'Continue'
}

Set-Alias -Name 'edbg' -Value 'Enable-DebugOutput'

function Disable-DebugOutput
{
    $Global:DebugPreference = 'SilentlyContinue'
}

Set-Alias -Name 'ddbg' -Value 'Disable-DebugOutput'


function Enable-InformationOutput
{
    $Global:InformationPreference = 'Continue'
}

Set-Alias -Name 'ei' -Value 'Enable-InformationOutput'

function Disable-InformationOutput
{
    $Global:InformationPreference = 'SilentlyContinue'
}

Set-Alias -Name 'di' -Value 'Disable-InformationOutput'


function Enable-VerboseOutput
{
    $Global:VerbosePreference = 'Continue'
}

Set-Alias -Name 'ev' -Value 'Enable-VerboseOutput'

function Disable-VerboseOutput
{
    $Global:VerbosePreference = 'SilentlyContinue'
}

Set-Alias -Name 'dv' -Value 'Disable-VerboseOutput'

function wkitchen
{
    wsl 'kitchen' $args
}

function wknife
{
    wsl 'knife' $args
}

function wchef
{
    wsl 'chef' $args
}


$NodeServers = @(
                    'jsweb01x-whs-04.dev.webmd.com',
                    'jsweb02x-whs-04.dev.webmd.com',
                    'jsweb03x-whs-04.dev.webmd.com'
                )

$PhmDevBlueServers = @(
                        'aadm01d-whs-04.dev.webmd.com',
                        'aapp01d-whs-04.dev.webmd.com',
                        'acch01d-whs-04.dev.webmd.com',
                        'adi02d-whs-04.dev.webmd.com',
                        'autil01d-whs-04.dev.webmd.com',
                        'aweb01d-whs-04.dev.webmd.com',
                        'aweb02d-whs-04.dev.webmd.com'
                    )

$PhmDevGoldServers = @(
                        'cadm01d-whs-04.dev.webmd.com',
                        'capp01d-whs-04.dev.webmd.com',
                        'ccch01d-whs-04.dev.webmd.com',
                        'cdi02d-whs-04.dev.webmd.com',
                        'cutil01d-whs-04.dev.webmd.com',
                        'cweb01d-whs-04.dev.webmd.com',
                        'cweb02d-whs-04.dev.webmd.com'
                    )

$PhmTestServers = @(
                        'cadm01t-whs-04.dev.webmd.com',
                        'capp01t-whs-04.dev.webmd.com',
                        'ccch01t-whs-04.dev.webmd.com',
                        'cdi01t-whs-04.dev.webmd.com',
                        'cutil01t-whs-04.dev.webmd.com',
                        'cweb01t-whs-04.dev.webmd.com'
                    )
                    
$HaDevBlueServers = @(
    'aweb01d-wqs-04.dev.webmd.com'
)

$HaDevGoldServers = @(
    'cweb01d-wqs-04.dev.webmd.com'
)

$HaTestServers = @(
    'cweb01t-wqs.dev.webmd.com'
)

$DecoupledDevServers = @(
                            'awsvs01d-whs-04.dev.webmd.com',
                            'awsvs02d-whs-04.dev.webmd.com',
                            'awsvs03d-whs-04.dev.webmd.com',
                            'awsvs04d-whs-04.dev.webmd.com',
                            'awsvs05d-whs-04.dev.webmd.com',
                            'cwsvs01d-whs-04.dev.webmd.com',
                            'cwsvs02d-whs-04.dev.webmd.com',
                            'cwsvs03d-whs-04.dev.webmd.com',
                            'cwsvs04d-whs-04.dev.webmd.com'
                        )

$DecoupledTestServers = @(
                            'cwsvs01t-whs-04.dev.webmd.com',
                            'cwsvs02t-whs-04.dev.webmd.com'
                            'wsvs01t-whs-04.dev.webmd.com',
                            'wsvs02t-whs-04.dev.webmd.com',
                            'wsvs05t-whs-04.dev.webmd.com',
                            'wsvs06t-whs-04.dev.webmd.com'
                        )

$BuildServers = @(
                    'jenk01d-whs-04.dev.webmd.com',
                    'build01d-whs-04.dev.webmd.com',
                    'build03d-whs-04.dev.webmd.com',
                    'build04d-whs-04.dev.webmd.com',
                    'abld02d-whs-04.dev.webmd.com',
                    'pdx1dpltbld01.dev.webmd.com'
                )
$AllServers = $NodeServers + `
              $PhmDevBlueServers + `
              $PhmDevGoldServers + `
              $PhmTestGoldServers + `
              $DecoupledDevServers + `
              $DecoupledTestServers + `
              $HaDevBlueServers + `
              $HaDevGoldServers + `
              $HaTestServers + `
              $BuildServers

function Compare-GitUncommittedChange
{
    [CmdletBinding()]
    param(
        [switch]$Staged
    )

    Set-StrictMode -Version 'Latest'

    Start-Job -ScriptBlock { Set-Location $using:PWD ; git difftool -d } -Name "$($PWD)> git difftool -d" | Out-Null

    # Clean up old jobs.
    Get-Job -Name '*> git difftool -d' | Where-Object 'State' -In @( 'Completed' ) | Remove-Job -Force -ErrorAction Ignore
}

Set-Alias -Name 'difftool' -Value 'Compare-GitUncommittedChange'

if( (Get-Module -Name 'PersistentHistory' -ListAvailable -ErrorAction Ignore) )
{
    $MaximumHistoryCount = 1000
    Import-Module 'PersistentHistory'
}
else
{
    Write-Warning 'Command history will not be preserved: the PersistentHistory module is not installed.'
}

if( -not (Get-Command -Name 'which' -ErrorAction Ignore) )
{
    Set-Alias -Name 'which' -Value 'Get-Command'
}
