# Bobcat300-TTN

Give your **Bobcat 300 G285** Helium hotspot a second life by converting it into a fully functional **The Things Network (TTN)** LoRaWAN gateway.

Unlike other installation methods, **this project is specifically designed for the G285** and runs entirely from a **microSD card**.

**Nothing is written to the internal eMMC.** Your original Helium firmware remains completely untouched.

Want to switch back to the original hotspot? Simply remove the microSD card and reboot.

---

## Why?

Thousands of Bobcat 300 hotspots are no longer being used after the decline of Helium mining.

This project provides a **safe and reversible** way to convert a **Bobcat 300 G285** into a TTN gateway without modifying the original firmware.

The G285 is unique because it is capable of booting directly from a microSD card. This allows Armbian and TTN software to run entirely from the SD card while the factory software remains safely stored on the internal eMMC.

For **G290** and **G295** devices, please refer to the original **Bobcat-Armbian** project by **sicXnull**. Those models use a different installation procedure.

---

## Features

- ✅ Designed specifically for the **Bobcat 300 G285**
- ✅ Runs entirely from a microSD card
- ✅ Original Helium firmware remains untouched
- ✅ Nothing is written to the internal eMMC
- ✅ One-command installation using `install_ttn.sh`
- ✅ Installs Semtech Basic Station
- ✅ Ready for The Things Network (TTN)
- ✅ Roll back at any time by simply removing the microSD card

---

## Supported hardware

| Model | Status | Notes |
|--------|--------|-------|
| G285 | ✅ Supported | Safe SD-card installation (no eMMC modifications) |
| G290 | 🟡 Use Bobcat-Armbian | Different installation method |
| G295 | 🟡 Use Bobcat-Armbian | Different installation method |

---

## Specifications

### Hardware

- Bobcat 300 G285
- Semtech SX1302 LoRa concentrator
- Ethernet backhaul
- Runs entirely from microSD
- Original eMMC remains untouched

### Supported LoRaWAN Regions

- 🇪🇺 EU868 (tested)
- Other regions can be configured by editing the Basic Station configuration.

### Supported Data Rates

Supports the complete LoRaWAN EU868 data rate range, including:

- SF7BW125
- SF8BW125
- SF9BW125
- SF10BW125
- SF11BW125
- SF12BW125

### Gateway Software

- Armbian Linux
- Semtech Basic Station
- The Things Stack (TTN V3)
- CUPS/LNS support

### Network

- Ethernet or WiFi (use standard Linux init and contact the G285 by Putty with an SSH connection)
- DHCP
- NTP time synchronization
- Automatic reconnect


# Installation

Bobcat300-TTN starts **after** your Bobcat 300 G285 has already been converted to Armbian.

If you have not done that yet, start here:

## Step 1 — Install Armbian on the G285

Follow the complete installation guide from **sicXnull**.

https://github.com/sicXnull/Bobcat-Armbian

Follow **all** instructions in that repository until:

- Armbian boots successfully from the microSD card
- You can log into the hotspot using SSH (PuTTY)

Do **not** continue until this works.

---

## Step 2 — Verify the LoRa concentrator

Still following the Bobcat-Armbian instructions, install and test the original Helium packet forwarder.

```
install_helium.sh
```

Verify that:

- the SX1302 concentrator is detected
- packets are being received
- there are no SPI errors

Only continue once the Helium packet forwarder is working correctly.

---

## Step 3 — Connect using SSH

Open **PuTTY** (or another SSH client) and connect to your Bobcat G285 running Armbian.

Example:

```
Host: 192.168.1.xxx
Port: 22
```

Login with your Armbian username and password.

---

## Step 4 — Install Bobcat300-TTN

Run:

```bash
wget https://raw.githubusercontent.com/AdvdLaar/Bobcat300-TTN/main/install_ttn.sh
chmod +x install_ttn.sh
./install_ttn.sh
```

The installer will:

- stop the Helium packet forwarder
- install Semtech Basic Station
- configure the Gateway EUI
- configure CUPS/LNS
- enable automatic startup
- reboot the gateway

After reboot the gateway is ready to register in **The Things Network**.

## Credits

This project would not have been possible without the outstanding work of **sicXnull**, who successfully ported **Armbian** to the Bobcat 300 platform.

My project builds upon that foundation and adds an easy, safe and fully reversible installation of **The Things Network (TTN)** for the **Bobcat 300 G285**.

### Original Bobcat-Armbian project

https://github.com/sicXnull/Bobcat-Armbian

### Armbian forum discussion

https://forum.armbian.com/topic/57321-armbian-for-bobcat-300-29x-helium-miner/

Many thanks to **sicXnull** for making Armbian available for the Bobcat platform and for sharing all of the hard work with the community.

---
