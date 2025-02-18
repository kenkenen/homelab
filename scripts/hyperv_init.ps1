# Define the names for the switches and VM
$externalSwitchName = "ExternalSwitch"
$privateSwitchName = "PrivateSwitch"
$vmName = "proxmoxve"
$isoPath = "$HOME\Downloads\proxmox-ve_8.3-1.iso"
$vmMemory = 4096MB
$vmDiskSize = 64GB
$vmVhdPath = "C:\ProgramData\Microsoft\Windows\Virtual Hard Disks\$vmName.vhdx"

# Delete existing VM if it exists
if (Get-VM -Name $vmName -ErrorAction SilentlyContinue) {
    if ((Get-VM -Name $vmName).State -eq 'Running') {
        Stop-VM -Name $vmName -Force -TurnOff
    }
    Remove-VM -Name $vmName -Force
    Write-Output "Existing VM '$vmName' deleted."
}

# Delete existing external switch if it exists
if (Get-VMSwitch -Name $externalSwitchName -ErrorAction SilentlyContinue) {
    Remove-VMSwitch -Name $externalSwitchName -Force
    Write-Output "Existing external switch '$externalSwitchName' deleted."
}

# Delete existing private switch if it exists
if (Get-VMSwitch -Name $privateSwitchName -ErrorAction SilentlyContinue) {
    Remove-VMSwitch -Name $privateSwitchName -Force
    Write-Output "Existing private switch '$privateSwitchName' deleted."
}

# Delete existing virtual hard disk if it exists
if (Test-Path $vmVhdPath) {
    Remove-Item -Path $vmVhdPath -Force
    Write-Output "Existing virtual hard disk '$vmVhdPath' deleted."
}

# Create the external switch
# Get the network adapter that is connected to the internet
$externalAdapter = Get-NetAdapter | Where-Object { 
    $_.Status -eq "Up" -and 
    ($_.MediaType -eq "802.3" -or $_.MediaType -eq "Native 802.11") -and 
    $_.Name -notlike "v*" -and 
    $_.Name -notlike "*Bridge*" -and
    $_.InterfaceDescription -notlike "*Virtual*"
} | Select-Object -First 1

if ($externalAdapter) {
    New-VMSwitch -Name $externalSwitchName -NetAdapterName $externalAdapter.Name -AllowManagementOS $true
    Write-Output "External switch '$externalSwitchName' created successfully using adapter '$($externalAdapter.Name)'."
} else {
    Write-Output "No active network adapter found for creating the external switch."
}

# Create the private switch
New-VMSwitch -Name $privateSwitchName -SwitchType private
Write-Output "Private switch '$privateSwitchName' created successfully."

# Create the VM
New-VM -Name $vmName -MemoryStartupBytes $vmMemory -BootDevice CD -Generation 2 -NoVHD

# Remove Default Network Adapter
Remove-VMNetworkAdapter -VMName "proxmoxve" -Name "Network Adapter"

# Disable secure boot
Set-VMFirmware -VMName $vmName -EnableSecureBoot Off

# Add a virtual hard disk
Add-VMHardDiskDrive -VMName $vmName -Path (New-VHD -Path $vmVhdPath -SizeBytes $vmDiskSize -Dynamic).Path

# Add network adapters
$externalAdapter1 = Add-VMNetworkAdapter -VMName $vmName -SwitchName $externalSwitchName -Name "External Adapter 1"
$externalAdapter2 = Add-VMNetworkAdapter -VMName $vmName -SwitchName $externalSwitchName -Name "External Adapter 2"
$privateAdapter = Add-VMNetworkAdapter -VMName $vmName -SwitchName $privateSwitchName -Name "Private Adapter"

# Enable MAC address spoofing for all network adapters
Set-VMNetworkAdapter -VMName $vmName -Name "Network Adapter" -MacAddressSpoofing On
Set-VMNetworkAdapter -VMName $vmName -Name "External Adapter 2" -MacAddressSpoofing On
Set-VMNetworkAdapter -VMName $vmName -Name "Private Adapter" -MacAddressSpoofing On

# Expose Virtualization Extensions
Set-VMProcessor -VMName "$vmName" -ExposeVirtualizationExtensions $true

# Set the ISO file as the DVD drive
Set-VMDvdDrive -VMName $vmName -Path $isoPath

# Power on the VM
Start-VM -Name $vmName

Write-Output "VM '$vmName' created and powered on successfully with the specified configuration."