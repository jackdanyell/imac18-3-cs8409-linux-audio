# iMac18,3 CS8409 Linux Audio Driver

A DKMS-based Linux audio driver setup for the **Apple iMac18,3 (Retina 5K, 27-inch, 2017)** with the **Cirrus Logic CS8409 / CS42L83** HDA audio codec.

This project is based on the `snd_hda_macbookpro` driver work by David Jones and the Linux kernel CS8409 driver, with Apple-specific CS8409 handling required for the iMac18,3 configuration.

The iMac18,3 is known to expose the CS8409 codec correctly under Linux while the standard driver may fail to initialize the Apple-specific audio path. Community reports also document the same CS8409 audio problem on this model.

**Current release:** [v0.2](https://github.com/jackdanyell/imac18-3-cs8409-linux-audio/releases/tag/v0.2)

## Tested Hardware

This project was developed and tested on:

| Component          | Value                               |
| ------------------ | ----------------------------------- |
| Mac model          | **iMac18,3**                        |
| Product            | **iMac (Retina 5K, 27-inch, 2017)** |
| Board              | `Mac-BE088AF8C5EB4FA2`              |
| Audio codec        | **Cirrus Logic CS8409 / CS42L83**   |
| Codec subsystem ID | `0x106b1000`                        |
| Architecture       | x86_64                              |
| Tested Linux       | Arch Linux / EndeavourOS            |
| Tested kernels     | `6.18.44-1-lts`, `7.1.8-arch1-3`    |
| DKMS module        | `snd_hda_macbookpro/0.2`            |

### Important

This repository is currently specifically tested against **iMac18,3**.

Other Apple computers may use the CS8409 codec but have different subsystem IDs, amplifier configurations, pin mappings, or initialization requirements.

Do not assume that a different Mac model is supported simply because it contains a CS8409 codec.

---

# Installation

Use this repository on an **iMac18,3**. Do **not** also install the AUR package `snd-hda-macbookpro-dkms-git`; it ships the same module under a different DKMS name and breaks kernel updates. If that package is present, `install-imac18-3.sh` removes it.

## Arch Linux / EndeavourOS

Install build tools and **headers for every kernel you actually boot**:

```bash
sudo pacman -S --needed git gcc make patch wget dkms
```

```bash
# default Arch / EndeavourOS kernel
sudo pacman -S --needed linux-headers
```

```bash
# only if linux-lts is installed and you still boot it
sudo pacman -S --needed linux-lts-headers
```

Clone and install:

```bash
git clone https://github.com/jackdanyell/imac18-3-cs8409-linux-audio.git
cd imac18-3-cs8409-linux-audio
sudo ./install-imac18-3.sh
```

The installer:

1. Confirms the machine is `iMac18,3` and that a CS8409 codec is present.
2. Removes the conflicting AUR DKMS package if it is installed.
3. Builds `snd_hda_macbookpro/0.2` for **each** kernel that has headers (`/lib/modules/<kernel>/build`).

You can keep both `linux` and `linux-lts`. After a successful install, boot either kernel; DKMS should already have a module for both.

Expected hardware check:

```text
==========================================
 iMac18,3 CS8409 Linux Audio Driver
==========================================

Detected machine : iMac18,3
Board            : Mac-BE088AF8C5EB4FA2
HDA codec        : CS8409/CS42L83

Hardware check: OK

Installing DKMS module for every kernel that has headers...
```

An extra HDMI codec such as `R6xx HDMI` is normal on AMD iMacs.

Then reboot:

```bash
sudo reboot
```

### Upgrade from 0.1

If you previously installed this repo or the AUR package:

```bash
cd imac18-3-cs8409-linux-audio
git pull
sudo ./install-imac18-3.sh
sudo reboot
```

That replaces `snd_hda_macbookpro/0.1` (and the hyphenated AUR name) with `0.2`.

## Ubuntu / Debian

```bash
sudo apt install git gcc make patch wget dkms linux-headers-$(uname -r)
git clone https://github.com/jackdanyell/imac18-3-cs8409-linux-audio.git
cd imac18-3-cs8409-linux-audio
sudo ./install-imac18-3.sh
sudo reboot
```

Fedora and Void are supported by the underlying scripts; see [Supported Distributions](#supported-distributions).

---

# Verify the Driver

After reboot, check the driver:

```bash
readlink -f /sys/bus/hdaudio/devices/hdaudioC0D0/driver
```

Expected:

```text
/sys/bus/hdaudio/drivers/snd_hda_codec_cs8409
```

Check the codec:

```bash
cat /sys/bus/hdaudio/devices/hdaudioC0D0/chip_name
```

Expected:

```text
CS8409/CS42L83
```

Check the subsystem ID:

```bash
cat /sys/bus/hdaudio/devices/hdaudioC0D0/subsystem_id
```

Expected on iMac18,3:

```text
0x106b1000
```

Check the installed module:

```bash
modinfo snd_hda_codec_cs8409 | grep -E 'filename|srcversion|vermagic'
```

The module should be located under the DKMS directory, for example:

```text
filename: /lib/modules/<kernel>/updates/dkms/snd-hda-codec-cs8409.ko.zst
```

Check DKMS:

```bash
dkms status | grep snd
```

Expected:

```text
snd_hda_macbookpro/0.2, <kernel>, x86_64: installed (Original modules exist)
```

---

# Audio Configuration

After installation, Linux should expose the analogue audio device.

For desktop audio, select:

```text
Analogue Stereo Output
```

If you need microphone input, the original driver documentation recommends:

```text
Analogue Stereo Duplex
```

The original driver documentation notes that microphone support and recording integration are less complete than playback support.

---

# What This Fix Does

The standard Linux CS8409 codec driver can detect the hardware but does not necessarily select the Apple-specific initialization path required by these machines.

The patched driver contains an Apple-specific fallback path.

The relevant logic detects when the normal CS8409 fixup is not selected:

```text
Primary patch_cs8409
Primary patch_cs8409 NOT FOUND trying APPLE
```

and then enters the Apple-specific CS8409 implementation.

For the tested iMac18,3 configuration, the Apple-specific code recognizes:

```text
0x106b1000
```

as the subsystem ID for the iMac configuration.

The working system was verified with:

```text
CS8409/CS42L83
0x106b1000
```

and the `snd_hda_codec_cs8409` driver successfully bound to the HDA codec.

---

# DKMS and Kernel Updates

The driver is installed through **DKMS**.

The DKMS configuration uses:

```text
AUTOINSTALL="yes"
```

This allows DKMS to rebuild the driver when a new kernel is installed.

After a kernel update, check:

```bash
dkms status
```

and:

```bash
modinfo snd_hda_codec_cs8409 | grep -E 'filename|vermagic'
```

If the new kernel has a compatible configuration and headers are installed, DKMS should build the module for the new kernel.

For example:

```bash
sudo dkms autoinstall
```

can be used to explicitly request DKMS to build missing modules.

Then verify:

```bash
dkms status
```

---

# Important: Kernel Compatibility

The installation script contains kernel-version-specific handling because Linux kernel HDA source code was reorganized starting with kernel 6.17.

The original project therefore contains separate handling for:

* kernels before 6.17
* kernel 6.17 and later

The current installer automatically determines the kernel version and selects the appropriate installation path.

The project has been tested on EndeavourOS with:

```text
6.18.44-1-lts
7.1.8-arch1-3
```

The installer builds for **every installed kernel that has headers**, so Arch `linux` and `linux-lts` can coexist. Boot whichever kernel you want after install.

Newer kernels than those listed should still often build (HDA sources from 6.17 onward share the same layout) but treat them as unverified until you confirm audio after reboot.

If a future kernel update causes the audio to stop working, boot the previous working kernel first and check:

```bash
uname -r
dkms status
modinfo snd_hda_codec_cs8409
```

---

# Backup

Before experimenting with kernel updates or modifying the driver, it is recommended to keep a backup of the working driver source and DKMS state.

Example:

```bash
sudo tar -czf ~/snd-hda-macbookpro-working-backup.tar.gz \
    /usr/src/snd_hda_macbookpro-0.2 \
    /var/lib/dkms/snd_hda_macbookpro \
    /etc/dkms
```

Verify the backup:

```bash
ls -lh ~/snd-hda-macbookpro-working-backup.tar.gz
```

---

# Removing the Driver

To remove the DKMS module for the current kernel:

```bash
sudo dkms remove snd_hda_macbookpro/0.2 --all
```

Then:

```bash
sudo depmod -a
```

Check:

```bash
dkms status
```

The original kernel CS8409 module should then be available again.

If DKMS reports that the module is not installed for the kernel, do not repeatedly run the remove command. Check the actual DKMS state first:

```bash
dkms status
```

---

# Manual Installation

The original driver can also be installed directly through its existing installer:

```bash
sudo ./install.cirrus.driver.sh
```

For DKMS installation:

```bash
sudo ./install.cirrus.driver.sh -i
```

For removal:

```bash
sudo ./install.cirrus.driver.sh -r
```

For iMac18,3 users, however, the recommended method is:

```bash
sudo ./install-imac18-3.sh
```

because it performs the hardware detection before starting the installation.

---

# Supported Distributions

The original driver installation scripts contain support for several Linux distributions, including:

* Arch Linux
* EndeavourOS
* Ubuntu
* Debian
* Fedora
* Void Linux

Distribution-specific kernel source and header requirements may differ.

For Arch-based systems:

```bash
sudo pacman -S --needed gcc make patch wget dkms linux-headers linux-lts-headers
```

For Ubuntu/Debian:

```bash
sudo apt install gcc make patch wget dkms linux-headers-$(uname -r)
```

Some Ubuntu configurations may additionally require the matching Linux kernel source package.

---

# Known Limitations

This project should currently be considered a **hardware-specific community driver configuration**, not a complete upstream replacement for the Linux CS8409 driver.

Known limitations inherited from the original driver include:

* microphone support may be incomplete
* internal microphone recording may require additional configuration
* headset microphone support is not fully integrated
* power management / suspend behavior is not fully tested
* the Apple audio processing is not necessarily identical to macOS
* different amplifier configurations may require different programming
* other Apple models are not automatically supported

The original driver documentation also notes that direct hardware devices such as `hw:0,0` and `plughw:0,0` may have very high output levels because they do not provide the normal volume control.

Use normal desktop audio controls unless you specifically know what you are doing.

---

# Troubleshooting

## Driver is not loaded

Check:

```bash
lsmod | grep cs8409
```

Then:

```bash
modinfo snd_hda_codec_cs8409
```

and:

```bash
sudo dmesg | grep -Ei 'cs8409|hda|audio' | tail -100
```

---

## Codec is detected but there is no sound

Check:

```bash
cat /sys/bus/hdaudio/devices/hdaudioC0D0/chip_name
cat /sys/bus/hdaudio/devices/hdaudioC0D0/subsystem_id
```

For the tested iMac18,3:

```text
CS8409/CS42L83
0x106b1000
```

Then check:

```bash
sudo dmesg | grep -Ei 'cs8409|apple|cirrus|subsystem'
```

You should see the Apple fallback path being selected, for example:

```text
snd_hda_intel: Primary cs8409
snd_hda_intel: Primary patch_cs8409 NOT FOUND trying APPLE
```

---

## DKMS does not build after a kernel update

Check the running kernel:

```bash
uname -r
```

Check installed headers.

On Arch:

```bash
pacman -Q linux-headers linux-lts-headers
```

Then:

```bash
dkms status
```

You can explicitly rebuild:

```bash
sudo dkms autoinstall
```

If the build fails, inspect:

```bash
sudo find /var/lib/dkms/snd_hda_macbookpro \
    -type f -name make.log -print
```

Then inspect the relevant log.

---

# Project Structure

Important files:

```text
.
├── dkms.conf
├── dkms.sh
├── install.cirrus.driver.sh
├── install.cirrus.driver.pre617.sh
├── install-imac18-3.sh
├── Makefile
├── README.md
├── LICENSE
├── patch_cirrus/
│   ├── cs8409.c
│   ├── cs8409.h
│   ├── cirrus_apple.h
│   ├── patch_cirrus_apple.h
│   └── ...
└── patches/
    └── ...
```

`install-imac18-3.sh` is the hardware-specific entry point for the tested iMac18,3 configuration.

`install.cirrus.driver.sh` contains the underlying kernel-source preparation, patching and DKMS installation logic.

`dkms.conf` defines the DKMS module configuration.

---

# Original Project

This repository is based on the work of:

**David Jones — `snd_hda_macbookpro`**

Original project:

https://github.com/davidjo/snd_hda_macbookpro

The original project supports a wider range of Apple machines using Cirrus CS8409 hardware.

This repository narrows the tested configuration to the:

```text
Apple iMac18,3
Retina 5K, 27-inch, 2017
CS8409 / CS42L83
```

---

# Why This Repository Exists

The goal of this repository is simple:

> Make the working iMac18,3 CS8409 Linux audio configuration easier for other owners of the same machine to reproduce.

The original CS8409 work is broader than this repository. This project documents the specific configuration that was successfully tested on an iMac18,3 running Linux.

Community reports continue to show that iMac18,3 users encounter CS8409 audio initialization problems on Linux, so reproducible hardware-specific documentation is useful for future testing and development.

---

# Testing Status

## Confirmed

* iMac18,3 hardware detection
* CS8409/CS42L83 codec detection
* subsystem ID `0x106b1000`
* DKMS installation
* `snd_hda_codec_cs8409` module loading
* CS8409 driver binding
* analogue audio playback
* persistence across reboot
* DKMS-managed installation on `6.18.44-1-lts` and `7.1.8-arch1-3`

## Not Yet Fully Verified

* internal microphone recording
* external/headset microphone
* suspend/resume
* other iMac18,x models
* other Linux distributions
* future kernel versions
* all amplifier configurations
* complete Apple-equivalent audio processing

---

# Contributing

If you have the same iMac model and the driver works, please report:

```bash
uname -r
```

```bash
cat /sys/class/dmi/id/product_name
```

```bash
cat /sys/class/dmi/id/board_name
```

```bash
cat /sys/bus/hdaudio/devices/hdaudioC0D0/chip_name
```

```bash
cat /sys/bus/hdaudio/devices/hdaudioC0D0/subsystem_id
```

and:

```bash
sudo dmesg | grep -Ei 'cs8409|apple|cirrus|audio'
```

If the driver does not work, please include the same information together with:

```bash
dkms status
```

and the relevant DKMS build log.

This information can help determine which Apple subsystem IDs and kernel versions can safely be supported.

---

# License

See [`LICENSE`](LICENSE).

The kernel-derived portions of this project retain their respective copyright and licensing information.

Please preserve the original copyright notices when modifying or redistributing the source.

Huge credit to the original snd_hda_macbookpro / CS8409 work that made this possible.

---


# :warning: Disclaimer

Use this fix at your own risk.

This project installs an out-of-tree kernel module and modifies the Linux audio driver stack. Kernel modules can potentially cause system instability, audio problems, or boot issues if something goes wrong.

The driver has been tested successfully on an iMac18,3 running EndeavourOS with kernel 6.18.43-1-lts, but it has not been tested on every hardware configuration or kernel version.

Before installing, make sure you have a working kernel available as a fallback.

I cannot guarantee that this fix will work on your system, and I am not responsible for any damage, data loss, system instability, or other problems resulting from its use.

If you’re unsure, please read the installation instructions carefully and keep a backup before proceeding.
