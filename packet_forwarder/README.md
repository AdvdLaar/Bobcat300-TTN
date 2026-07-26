# Bobcat300-DebianMinimalDocker

This repository is based on the original work by **metrafonic**.

**Original repository:**
https://github.com/metrafonic/Bobcat300-DebianMinimalDocker

This version contains modifications required for the **Bobcat300-TTN** project.

A minimal docker-compose setup for running a **Helium LoRa gateway** on a **Bobcat 300** using Debian and Docker.

---

## Details

Currently tested on:
- **G285 / G29X**
- **G280**

Uses the following Docker images:
- **heliumdiy/sx1302_hal** – Fast and common packet forwarder used by most DIY miners. Used on 29x/285
- **quay.io/team-helium/miner:gateway-latest** – Official Helium gateway image
- **crankkster/pktfwd** – SX1301 Packet Forwarder for G280

---

## Credits

- **r00t1ng** – Supplying the initial missing LDO reset script  
- **sicXnull** – Extensive reverse engineering of the Bobcat 300  
  - https://github.com/sicXnull/Bobcat300-Debian  
  - https://github.com/sicXnull/BobcatDashboard  

---

## Ansible Config

1. Install the Debian image from:  
   https://github.com/sicXnull/Bobcat300-Debian

2. Copy SSH keys to the host:
   ```bash
   ssh-copy-id root@192.168.x.x
   ```
   Update `hosts.ini`, then change the root password:
   ```bash
   passwd
   ```

3. Set `region` and `device_model` in `bobcat.yml`

4. Run:
   ```bash
   ansible-playbook -i hosts.ini bobcat.yml
   ```

---

## Manual Config

### Preparations

1. Install the Debian image from:  
   https://github.com/sicXnull/Bobcat300-Debian

2. Remove the dashboard and unnecessary packages (optional):
   ```bash
   sh /var/dashboard/uninstall.sh
   systemctl disable timezone-config-check.timer server-detection.timer bobcat-watchdog.timer
   apt remove -y php* nginx* strongswan* openvpn*
   docker rm -f helium-miner portainer pktfwd
   apt -y autoremove
   ```

3. Reduce SD card wear:
   ```bash
   systemctl disable rsyslog
   echo "Storage=volatile" >> /etc/systemd/journald.conf
   ```

4. Disable Wi-Fi (not functional on this firmware):
   ```bash
   nmcli radio wifi off
   systemctl disable iwd wpa_supplicant
   ```

5. Update system and reboot:
   ```bash
   apt update && apt upgrade -y && reboot
   ```

6. Install Docker Compose and Chrony:
   ```bash
   apt -y install docker-compose chrony
   ```

7. Verify time sync:
   ```bash
   chronyc tracking
   ```

8. Set root password:
   ```bash
   passwd
   ```

9. (Optional) Disable password-based SSH authentication by adding:
   ```
   PasswordAuthentication no
   ```
   to `/etc/ssh/ssh_config`

---

## Install

Clone the repository:
```bash
git clone https://github.com/metrafonic/Bobcat300-DebianMinimalDocker bobcat
cd bobcat
```

---

## Select the Correct docker-compose File

- **G285** ? `docker-compose-G285.yml`
- **G29X** ? `docker-compose-G29X.yml`
- **G280** ? `docker-compose-G280.yml`

Set the `REGION` variable in the selected file.

Valid regions:
```
US915 | EU868 | EU433 | CN470 | CN779 | AU915 | AS923 | KR920 | IN865
```

---

## Device-Specific Setup

### G285 / G29X (First-Run Config Required)

Start `pktfwd` once to generate the config, then stop it.

**G285**
```bash
docker-compose -f docker-compose-G285.yml up -d pktfwd && sleep 1 && docker-compose -f docker-compose-G285.yml down
```

**G29X**
```bash
docker-compose -f docker-compose-G29X.yml up -d pktfwd && sleep 1 && docker-compose -f docker-compose-G29X.yml down
```

Edit:
```
packet_forwarder/configs/global_conf.json
```

Set `spidev_path`:

**G285**
```json
"spidev_path": "/dev/spidev1.0",
```

**G29X**
```json
"spidev_path": "/dev/spidev5.0",
```

Remove this line:
```json
"gps_i2c_path": "/dev/i2c-1",
```

Start normally:

**G285**
```bash
docker-compose -f docker-compose-G285.yml up -d
```

**G29X**
```bash
docker-compose -f docker-compose-G29X.yml up -d
```

---

### G280 (No First-Run Config Needed)

For **G280**, no pre-run or config edits are required.

Simply start:
```bash
docker-compose -f docker-compose-G280.yml up -d
```

Once started, it is fully operational.

---

## Verification

Check logs:
```bash
docker-compose -f docker-compose-G285.yml logs -f --tail=1000
```

Check miner animal name:
```bash
docker-compose -f docker-compose-G285.yml exec miner helium_gateway key info
```

(Replace the compose file name as needed.)

---

## Troubleshooting

- Ensure the correct docker-compose file is used for your device model
- Verify the `REGION` value is correct
- Check container logs:
  ```bash
  docker-compose -f <compose-file>.yml logs
  ```

### Device Notes

- **G285** ? `spidev1.0`
- **G29X** ? `spidev5.0`
- **G280** ? no initial start/stop required; `up -d` is sufficient
