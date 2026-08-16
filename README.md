# Install Azure Linux 4 on Hyper-V — Command Reference

This repository contains the PowerShell and Bash commands demonstrated in **Install Azure Linux 4 on Hyper-V — Microsoft’s New Linux Distro**.

The command references cover downloading and validating the Azure Linux 4 ISO, creating a Generation 2 Hyper-V virtual machine, configuring the minimal Azure Linux installation, assigning static network settings, joining Active Directory, and hardening SSH with public-key authentication.

> **Azure Linux 4 is currently a preview release intended for testing and evaluation rather than production deployment.**

## What Is Included

| File | Purpose |
|---|---|
| [`AzureLinux4-HyperV-PowerShell-Command-Reference.ps1`](AzureLinux4-HyperV-PowerShell-Command-Reference.ps1) | Windows and Hyper-V commands for downloading the ISO, verifying its SHA-256 checksum, creating the VM, checking Active Directory time, generating SSH keys, copying the public key, and testing SSH authentication. |
| [`AzureLinux4-Bash-Command-Reference.sh`](AzureLinux4-Bash-Command-Reference.sh) | Azure Linux commands for first-boot inspection, static networking, package installation, Active Directory integration, sudo configuration, SELinux labeling, and SSH hardening. |

## Applies To

- Azure Linux 4 Preview using the x86-64 standalone ISO
- Generation 2 Hyper-V virtual machines
- Azure Local hosts, formerly known as Azure Stack HCI
- Windows 11 or another Windows administrative workstation with PowerShell, OpenSSH, and SCP
- Windows Server 2025 Active Directory Domain Services
- Static IPv4 and DNS configuration using `systemd-networkd`
- RPM and DNF5 package management
- Active Directory integration using `realmd`, SSSD, `adcli`, and Kerberos
- SELinux-enforcing systems, firewalld, and OpenSSH public-key authentication

## Command-Reference Workflow

1. Download the Azure Linux 4 ISO and checksum file.
2. Verify that the downloaded ISO matches the published SHA-256 checksum.
3. Create a Generation 2 Hyper-V VM with static memory and Secure Boot disabled.
4. Complete the text-based Azure Linux installation.
5. Inspect the operating system, storage layout, firewall, and SELinux status.
6. Configure a static IP address, default gateway, DNS servers, and DNS search suffix with `systemd-networkd`.
7. Update Azure Linux and install the missing networking and DNS utilities.
8. Install the Active Directory integration packages and join the domain with `realm`.
9. Configure a selected Active Directory group for `sudo` access.
10. Configure ED25519 public-key SSH authentication and disable password authentication.

## Before Using the Commands

The code files are **command references, not unattended deployment scripts**. Each file includes a safety stop to prevent accidental whole-file execution. Review the content, then select and run only the commands required for your environment.

Replace the generalized example values before use, including:

- Hyper-V virtual switch name
- ISO and virtual-disk paths
- VM name, processor count, memory, and disk size
- Static IP address, subnet prefix, gateway, and DNS servers
- DNS domain and Kerberos realm
- Azure Linux hostname
- Domain-join account, domain user, and administrative group
- SSH key filename and destination account

The examples use the sample domain `contoso.com` and example private IPv4 addresses. They are placeholders and must be changed.

## Important Hyper-V Settings

For the Azure Linux 4 preview shown in the accompanying video:

- Create a **Generation 2** VM.
- Use a **static memory allocation** and disable Dynamic Memory.
- Disable **Secure Boot** because the preview ISO used in the demonstration is not Secure Boot signed.

The included VM sizing values—12 virtual processors, 12 GB of memory, and a 127 GB virtual disk—are demonstration values, not minimum requirements.

## Networking Notes

The minimal installer shown in the video does not present a networking configuration section. The Bash reference therefore uses `systemd-networkd` and a lower-numbered `.network` file to take precedence over the existing DHCP configuration.

The example configuration includes:

- Static IPv4 address and prefix
- Default gateway
- Two DNS servers
- DNS search suffix

After applying the configuration, the reference installs `iputils` and `bind-utils` to provide tools such as `ping`, `nslookup`, and `dig`.

## Active Directory Notes

The domain-join section uses:

- `realmd`
- SSSD and SSSD tools
- `adcli`
- Kerberos workstation utilities
- `oddjob` and `oddjob-mkhomedir`

Before joining the domain, confirm that DNS resolution works and that the Azure Linux system time is closely synchronized with Active Directory.

The sudoers example grants administrative access to a selected Active Directory group. Use a dedicated least-privilege group in production rather than automatically granting broad access.

## SSH Hardening Notes

The SSH section follows this order:

1. Confirm the effective SSH configuration with `sshd -T`.
2. Generate an ED25519 key pair on the Windows workstation.
3. Copy only the public key to Azure Linux.
4. Create `~/.ssh/authorized_keys` with restrictive permissions.
5. Restore the expected SELinux labels with `restorecon`.
6. Verify private-key authentication before disabling passwords.
7. Add `PasswordAuthentication no` under `/etc/ssh/sshd_config.d/`.
8. Validate the SSH configuration with `sshd -t`.
9. Keep the existing SSH session open while testing from a second terminal.
10. Verify that password-only authentication fails and private-key authentication succeeds.

## Official Azure Linux Repository

https://github.com/microsoft/azurelinux/tree/4.0

## Disclaimer

These commands are provided for educational and lab use. Azure Linux 4 preview behavior, package availability, installer options, and security defaults may change. Review every command, replace all example values, maintain a recovery path when changing remote-access settings, and test thoroughly before adapting the procedures to another environment.

## Author and Channel

**Darien Hawkins**  
**Darien’s Tips**  
YouTube: https://www.youtube.com/@darienstips9409  
GitHub: https://github.com/DariensTips

**Version:** 1.0  
**Created:** 2026-08-16
