#!/bin/bash
# ============================================================
# Linux Hardening Script — by ibramoha2
# Inspired by CIS Benchmark Level 1
# Usage: sudo bash harden.sh
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err() { echo -e "${RED}[-]${NC} $1"; }

if [ "$EUID" -ne 0 ]; then
  err "Ce script doit être exécuté en tant que root"
  exit 1
fi

echo "========================================"
echo " 🔐 Linux Hardening Script — ibramoha2"
echo "========================================"
echo ""

# 1. Mise à jour système
log "Mise à jour du système..."
apt-get update -qq && apt-get upgrade -y -qq
log "Système mis à jour ✅"

# 2. Installation fail2ban
log "Installation de fail2ban..."
apt-get install -y fail2ban -qq
systemctl enable fail2ban
systemctl start fail2ban
log "fail2ban installé et démarré ✅"

# 3. Configuration SSH sécurisée
log "Sécurisation SSH..."
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/X11Forwarding yes/X11Forwarding no/' /etc/ssh/sshd_config
echo "ClientAliveInterval 300" >> /etc/ssh/sshd_config
echo "ClientAliveCountMax 2" >> /etc/ssh/sshd_config
systemctl restart sshd
log "SSH sécurisé ✅"

# 4. Configuration sysctl (kernel hardening)
log "Durcissement du kernel..."
cat >> /etc/sysctl.conf << 'SYSCTL'
# Security hardening — ibramoha2
net.ipv4.ip_forward = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.log_martians = 1
kernel.randomize_va_space = 2
fs.suid_dumpable = 0
kernel.dmesg_restrict = 1
SYSCTL
sysctl -p > /dev/null 2>&1
log "Kernel durci ✅"

# 5. Firewall UFW
log "Configuration du firewall UFW..."
apt-get install -y ufw -qq
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw --force enable
log "UFW configuré ✅"

# 6. Audit des fichiers SUID
log "Audit des fichiers SUID/SGID..."
find / -perm /4000 -type f 2>/dev/null > /tmp/suid_files.txt
warn "Fichiers SUID trouvés — voir /tmp/suid_files.txt"

# 7. Auditd
log "Installation de auditd..."
apt-get install -y auditd -qq
systemctl enable auditd
systemctl start auditd
log "auditd démarré ✅"

echo ""
echo "========================================"
echo " ✅ Durcissement terminé !"
echo " 🔍 Vérifiez /tmp/suid_files.txt"
echo " 📋 Backup SSH: /etc/ssh/sshd_config.bak"
echo "========================================"
