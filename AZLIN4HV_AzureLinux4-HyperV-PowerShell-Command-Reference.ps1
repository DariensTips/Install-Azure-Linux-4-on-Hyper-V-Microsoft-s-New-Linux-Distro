<#
.SYNOPSIS
    Azure Linux 4 on Hyper-V PowerShell command reference.

.DESCRIPTION
    Contains the PowerShell commands demonstrated in the video:
    "Install Azure Linux 4 on Hyper-V — Microsoft’s New Linux Distro."

    The commands cover downloading and validating the Azure Linux 4 ISO,
    creating a Generation 2 Hyper-V virtual machine, checking Active Directory
    time, generating an SSH key pair, transferring the public key, and testing
    SSH authentication.

    This is a command reference, not an unattended deployment script. Review
    and run each section individually. Replace all generalized example values
    before use.

.NOTES
    File Name      : AzureLinux4-HyperV-PowerShell-Command-Reference.ps1
    Author         : Darien Hawkins
    Channel        : Darien's Tips
    YouTube        : https://www.youtube.com/@darienstips9409
    GitHub         : https://github.com/DariensTips
    Version        : 1.0
    Created        : 2026-08-16
    Applies To     : Windows 11; Windows Server or Azure Local with Hyper-V;
                     Windows Server 2025 Active Directory; Azure Linux 4 Preview

    IMPORTANT:
    - Run only the section required for the current task.
    - Replace example paths, switch names, domain names, hostnames, and accounts.
    - Keep an existing SSH session open while changing SSH authentication.

    DISCLAIMER:
    These commands are provided for educational and lab use. Test all changes
    in a controlled environment before adapting them for another system.
#>

# SAFETY STOP
# This file is intentionally structured as a command reference. Select and run
# the required commands or sections individually rather than executing the
# entire file from beginning to end.
Write-Warning "Command reference only. Select and run the required section individually."
return

# ============================================================================
# SECTION 1 — DOWNLOAD THE AZURE LINUX 4 ISO AND CHECKSUM
# Run from the Windows or Hyper-V system that will store the ISO.
# ============================================================================

Start-BitsTransfer `
    -Source https://aka.ms/azurelinux-4.0-x86_64.iso `
    -Destination "C:\HV\ISO"

Start-BitsTransfer `
    -Source https://aka.ms/azurelinux-4.0-x86_64-iso-checksum `
    -Destination $env:USERPROFILE\Downloads


# ============================================================================
# SECTION 2 — VERIFY THE ISO SHA-256 CHECKSUM
# ============================================================================

$checksumPath = "$env:USERPROFILE\Downloads\azurelinux-4.0-x86_64-iso-checksum"
$isoPath = "C:\HV\ISO\AzureLinux-4.0-x86_64.iso"
$expectedHash = (Get-Content $checksumPath).Substring(0,64)
$actualHash = (Get-FileHash $isoPath -Algorithm SHA256).Hash

$expectedHash -eq $actualHash


# ============================================================================
# SECTION 3 — CREATE THE GENERATION 2 HYPER-V VIRTUAL MACHINE
# Replace the VM name, virtual-switch name, ISO path, and sizing values.
# ============================================================================

function New-AzureLinuxVM {
    # Declare VM name variable
    $daVM = "AzureLinux4-Preview"

    # Create VM
    New-VM `
        -Name $daVM `
        -Generation 2 `
        -MemoryStartupBytes 12GB `
        -SwitchName "Your-Hyper-V-Switch" `
        -NewVHDPath "$daVM-2.vhdx" `
        -NewVHDSizeBytes 127GB

    # Set Processor and add DVD
    Set-VM -VMName $daVM -ProcessorCount 12
    Add-VMDvdDrive -VMName $daVM -Path "C:\HV\ISO\AzureLinux-4.0-x86_64.iso"

    # Set Memory to static
    Set-VMMemory `
        -VMName $daVM `
        -DynamicMemoryEnabled $false

    # Set first boot device and ensure Secure Boot is off
    Set-VMFirmware `
        -VMName $daVM `
        -FirstBootDevice (Get-VMDvdDrive -VMName $daVM) `
        -EnableSecureBoot off
}

New-AzureLinuxVM


# ============================================================================
# SECTION 4 — CHECK THE ACTIVE DIRECTORY PDC EMULATOR TIME
# Run from a Windows Privileged Access Workstation with the Active Directory
# PowerShell module installed and PowerShell remoting available to the DC.
# ============================================================================

$dcPDC = Get-ADDomain

Invoke-Command `
    -ComputerName $dcPDC.PDCEmulator `
    -ScriptBlock {Get-Date}


# ============================================================================
# SECTION 5 — CREATE AN ED25519 SSH KEY PAIR
# Run from the Windows workstation used to administer Azure Linux.
# ============================================================================

ssh-keygen.exe -t ed25519 -f $env:USERPROFILE\.ssh\azurelinux4


# ============================================================================
# SECTION 6 — COPY THE PUBLIC KEY TO AZURE LINUX
# Replace the domain UPN and Azure Linux hostname.
# Password authentication must still be available for this transfer.
# ============================================================================

scp $env:USERPROFILE\.ssh\azurelinux4.pub admin.user@contoso.com@azlin4.contoso.com:~


# ============================================================================
# SECTION 7 — TEST PRIVATE-KEY SSH AUTHENTICATION
# ============================================================================

ssh -i $env:USERPROFILE\.ssh\azurelinux4 -l "admin.user@contoso.com" azlin4.contoso.com


# ============================================================================
# SECTION 8 — FORCE A PASSWORD-ONLY SSH TEST
# Run after PasswordAuthentication has been set to no on Azure Linux.
# Keep the current working SSH session open as a recovery path.
# ============================================================================

ssh `
    -o PubkeyAuthentication=no `
    -o GSSAPIAuthentication=no `
    -o PreferredAuthentications=password `
    -l "admin.user@contoso.com" `
    azlin4.contoso.com


# ============================================================================
# SECTION 9 — RETEST PRIVATE-KEY SSH AUTHENTICATION
# ============================================================================

ssh -i $env:USERPROFILE\.ssh\azurelinux4 -l "admin.user@contoso.com" azlin4.contoso.com
