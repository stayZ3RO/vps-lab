# Phase 1 - Validation Evidence 📸

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


![Status](https://img.shields.io/badge/status-validated-brightgreen)
![Evidence](https://img.shields.io/badge/evidence-screenshots-blue)
![Security](https://img.shields.io/badge/security-baseline%20verified-success)

## Purpose

This page documents the validation evidence for Phase 1: VPS Baseline & Security Hardening.

The goal is to show that the VPS was not only configured, but also verified through command output and redacted screenshots.

---

## Validation Summary

| Area | Validation Result |
|---|---|
| Hostname | Configured and resolving cleanly |
| OS | Ubuntu Linux documented |
| SSH service | Active and running |
| SSH config | Syntax validation passed |
| Firewall | UFW enabled with limited exposure |
| Brute-force protection | Fail2Ban active for SSH |
| Updates | Unattended upgrades enabled |
| Runtime | Docker and Docker Compose installed |
| Private access | Tailscale connected |
| Filesystem | /opt/stayz3ro structure created |
| Ports | Listening services reviewed |

---

## Completion Criteria

Phase 1 is complete because:

| Requirement | Status |
|---|---:|
| Hostname resolves correctly with no sudo warning | ✅ Complete |
| Non-root sudo user works | ✅ Complete |
| SSH service is active | ✅ Complete |
| SSH config validates successfully | ✅ Complete |
| Root SSH login is disabled | ✅ Complete |
| Password SSH login is disabled | ✅ Complete |
| UFW is enabled | ✅ Complete |
| Only SSH, HTTP, and HTTPS are allowed | ✅ Complete |
| Fail2Ban is active for SSH | ✅ Complete |
| Unattended upgrades are enabled | ✅ Complete |
| Docker and Docker Compose work | ✅ Complete |
| Tailscale is installed and connected | ✅ Complete |
| /opt/stayz3ro folder structure exists | ✅ Complete |
| Listening ports are understood and documented | ✅ Complete |

---

# Screenshot Evidence

## 02 - Hostname Validation

Confirms the VPS hostname is configured cleanly as edge-vps.

![Hostname validation](../../screenshots-redacted/phase-1-vps-baseline-security/02-hostnamectl.png)

---

## 03 - OS Version

Documents the Ubuntu Linux version used for the VPS baseline.

![OS version](../../screenshots-redacted/phase-1-vps-baseline-security/03-os-version.png)

---

## 05 - SSH Service Status

Confirms the SSH service is active and running.

![SSH service status](../../screenshots-redacted/phase-1-vps-baseline-security/05-ssh-service-status.png)

---

## 06 - SSH Config Validation

Confirms the SSH configuration syntax passed validation before reload.

![SSH config validation](../../screenshots-redacted/phase-1-vps-baseline-security/06-ssh-config-validation.png)

---

## 07 - UFW Firewall Status

Confirms UFW is enabled and only the intended baseline ports are allowed.

![UFW firewall status](../../screenshots-redacted/phase-1-vps-baseline-security/07-ufw-firewall-status.png)

---

## 08 - Fail2Ban Status

Confirms Fail2Ban is active for SSH protection.

![Fail2Ban status](../../screenshots-redacted/phase-1-vps-baseline-security/08-fail2ban-status.png)

---

## 09 - Unattended Upgrades

Confirms unattended upgrades are enabled for automatic security updates.

![Unattended upgrades](../../screenshots-redacted/phase-1-vps-baseline-security/09-unattended-upgrades-status.png)

---

## 10 - Swap and Memory Check

Confirms system memory and swap status after baseline configuration.

![Swap and memory check](../../screenshots-redacted/phase-1-vps-baseline-security/10-swap-memory-check.png)

---

## 11 - Docker Validation

Confirms Docker and Docker Compose are installed and available.

![Docker validation](../../screenshots-redacted/phase-1-vps-baseline-security/11-docker-version.png)

---

## 12 - Tailscale Status

Confirms the VPS is connected to Tailscale for private administrative access.

![Tailscale status](../../screenshots-redacted/phase-1-vps-baseline-security/12-tailscale-status-redacted.png)

---

## 13 - VPS Folder Structure

Confirms the /opt/stayz3ro folder structure was created for future services.

![VPS folder structure](../../screenshots-redacted/phase-1-vps-baseline-security/13-folder-structure.png)

---

## 14 - Listening Ports

Confirms listening services were reviewed before public app deployment.

![Listening ports](../../screenshots-redacted/phase-1-vps-baseline-security/14-listening-ports-redacted.png)

---

## Optional Evidence Not Included

| Evidence | Reason |
|---|---|
| Netcup VPS dashboard | Omitted to avoid exposing provider/account details |
| Sudo user group screenshot | Verified during setup but not included in this screenshot set |

---

## Redaction Rules

The following information was redacted or excluded before committing screenshots:

| Sensitive Item | Handling |
|---|---|
| Public IPv4 address | Redacted or excluded |
| IPv6 address | Redacted or excluded |
| Tailscale IPs | Redacted |
| Tailscale device identifiers | Redacted where needed |
| Netcup account details | Excluded |
| Email addresses | Redacted or excluded |
| Authentication URLs | Excluded |
| API keys or tokens | Excluded |
| SSH keys | Excluded |
| Billing details | Excluded |

---

## Validation Result

Phase 1 is validated.

The VPS has a secure baseline and is ready for the next phase:

**Phase 2 - Domain DNS & Public Routing**
