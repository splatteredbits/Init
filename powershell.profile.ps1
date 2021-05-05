
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
