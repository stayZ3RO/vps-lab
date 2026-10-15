# Phase 1 - Step-by-Step Guide 🛠️

---

## Quick Navigation

| Page | Link |
|---|---|
| Phase 1 Home | [README](README.md) |
| Overview | [overview.md](overview.md) |
| Step-by-Step Guide | [step-by-step.md](step-by-step.md) |
| Validation Evidence | [validation.md](validation.md) |
| Architecture Diagram | [Diagram](../../diagrams/phase-1-vps-baseline-security.md) |

---


![Status](https://img.shields.io/badge/status-complete-brightgreen)
![Scope](https://img.shields.io/badge/scope-VPS%20Hardening-blue)
![Access](https://img.shields.io/badge/access-SSH%20%2B%20Tailscale-purple)

## Purpose

This guide documents the implementation flow used to harden the Netcup VPS before deploying public services.

The goal was to configure a secure Linux baseline with SSH hardening, firewall rules, brute-force protection, Docker, Tailscale, and validation evidence.

---

## Implementation Flow

| Step | Task | Status |
|---|---|---:|
| 1 | Confirm server access | ✅ Complete |
| 2 | Update operating system | ✅ Complete |
| 3 | Configure hostname | ✅ Complete |
| 4 | Confirm non-root sudo user | ✅ Complete |
| 5 | Harden SSH | ✅ Complete |
| 6 | Configure UFW firewall | ✅ Complete |
| 7 | Enable Fail2Ban | ✅ Complete |
| 8 | Enable unattended upgrades | ✅ Complete |
| 9 | Configure timezone | ✅ Complete |
| 10 | Add swap | ✅ Complete |
| 11 | Install Docker and Docker Compose | ✅ Complete |
| 12 | Install Tailscale | ✅ Complete |
| 13 | Create VPS folder structure | ✅ Complete |
| 14 | Review listening ports | ✅ Complete |

---

## Step 1 - Confirm Server Access

Initial access was established over SSH.

The VPS was first accessed using provider-provided credentials, then moved to a safer non-root administrative model.

Validation goals:

- Confirm the VPS is reachable
- Confirm SSH access works
- Confirm administrative commands can be executed

---

## Step 2 - Update the Operating System

The package index and installed packages were updated.

Commands used:

    sudo apt update
    sudo apt upgrade -y

Baseline tools were installed:

    sudo apt install -y curl wget git nano htop ufw fail2ban unzip ca-certificates gnupg lsb-release tree

Why this matters:

| Reason | Benefit |
|---|---|
| Patch current packages | Reduces risk from outdated software |
| Install admin tools | Supports validation and troubleshooting |
| Install security tools | Prepares UFW and Fail2Ban |
| Install documentation tools | Enables tree output and cleaner screenshots |

---

## Step 3 - Configure Hostname

Hostname used:

    edge-vps

Validation commands:

    hostname
    hostnamectl

The local hosts file was also checked:

    cat /etc/hosts

Expected result:

- Hostname displays correctly
- Sudo commands do not show hostname resolution warnings

Why this matters:

A clean hostname makes the VPS easier to identify in documentation, monitoring, Tailscale, terminal sessions, and future dashboards.

---

## Step 4 - Confirm Non-Root Sudo User

A non-root administrative user was used for daily management.

Validation commands:

    groups ash
    sudo whoami

Expected sudo result:

    root

Why this matters:

| Practice | Reason |
|---|---|
| Use non-root admin user | Safer daily administration |
| Confirm sudo access | Ensures admin tasks still work |
| Avoid direct root SSH | Reduces brute-force risk |

---

## Step 5 - Harden SSH

SSH was configured for key-based access and reduced exposure.

Target SSH settings:

    PermitRootLogin no
    PasswordAuthentication no
    PubkeyAuthentication yes

Validation commands:

    sudo systemctl status ssh --no-pager
    sudo sshd -t

For screenshot clarity:

    sudo sshd -t && echo "SSH config validation passed"

Reload SSH after validation:

    sudo systemctl reload ssh

Safety workflow:

| Step | Reason |
|---|---|
| Keep original session open | Prevents accidental lockout |
| Validate config with sshd -t | Catches syntax errors |
| Reload SSH | Applies changes safely |
| Test from second terminal | Confirms access still works |
| Close old session last | Avoids losing access |

---

## Step 6 - Configure UFW Firewall

UFW was enabled with a minimal public exposure model.

Commands used:

    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow OpenSSH
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    sudo ufw enable

Validation command:

    sudo ufw status verbose

Expected baseline exposure:

| Port | Purpose |
|---|---|
| SSH | Administrative access |
| HTTP | Web traffic and certificate validation |
| HTTPS | Secure public services |

Design decision:

Application ports, database ports, dashboards, and internal tools should not be directly exposed to the public internet.

---

## Step 7 - Enable Fail2Ban

Fail2Ban was enabled for SSH brute-force protection.

Example SSH jail configuration:

    [sshd]
    enabled = true
    port = ssh
    maxretry = 5
    bantime = 1h
    findtime = 10m

Service commands:

    sudo systemctl restart fail2ban
    sudo systemctl enable fail2ban

Validation commands:

    sudo fail2ban-client status
    sudo fail2ban-client status sshd

Why this matters:

- Public VPS servers receive automated login attempts
- Fail2Ban adds a defensive layer for repeated failures
- SSH remains protected beyond key authentication and firewalling

---

## Step 8 - Enable Unattended Security Updates

Unattended upgrades were enabled for automatic security patching.

Commands used:

    sudo apt install -y unattended-upgrades
    sudo dpkg-reconfigure --priority=low unattended-upgrades

Validation command:

    systemctl status unattended-upgrades --no-pager

Why this matters:

| Benefit | Description |
|---|---|
| Automatic security patches | Helps reduce exposure from outdated packages |
| Lower maintenance burden | Security updates continue between manual checks |
| Production-minded baseline | Aligns with real server administration habits |

---

## Step 9 - Configure Timezone

Timezone was set to Eastern time.

Command used:

    sudo timedatectl set-timezone America/New_York

Validation command:

    timedatectl

Why this matters:

Consistent time settings help with logs, alerts, screenshots, monitoring, and troubleshooting.

---

## Step 10 - Add Swap

Swap was added to improve stability on a small VPS.

Validation command before and after:

    free -h

Example swap creation commands:

    sudo fallocate -l 2G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile

Persistence entry:

    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

Why this matters:

- Adds a memory safety buffer
- Helps reduce risk of process crashes under light memory pressure
- Useful for smaller VPS plans running Docker services

---

## Step 11 - Install Docker and Docker Compose

Docker was installed as the future container runtime.

Install command:

    curl -fsSL https://get.docker.com | sudo sh

The admin user was added to the Docker group:

    sudo usermod -aG docker ash

Group membership was refreshed:

    newgrp docker

Validation commands:

    docker version
    docker compose version
    docker run hello-world

Why this matters:

| Capability | Purpose |
|---|---|
| Docker Engine | Runs containers |
| Docker Compose | Defines repeatable service stacks |
| Docker group access | Allows non-root Docker management |
| hello-world test | Confirms Docker works |

---

## Step 12 - Install Tailscale

Tailscale was installed for private administrative access.

Install command:

    curl -fsSL https://tailscale.com/install.sh | sh

Authentication command:

    sudo tailscale up

Validation command:

    tailscale status

Why this matters:

- Keeps admin-only tools private
- Reduces need to expose dashboards publicly
- Supports future private access to Portainer, monitoring, and internal services

---

## Step 13 - Create VPS Folder Structure

A clean service layout was created under /opt/stayz3ro.

Commands used:

    sudo mkdir -p /opt/stayz3ro/{proxy,apps,monitoring,backups,scripts}
    sudo chown -R ash:ash /opt/stayz3ro

Validation command:

    tree /opt/stayz3ro

Expected structure:

    /opt/stayz3ro
    ├── apps
    ├── backups
    ├── monitoring
    ├── proxy
    └── scripts

Purpose:

| Folder | Intended Use |
|---|---|
| apps | Future Dockerized applications |
| proxy | Reverse proxy stack |
| monitoring | Monitoring agents or services |
| backups | Backup targets and scripts |
| scripts | Maintenance automation |

---

## Step 14 - Review Listening Ports

Listening services were reviewed before deploying public apps.

Validation command:

    sudo ss -tulpen | grep LISTEN

Why this matters:

- Confirms what services are listening
- Helps identify accidental exposure
- Creates a clean baseline before reverse proxy and app deployment

---

## Final Phase 1 Validation Checklist

| Validation Item | Status |
|---|---:|
| Hostname configured | ✅ Complete |
| Non-root sudo user works | ✅ Complete |
| SSH service active | ✅ Complete |
| SSH config validates | ✅ Complete |
| Root SSH login disabled | ✅ Complete |
| Password SSH login disabled | ✅ Complete |
| UFW enabled | ✅ Complete |
| Fail2Ban active | ✅ Complete |
| Unattended upgrades enabled | ✅ Complete |
| Docker installed | ✅ Complete |
| Docker Compose installed | ✅ Complete |
| Tailscale connected | ✅ Complete |
| Folder structure created | ✅ Complete |
| Listening ports reviewed | ✅ Complete |

---

## Phase 1 Result

At the end of this phase, the VPS has a hardened and validated baseline.

The server is ready for:

- Domain DNS configuration
- Reverse proxy deployment
- HTTPS setup
- Docker application hosting
- Monitoring and backup planning
