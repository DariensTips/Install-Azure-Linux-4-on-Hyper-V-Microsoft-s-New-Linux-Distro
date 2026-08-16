##################################################
# (C) Download Azure Linux 4.0
##################################################

# Download Azure Linux 4.0 ISO using Start-BitsTransfer
Start-BitsTransfer `
    -Source https://aka.ms/azurelinux-4.0-x86_64.iso `
    -Destination "C:\HV\ISO"

# Download Azure Linux 4.0 ISO checksum using Start-BitsTransfer
Start-BitsTransfer `
    -Source https://aka.ms/azurelinux-4.0-x86_64-iso-checksum `
    -Destination $env:USERPROFILE\Downloads

# Verify the checksum of the downloaded ISO file
$checksumPath = "$env:USERPROFILE\Downloads\azurelinux-4.0-x86_64-iso-checksum"
$isoPath = "C:\HV\ISO\AzureLinux-4.0-x86_64.iso"
$expectedHash = (Get-Content $checksumPath).Substring(0,64)
$actualHash = (Get-FileHash $isoPath -Algorithm SHA256).Hash

$expectedHash -eq $actualHash


##################################################
# (D) Configure Hyper-V for Azure Linux 4.0
##################################################

#function to create a new Azure Linux 4.0 VM in Hyper-V
function New-AzureLinuxVM {
    # Declare VM name variable
    $daVM = "AzureLinux4-Preview"

    # Create VM
    New-VM `
        -Name $daVM `
        -Generation 2 `
        -MemoryStartupBytes 12GB `
        -SwitchName "ComputeSwitch(hv-seteam-compute)" `
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


##################################################
# (F) First Boot (BASH)
##################################################

cat /etc/os-release
hostnamectl

sudo hostnamectl hostname azlin4.dariens.tips

lsblk

systemctl status firewalld
sudo firewall-cmd --list-all
sudo firewall-cmd --info-service=ssh

sestatus

clear



##################################################
# (G) Manually Configure Networking (BASH)
##################################################

ip addr

networkctl status eth0

cd /etc/systemd/network
ls

cat 20-wired-dhcp.network

##################################################
sudo nano 10-eth0.network
[Match]
Name=eth0

[Network]
Address=10.22.25.43/24
Gateway=10.22.25.1
DNS=10.22.25.25
DNS=10.22.25.26
Domains=dariens.tips
##################################################

sudo systemctl restart systemd-networkd

ip addr
ip route
networkctl status eth0

dnf provides '*/ping'
dnf provides '*/nslookup'

sudo dnf update -y

sudo dnf install -y iputils bind-utils

ping -c 4 www.github.com

nslookup dariens.tips

dig _ldap._tcp.dc._msdcs.dariens.tips SRV

sudo dnf install -y ncurses

sudo reboot


##################################################
# (H) Active Directory Domain Join
##################################################

networkctl status eth0

sudo dnf install -y realmd sssd sssd-tools adcli krb5-workstation oddjob oddjob-mkhomedir


# Configure DNS to point to the AD DC (PowerShell)
$dcPDC=Get-ADDomain
Invoke-Command `
    -ComputerName $dcPDC.PDCEmulator `
    -ScriptBlock {Get-Date}
##################################################

timedatectl

realm discover dariens.tips

sudo realm join -v dariens.tips -U professa.ea

realm list

id astro.naut@dariens.tips

sudo visudo -f /etc/sudoers.d/02-linux-sudo-admins
%domain\ admins@dariens.tips ALL=(ALL:ALL) ALL

sudo visudo -c


##################################################
# (I) Configure and Harden SSH Authentication (BASH)
##################################################
ssh -l "professa.ea@dariens.tips" azlin4.dariens.tips

sudo cat /etc/ssh/sshd_config.d/50-permit-root-login.conf

sudo sshd -T | grep -E 'passwordauthentication|pubkeyauthentication|permitrootlogin'

scp $env:USERPROFILE\.ssh\azurelinux4.pub professa.ea@dariens.tips@azlin4.dariens.tips:~

mkdir -p ~/.ssh
chmod 700 ~/.ssh

cat ~/azurelinux4.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
sudo restorecon -Rv ~/.ssh
rm ~/azurelinux4.pub

ssh -i $env:USERPROFILE\.ssh\azurelinux4 -l "professa.ea@dariens.tips" azlin4.dariens.tips

sudo ls /etc/ssh/sshd_config.d/
sudo nano /etc/ssh/sshd_config.d/20-disablepasswordauth.conf
PasswordAuthentication no

sudo sshd -t

sudo systemctl restart sshd

sudo sshd -T | grep -E 'passwordauthentication|pubkeyauthentication|permitrootlogin'

ssh `
    -o PubkeyAuthentication=no `
    -o GSSAPIAuthentication=no `
    -o PreferredAuthentications=password `
    -l "professa.ea@dariens.tips" `
    azlin4.dariens.tips

    ssh -i $env:USERPROFILE\.ssh\azurelinux4 -l "professa.ea@dariens.tips" azlin4.dariens.tips



