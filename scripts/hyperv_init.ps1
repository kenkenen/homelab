# Define the names for the switches and VM
$externalSwitchName = "ExternalSwitch"
$internalSwitchName = "InternalSwitch"
$vmName = "proxmoxve"
$isoPath = "$HOME\Downloads\proxmox-ve_8.3-1.iso"
$vmMemory = 4096MB
$vmDiskSize = 64GB

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

# Create the internal switch
New-VMSwitch -Name $internalSwitchName -SwitchType Internal
Write-Output "Internal switch '$internalSwitchName' created successfully."

# Create the VM
New-VM -Name $vmName -MemoryStartupBytes $vmMemory -BootDevice CD -Generation 2 -NoVHD

# Disable secure boot
Set-VMFirmware -VMName $vmName -EnableSecureBoot Off

# Add a virtual hard disk
Add-VMHardDiskDrive -VMName $vmName -Path (New-VHD -Path "$HOME\Hyper-V\$vmName\$vmName.vhdx" -SizeBytes $vmDiskSize -Dynamic).Path

# Add network adapters
$externalAdapter1 = Add-VMNetworkAdapter -VMName $vmName -SwitchName $externalSwitchName -Name "External Adapter 1"
$externalAdapter2 = Add-VMNetworkAdapter -VMName $vmName -SwitchName $externalSwitchName -Name "External Adapter 2"
$internalAdapter = Add-VMNetworkAdapter -VMName $vmName -SwitchName $internalSwitchName -Name "Internal Adapter"

# Enable MAC address spoofing for all network adapters
Set-VMNetworkAdapter -VMName $vmName -Name "External Adapter 1" -MacAddressSpoofing On
Set-VMNetworkAdapter -VMName $vmName -Name "External Adapter 2" -MacAddressSpoofing On
Set-VMNetworkAdapter -VMName $vmName -Name "Internal Adapter" -MacAddressSpoofing On

# Set the ISO file as the DVD drive
Set-VMDvdDrive -VMName $vmName -Path $isoPath

Write-Output "VM '$vmName' created successfully with the specified configuration."