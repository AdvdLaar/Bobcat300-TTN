# Bobcat300-TTN

Give your Bobcat 300 Helium hotspot a second life by converting it into a fully functional **The Things Network (TTN)** LoRaWAN gateway.

Bobcat300-TTN installs **Armbian** on a microSD card, leaving the original Bobcat firmware stored on the internal eMMC completely untouched.

No permanent modifications are made to the hotspot.

Want to switch back to the original Helium firmware? Simply remove the microSD card and reboot the device.

---

## Why?

Thousands of Bobcat 300 hotspots are no longer being used after the decline of Helium mining.

This project gives these devices a second life by turning them into reliable TTN LoRaWAN gateways while preserving the original firmware.

---

## Features

- ✅ Non-destructive installation (runs entirely from microSD)
- ✅ Keeps the original Helium firmware intact
- ✅ Easy installation using `install_ttn.sh`
- ✅ Installs Semtech Basic Station
- ✅ Ready for The Things Network (TTN)
- ✅ Easy rollback by removing the microSD card

---

## Supported hardware

| Model | Status | Notes |
|--------|--------|-------|
| G285 | ✅ Tested | Fully working |
| G290 | 🟡 Expected | Untested |
| G295 | 🟡 Expected | Untested |

---

## Installation

Coming soon.

The installation will be as simple as:

```bash
wget https://raw.githubusercontent.com/<yourname>/Bobcat300-TTN/main/install_ttn.sh
chmod +x install_ttn.sh
./install_ttn.sh
```

---

## Credits

This project builds upon the excellent work of **sicXnull**, who ported Armbian to the Bobcat 300 platform.

### Bobcat-Armbian

https://github.com/sicXnull/Bobcat-Armbian

### Issues and discussion

https://github.com/sicXnull/Bobcat-Armbian/issues

Many thanks to **sicXnull** for making Armbian available for the Bobcat 300 series.

---

## Disclaimer

This project is **not affiliated with Bobcat, Helium, Semtech or The Things Network**.

Use this software at your own risk.

Always create a backup before making changes to your hotspot.

---

## License

MIT License
