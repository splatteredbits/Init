
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
