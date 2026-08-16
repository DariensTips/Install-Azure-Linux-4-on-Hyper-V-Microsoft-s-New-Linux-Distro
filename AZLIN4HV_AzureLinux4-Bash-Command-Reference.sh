#!/usr/bin/env bash
# ==============================================================================
# Title          : Azure Linux 4 Bash Command Reference
# File Name      : AzureLinux4-Bash-Command-Reference.sh
# Author         : Darien Hawkins
# Channel        : Darien's Tips
# YouTube        : https://www.youtube.com/@darienstips9409
# GitHub         : https://github.com/DariensTips
# Version        : 1.0
# Created        : 2026-08-16
# Applies To     : Azure Linux 4 Preview installed as a Generation 2 Hyper-V VM
#
# Description:
#   Commands demonstrated in the video:
#   "Install Azure Linux 4 on Hyper-V — Microsoft’s New Linux Distro."
#
#   This file covers first-boot inspection, static network configuration,
#   package installation, Active Directory integration, sudo configuration,
#   SELinux labeling, and OpenSSH hardening.
#
# IMPORTANT:
#   This is a command reference, not an unattended deployment script.
#   Review and run each section individually. Replace every generalized example
#   value before use, including IP addresses, DNS servers, domain names,
#   hostnames, user accounts, and Active Directory groups.
#
# DISCLAIMER:
#   These commands are provided for educational and lab use. Azure Linux 4 is
#   a preview release, and behavior may change. Test all changes in a controlled
#   environment and keep a recovery path when modifying remote access.
# ==============================================================================

# SAFETY STOP
# This file is intentionally structured as a command reference. Copy and run
# the required commands or sections individually rather than executing or
# sourcing the entire file.
printf '%s\n' 'Command reference only. Copy and run the required section individually.'
return 0 2>/dev/null || exit 0

# ==============================================================================
# SECTION 1 — FIRST-BOOT INSPECTION
# ==============================================================================

cat /etc/os-release
hostnamectl

sudo hostnamectl hostname azlin4.contoso.com

lsblk

systemctl status firewalld
sudo firewall-cmd --list-all
sudo firewall-cmd --info-service=ssh

sestatus

clear


# ==============================================================================
# SECTION 2 — IDENTIFY THE NETWORK INTERFACE
# ==============================================================================

ip addr
networkctl status eth0


# ==============================================================================
# SECTION 3 — REVIEW THE EXISTING SYSTEMD-NETWORKD CONFIGURATION
# ==============================================================================

cd /etc/systemd/network
ls
cat 20-wired-dhcp.network


# ==============================================================================
# SECTION 4 — CREATE A STATIC SYSTEMD-NETWORKD CONFIGURATION
# Replace the interface name, IP address, prefix, gateway, DNS servers, and
# search domain. Add the commented content below to 10-eth0.network.
# ==============================================================================

sudo nano 10-eth0.network

# [Match]
# Name=eth0
#
# [Network]
# Address=192.168.1.43/24
# Gateway=192.168.1.1
# DNS=192.168.1.10
# DNS=192.168.1.11
# Domains=contoso.com


# ==============================================================================
# SECTION 5 — APPLY AND VERIFY THE NETWORK CONFIGURATION
# ==============================================================================

sudo systemctl restart systemd-networkd

ip addr
ip route
networkctl status eth0


# ==============================================================================
# SECTION 6 — LOCATE, UPDATE, AND INSTALL NETWORKING UTILITIES
# ==============================================================================

dnf provides '*/ping'
dnf provides '*/nslookup'

sudo dnf update -y
sudo dnf install -y iputils bind-utils

ping -c 4 www.github.com
nslookup contoso.com
dig _ldap._tcp.dc._msdcs.contoso.com SRV

sudo dnf install -y ncurses
clear

sudo reboot


# ==============================================================================
# SECTION 7 — VERIFY NETWORKING AFTER REBOOT
# ==============================================================================

networkctl status eth0


# ==============================================================================
# SECTION 8 — INSTALL ACTIVE DIRECTORY INTEGRATION PACKAGES
# ==============================================================================

sudo dnf install -y realmd sssd sssd-tools adcli krb5-workstation oddjob oddjob-mkhomedir


# ==============================================================================
# SECTION 9 — VERIFY TIME, DISCOVER THE DOMAIN, AND JOIN ACTIVE DIRECTORY
# Replace the domain and domain-join account.
# ==============================================================================

timedatectl

realm discover contoso.com

sudo realm join -v contoso.com -U domainjoinuser

realm list

id domain.user@contoso.com


# ==============================================================================
# SECTION 10 — GRANT A SELECTED ACTIVE DIRECTORY GROUP SUDO ACCESS
# Add the commented sudoers rule below to the file opened by visudo.
# Use a dedicated least-privilege AD group for production environments.
# ==============================================================================

sudo visudo -f /etc/sudoers.d/02-linux-sudo-admins

# %linux\ admins@contoso.com ALL=(ALL:ALL) ALL

sudo visudo -c

sudo chown root:root /etc/sudoers.d/02-linux-sudo-admins
sudo chmod 0440 /etc/sudoers.d/02-linux-sudo-admins

sudo restorecon -v /etc/sudoers.d/02-linux-sudo-admins
sudo visudo -c


# ==============================================================================
# SECTION 11 — INSPECT THE EFFECTIVE SSH SERVER CONFIGURATION
# ==============================================================================

sudo cat /etc/ssh/sshd_config.d/50-permit-root-login.conf

sudo sshd -T | grep -E 'passwordauthentication|pubkeyauthentication|permitrootlogin'


# ==============================================================================
# SECTION 12 — INSTALL THE USER'S SSH PUBLIC KEY
# The public key is copied from the Windows workstation before these commands.
# ==============================================================================

mkdir -p ~/.ssh
chmod 700 ~/.ssh

cat ~/azurelinux4.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

sudo restorecon -Rv ~/.ssh

rm ~/azurelinux4.pub


# ==============================================================================
# SECTION 13 — DISABLE SSH PASSWORD AUTHENTICATION
# Add the commented directive below to the file opened with nano.
# Keep the current SSH session open until a new key-authenticated session works.
# ==============================================================================

sudo ls /etc/ssh/sshd_config.d/

sudo nano /etc/ssh/sshd_config.d/20-disablepasswordauth.conf

# PasswordAuthentication no

sudo sshd -t

sudo systemctl restart sshd

sudo sshd -T | grep -E 'passwordauthentication|pubkeyauthentication|permitrootlogin'
