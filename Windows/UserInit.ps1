# User Init Script for a Windows 10 machine.
# This assumes Chocolatey was installed with the following programs installed WITH CHOCOLATEY:
#
# * dotnetcore-sdk
# * vscode.install

# This can not be run with ADMIN, since this is user-level settings.
if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{    
    Write-Host "This script can NOT be run as ADMIN.";
    Exit -1;
}

###
# Functions
###
function WriteInfo( $line )
{
    Write-Host $line -ForegroundColor Green
    Write-Host "";
}

function WriteLine( $line )
{
    Write-Host $line;
    Write-Host "";
}

function ErrorWriteLine( $line )
{
    Write-Host $line -ForegroundColor Red
    Write-Host "";
}

function LaunchProcess( [string]$command, [string]$arguments )
{
    $startInfo = New-Object system.Diagnostics.ProcessStartInfo;
    $startInfo.UseShellExecute = $false;
    $startInfo.FileName = $command;
    $startInfo.CreateNoWindow = $true;
    $startInfo.RedirectStandardOutput = $true;
    $startInfo.RedirectStandardError = $true;

    Write-Host "#################";
    if( $args -eq "" )
    {
        Write-Host $command
    }
    else
    {
        $startInfo.Arguments = $arguments;
        Write-Host $command $arguments
    }

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo
    $process.Start() | Out-Null
    $process.WaitForExit() | Out-Null;

    $stdout = $process.StandardOutput.ReadToEnd()
    $stderr = $process.StandardError.ReadToEnd()

    if( -not ( $stdout -eq "") )
    {
        Write-Host "STDOUT:" 
        Write-Host $stdout
    }

    if( -not ( $stderr -eq "" ) )
    {
        Write-Host "STDERR:" 
        Write-Host $stderr
    }

    $exitCode = $process.ExitCode
    if( $exitCode -eq 0 )
    {
        # Do nothing.
    }
    else
    {
        ErrorWriteLine("Error when launching $command $arguments (got exit code: $exitCode)")
    }

    Write-Host "#################";

    return $exitCode
}

###
# Configure dotnet sdk
###

# First, opt-out of telemetry
WriteInfo( "Opting out of DOTNET CLI Telemetry" );
[System.Environment]::SetEnvironmentVariable('DOTNET_CLI_TELEMETRY_OPTOUT', 'true', [System.EnvironmentVariableTarget]::User);

# Next, install the format tools.
WriteInfo( "Installing Dotnet format tools to user." );
LaunchProcess -command "C:\Program Files\dotnet\dotnet.exe" -arguments "tool install -g dotnet-format" | Out-Null;
LaunchProcess -command "C:\Program Files\dotnet\dotnet.exe" -arguments "format --version" | Out-Null;

###
# Edit Folder Options
###
# HKCU == Current User.
WriteInfo( "Enabling Show Hidden Files");
Set-ItemProperty -path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name "Hidden" -Value "1"

WriteInfo( "Enabling Show File Extensions");
Set-ItemProperty -path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name "HideFileExt" -Value "0"

WriteInfo( "Enabling Checkboxes in Explorer");
Set-ItemProperty -path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name "AutoCheckSelect" -Value "1"

###
# Download VS code extensions
###
$codeLocation = "C:\Program Files\Microsoft VS Code\bin\code.cmd";

WriteInfo( "Checking to see if VS Code is installed." );
$codeExitCode = LaunchProcess -command $codeLocation -arguments "--version"
if ( $codeExitCode -eq 0)
{
    WriteInfo( "Installing C# VSCode addon" );
    LaunchProcess -command $codeLocation -arguments "--install-extension ms-vscode.csharp" | Out-Null

    WriteInfo( "Installing Powershell VSCode addon" );
    LaunchProcess -command $codeLocation -arguments "--install-extension ms-vscode.powershell" | Out-Null

    WriteInfo( "Installing C++ VSCode addon" );
    LaunchProcess -command $codeLocation -arguments "--install-extension ms-vscode.cpptools" | Out-Null

    WriteInfo( "Installing Python VSCode addon" );
    LaunchProcess -command $codeLocation -arguments "--install-extension ms-python.python" | Out-Null

    WriteInfo( "Installing Cake VSCode addon" );
    LaunchProcess -command $codeLocation -arguments "--install-extension cake-build.cake-vscode" | Out-Null
}
else
{
    ErrorWriteLine( "VSCode not installed, skipping plugin install.");
}
