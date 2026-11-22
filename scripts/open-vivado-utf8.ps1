<#
.SYNOPSIS
Open the project with UTF-8 as the Java text editor's default encoding.
.DESCRIPTION
Vivado 2019.1 on Chinese Windows can read sources using the system code page.
Use this launcher when editing the project's UTF-8 sources in that version.
JAVA_TOOL_OPTIONS is set only for this invocation and restored afterwards.
.EXAMPLE
.\scripts\open-vivado-utf8.ps1
.EXAMPLE
.\scripts\open-vivado-utf8.ps1 -VivadoPath 'D:\Xilinx\Vivado\2019.1\bin\vivado.bat'
#>
[CmdletBinding()]
param(
    [string] $Project = (Join-Path $PSScriptRoot '..\OpenMIPS.xpr'),
    [string] $VivadoPath,
    [string[]] $VivadoArguments = @()
)

$ErrorActionPreference = 'Stop'
if (-not $VivadoPath) {
    $command = Get-Command vivado -ErrorAction SilentlyContinue
    if ($command) {
        $VivadoPath = $command.Source
    } elseif ($env:XILINX_VIVADO) {
        $VivadoPath = Join-Path $env:XILINX_VIVADO 'bin\vivado.bat'
    } elseif (Test-Path -LiteralPath 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat') {
        $VivadoPath = 'C:\Xilinx\Vivado\2019.1\bin\vivado.bat'
    } else {
        throw 'Vivado was not found. Specify -VivadoPath or run settings64.bat first.'
    }
}
if ($Project) {
    $Project = (Resolve-Path -LiteralPath $Project).Path
}

$previousOptions = $env:JAVA_TOOL_OPTIONS
try {
    $env:JAVA_TOOL_OPTIONS = "$previousOptions -Dfile.encoding=UTF-8".Trim()
    $launchArguments = @($VivadoArguments)
    if ($Project) { $launchArguments += $Project }
    & $VivadoPath @launchArguments
    if ($LASTEXITCODE -ne 0) { throw "Vivado exited with code $LASTEXITCODE." }
} finally {
    $env:JAVA_TOOL_OPTIONS = $previousOptions
}
