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

# Current status

The gateway currently uses the proven and widely supported:

**Semtech UDP Packet Forwarder**

This implementation has been tested successfully on the **Bobcat 300 G285** with:

* SX1302 LoRa concentrator
* EU868 region
* The Things Network V3
* Ethernet connection
* Docker based packet forwarder

The UDP packet forwarder is currently the stable version of this project.

---

# Future development

The next development step is to move towards:

**Semtech Basic Station**

Basic Station is the newer gateway protocol and offers advantages such as:

* Secure WebSocket connection
* Better gateway management
* CUPS support
* Easier future integration with The Things Stack

The goal is to add Basic Station support while keeping the current UDP installation available as a reliable fallback.

---

# Features

* ✅ Designed specifically for the **Bobcat 300 G285**
* ✅ Runs entirely from a microSD card
* ✅ Original Helium firmware remains untouched
* ✅ Nothing is written to the internal eMMC
* ✅ Converts the G285 into a TTN LoRaWAN gateway
* ✅ Uses Semtech UDP Packet Forwarder
* ✅ Automatic Gateway EUI detection
* ✅ Docker based gateway operation
* ✅ Safe and reversible installation
* 🟡 Basic Station support planned

---

# Supported hardware

| Model | Status                | Notes                                             |
| ----- | --------------------- | ------------------------------------------------- |
| G285  | ✅ Supported           | Safe SD-card installation (no eMMC modifications) |
| G290  | 🟡 Use Bobcat-Armbian | Different installation method                     |
| G295  | 🟡 Use Bobcat-Armbian | Different installation method                     |

---

# Specifications

## Hardware

* Bobcat 300 G285
* Semtech SX1302 LoRa concentrator
* Ethernet backhaul
* microSD boot
* Original eMMC remains untouched

## Supported LoRaWAN Regions

Currently tested:

* 🇪🇺 EU868

Other regions can be configured by changing the packet forwarder configuration.

## Gateway Software

Current:

* Armbian Linux
* Docker
* Semtech UDP Packet Forwarder
* The Things Network V3

Future:

* Semtech Basic Station
* CUPS/LNS support

## Network

* Ethernet or WiFi
* SSH access using PuTTY
* DHCP
* NTP time synchronization
* Automatic reconnect after power loss

---

# Installation

This project **does not install Armbian**.

It starts **after** your Bobcat 300 G285 has already been converted to Armbian.

---

## Step 1 — Install Armbian

Follow the complete Bobcat-Armbian installation guide:

https://github.com/sicXnull/Bobcat-Armbian

For the **Bobcat 300 G285**, complete:

* ✅ G285 – SD Card Boot (No eMMC Flash Required)
* ✅ First Boot
* ✅ Helium Installation

Do not continue until:

* Armbian boots from the microSD card
* SSH access works
* The SX1302 concentrator is detected
* The original Helium installation has completed successfully

The original firmware remains stored safely on the internal eMMC.

---

# Step 2 — Connect to the gateway

Use **PuTTY** or another SSH client.

Example:

```text
Host: 192.168.1.xxx
Port: 22
```

Login with your Armbian credentials.

---

# Step 3 — Install TTN UDP Packet Forwarder

Download and run:

```bash
wget https://raw.githubusercontent.com/AdvdLaar/Bobcat300-TTN/main/install_ttn_udp.sh

chmod +x install_ttn_udp.sh

./install_ttn_udp.sh
```

The installer will:

* Detect the correct network MAC address
* Create the Gateway EUI
* Configure TTN UDP settings
* Remove the Helium miner container from the Docker setup
* Create a TTN-only packet forwarder
* Start the LoRa gateway automatically

---

# Step 4 — Register the gateway in TTN

Create a gateway in:

https://console.cloud.thethings.network/

Use the Gateway EUI shown by the installer.

The gateway should appear online after startup.

---

# That's it!

Your **Bobcat 300 G285** is now running as a TTN LoRaWAN gateway.

The original Helium firmware remains untouched.

To return to the original Helium hotspot:

1. Power off the gateway
2. Remove the microSD card
3. Reboot

---

# Credits

This project would not have been possible without the outstanding work of **sicXnull**, who successfully ported **Armbian** to the Bobcat 300 platform.

This project builds upon that foundation and adds an easy, safe and reversible installation of **The Things Network (TTN)** for the **Bobcat 300 G285**.

## Original Bobcat-Armbian project

https://github.com/sicXnull/Bobcat-Armbian

## Armbian forum discussion

https://forum.armbian.com/topic/57321-armbian-for-bobcat-300-29x-helium-miner/

Many thanks to **sicXnull** for making Armbian available for the Bobcat platform and sharing this work with the community.

---
