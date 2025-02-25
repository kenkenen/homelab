# Define the names for the switches and VM
$EXTERNAL_SWITCH_NAME = "ExternalSwitch"
$PRIVATE_SWITCH_NAME = "PrivateSwitch"
$VM_NAME = "proxmoxve"
$ISO_PATH = "$HOME\Downloads\proxmox-ve_8.3-1.iso"
$VM_MEMORY = 4096MB
$VM_DISK_SIZE = 64GB
$VM_VHD_PATH = "C:\ProgramData\Microsoft\Windows\Virtual Hard Disks\$VM_NAME.vhdx"

# Delete existing VM if it exists
if (Get-VM -Name $VM_NAME -ErrorAction SilentlyContinue) {
    if ((Get-VM -Name $VM_NAME).State -eq 'Running') {
        Stop-VM -Name $VM_NAME -Force -TurnOff
    }
    Remove-VM -Name $VM_NAME -Force
    Write-Output "Existing VM '$VM_NAME' deleted."
}

# Delete existing external switch if it exists
if (Get-VMSwitch -Name $EXTERNAL_SWITCH_NAME -ErrorAction SilentlyContinue) {
    Remove-VMSwitch -Name $EXTERNAL_SWITCH_NAME -Force
    Write-Output "Existing external switch '$EXTERNAL_SWITCH_NAME' deleted."
}

# Delete existing private switch if it exists
if (Get-VMSwitch -Name $PRIVATE_SWITCH_NAME -ErrorAction SilentlyContinue) {
    Remove-VMSwitch -Name $PRIVATE_SWITCH_NAME -Force
    Write-Output "Existing private switch '$PRIVATE_SWITCH_NAME' deleted."
}

# Delete existing virtual hard disk if it exists
if (Test-Path $VM_VHD_PATH) {
    Remove-Item -Path $VM_VHD_PATH -Force
    Write-Output "Existing virtual hard disk '$VM_VHD_PATH' deleted."
}

# Create the external switch
# Get the network adapter that is connected to the internet
$EXTERNAL_ADAPTER = Get-NetAdapter | Where-Object { 
    $_.Status -eq "Up" -and 
    ($_.MediaType -eq "802.3" -or $_.MediaType -eq "Native 802.11") -and 
    $_.Name -notlike "v*" -and 
    $_.Name -notlike "*Bridge*" -and
    $_.InterfaceDescription -notlike "*Virtual*"
} | Select-Object -First 1

if ($EXTERNAL_ADAPTER) {
    New-VMSwitch -Name $EXTERNAL_SWITCH_NAME -NetAdapterName $EXTERNAL_ADAPTER.Name -AllowManagementOS $true
    Write-Output "External switch '$EXTERNAL_SWITCH_NAME' created successfully using adapter '$($EXTERNAL_ADAPTER.Name)'."
} else {
    Write-Output "No active network adapter found for creating the external switch."
}

# Create the private switch
New-VMSwitch -Name $PRIVATE_SWITCH_NAME -SwitchType private
Write-Output "Private switch '$PRIVATE_SWITCH_NAME' created successfully."

# Create the VM
New-VM -Name $VM_NAME -MemoryStartupBytes $VM_MEMORY -BootDevice CD -Generation 2 -NoVHD

# Set the number of vCPUs to 3
Set-VM -Name $VM_NAME -ProcessorCount 3

# Remove Default Network Adapter
Remove-VMNetworkAdapter -VMName "$VM_NAME" -Name "Network Adapter"

# Disable secure boot
Set-VMFirmware -VMName $VM_NAME -EnableSecureBoot Off

# Add a virtual hard disk
Add-VMHardDiskDrive -VMName $VM_NAME -Path (New-VHD -Path $VM_VHD_PATH -SizeBytes $VM_DISK_SIZE -Dynamic).Path

# Add network adapters
$EXTERNAL_ADAPTER1 = Add-VMNetworkAdapter -VMName $VM_NAME -SwitchName $EXTERNAL_SWITCH_NAME -Name "External Adapter 1"
$EXTERNAL_ADAPTER2 = Add-VMNetworkAdapter -VMName $VM_NAME -SwitchName $EXTERNAL_SWITCH_NAME -Name "External Adapter 2"
$PRIVATE_ADAPTER = Add-VMNetworkAdapter -VMName $VM_NAME -SwitchName $PRIVATE_SWITCH_NAME -Name "Private Adapter"

# Enable MAC address spoofing for all network adapters
Set-VMNetworkAdapter -VMName $VM_NAME -Name "External Adapter 1" -MacAddressSpoofing On
Set-VMNetworkAdapter -VMName $VM_NAME -Name "External Adapter 2" -MacAddressSpoofing On
Set-VMNetworkAdapter -VMName $VM_NAME -Name "Private Adapter" -MacAddressSpoofing On

# Expose Virtualization Extensions
Set-VMProcessor -VMName "$VM_NAME" -ExposeVirtualizationExtensions $true

# Set the ISO file as the DVD drive
Set-VMDvdDrive -VMName $VM_NAME -Path $ISO_PATH

# Power on the VM
Start-VM -Name $VM_NAME

Write-Output "VM '$VM_NAME' created and powered on successfully with the specified configuration."