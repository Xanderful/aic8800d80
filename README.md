# AIC8800D80 USB WiFi Driver for Linux (Kernel 6.15+)

A patched Linux driver for the **AIC8800D80** chipset, tested with the **CUDY WU900** USB WiFi adapter. Forked from [goecho/aic8800_linux_drvier](https://github.com/goecho/aic8800_linux_drvier) with fixes for modern kernels (6.15 – 6.17+).

## Supported Hardware

| Adapter | Chipset | USB IDs |
|---------|---------|---------|
| CUDY WU900 | AIC8800D80 | `a69c:572c` (mass storage) → `a69c:8d80` → `368b:8d81` (WiFi) |

Other AIC8800D80-based adapters (USB IDs `a69c:5721`, `a69c:5723`) should also work.

## Features

- 802.11ac (WiFi 5) dual-band, up to 433 Mbps on 5 GHz
- WPA/WPA2/WPA3 support
- Automatic mass-storage-to-WiFi mode switching via udev
- MU-MIMO support
- Secure Boot compatible (with manual MOK signing)

## Requirements

- Linux kernel **6.15+** (tested on 6.17.0)
- Kernel headers and build tools

```bash
# Ubuntu / Debian
sudo apt install build-essential linux-headers-$(uname -r) git

# Fedora
sudo dnf install kernel-devel kernel-headers gcc make git

# Arch
sudo pacman -S linux-headers base-devel git
```

## Installation

```bash
git clone https://github.com/Xanderful/aic8800d80.git
cd aic8800d80
make
sudo make install
```

This will:
1. Build `aic_load_fw.ko` (firmware loader) and `aic8800_fdrv.ko` (WiFi driver)
2. Install modules to `/lib/modules/$(uname -r)/`
3. Install firmware to `/lib/firmware/aic8800D80/`
4. Install udev rules to `/etc/udev/rules.d/aic.rules`
5. Run `depmod` so modules auto-load

After installation, **unplug and replug** the adapter. The udev rule will auto-eject the virtual CDROM and the WiFi driver will load automatically.

### Verify

```bash
# Check modules are loaded
lsmod | grep aic

# Check WiFi interface exists
ip link | grep wlan_cudy

# Scan for networks
sudo iwlist wlan_cudy scan | grep ESSID
```

## Secure Boot

If your system has Secure Boot enabled, unsigned kernel modules will be blocked. You need to create a Machine Owner Key (MOK) and sign the modules:

```bash
# 1. Create a signing key (one-time)
sudo mkdir -p /root/module-signing
cd /root/module-signing
sudo openssl req -new -x509 -newkey rsa:2048 -keyout MOK.priv -outform DER \
    -out MOK.der -nodes -days 36500 -subj "/CN=Local Module Signing/"

# 2. Enroll the key (one-time, requires reboot)
sudo mokutil --import /root/module-signing/MOK.der
# Set a one-time password when prompted, then reboot
# At the blue MOK Manager screen: Enroll MOK → Continue → Enter password → Reboot

# 3. Sign the modules (required after each rebuild)
SIGN=/usr/src/linux-headers-$(uname -r)/scripts/sign-file
KMOD=/lib/modules/$(uname -r)

sudo $SIGN sha256 /root/module-signing/MOK.priv /root/module-signing/MOK.der \
    $KMOD/extra/aic_load_fw.ko
sudo $SIGN sha256 /root/module-signing/MOK.priv /root/module-signing/MOK.der \
    $KMOD/extra/aic8800_fdrv.ko
```

After signing, unplug/replug the adapter or run `sudo modprobe aic8800_fdrv`.

## Uninstallation

```bash
sudo make uninstall
```

## What Was Changed (vs upstream)

These patches fix build failures on kernel 6.15 – 6.17+:

| File | Fix |
|------|-----|
| `aic_bluetooth_main.c` | `MODULE_IMPORT_NS()` string literal syntax (kernel 6.12+) |
| `rwnx_cfgfile.h` | Added missing `<linux/if_ether.h>` and `lmac_msg.h` includes |
| `rwnx_rx.c` | `from_timer()` → `timer_container_of()` (6.15+), added `link_id` param to `cfg80211_rx_spurious_frame()` / `cfg80211_rx_unexpected_4addr_frame()` |
| `rwnx_compat.h` | Compat macros for `del_timer()` → `timer_delete()` (removed in 6.17) |
| `rwnx_radar.c` | Added `link_id` param to `cfg80211_cac_event()` |
| `aicwf_usb.h` / `aicwf_usb.c` | Added USB product IDs `0x8d80`, `0x8d81` and vendor `0x368b` for CUDY WU900 |
| `tools/aic.rules` | Added udev rule for USB ID `572c`, `UDISKS_IGNORE` to suppress mount popups, WiFi interface rename |

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Credits

- Original driver: [goecho/aic8800_linux_drvier](https://github.com/goecho/aic8800_linux_drvier)
- Upstream source: [shenmintao/aic8800d80](https://github.com/shenmintao/aic8800d80)

