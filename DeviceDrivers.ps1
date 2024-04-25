param(
    [Parameter(Mandatory)]
    [string]$TargetPnpDeviceFriendlyName
)

Function Update-DeviceDrivers([string]$targetPnpDeviceInstanceId)
{
    $UpdateDeviceDriversSource = Get-Content -Raw -Path .\Source.cs
    Add-Type -TypeDefinition $UpdateDeviceDriversSource -Language CSharp
    [PsWinApiStuff.UpdateDrivers]::GetDeviceInformationSet($targetPnpDeviceInstanceId)
}

$PSDefaultParameterValues['*:Encoding'] = 'utf8'
$pnpDevice = Get-PnpDevice -FriendlyName $TargetPnpDeviceFriendlyName
Update-DeviceDrivers($pnpDevice.InstanceId)