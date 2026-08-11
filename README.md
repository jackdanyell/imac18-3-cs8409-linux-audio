# iMac18,3 CS8409 Linux Audio Driver

A DKMS-based Linux audio driver setup for the **Apple iMac18,3 (Retina 5K, 27-inch, 2017)** with the **Cirrus Logic CS8409 / CS42L83** HDA audio codec.

This project is based on the `snd_hda_macbookpro` driver work by David Jones and the Linux kernel CS8409 driver, with Apple-specific CS8409 handling required for the iMac18,3 configuration.

The iMac18,3 is known to expose the CS8409 codec correctly under Linux while the standard driver may fail to initialize the Apple-specific audio path. Community reports also document the same CS8409 audio problem on this model.

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
| Tested kernel      | `6.18.43-1-lts`                     |
| Module             | `snd-hda-codec-cs8409`              |
| Installation       | DKMS                                |

### Important

This repository is currently specifically tested against **iMac18,3**.

Other Apple computers may use the CS8409 codec but have different subsystem IDs, amplifier configurations, pin mappings, or initialization requirements.

Do not assume that a different Mac model is supported simply because it contains a CS8409 codec.

---

# Quick Installation

## 1. Install dependencies

### Arch Linux / EndeavourOS

```bash
sudo pacman -S --needed git gcc linux-headers make patch wget dkms
```

### Ubuntu / Debian

```bash
sudo apt install git gcc make patch wget dkms linux-headers-$(uname -r)
```

The original driver also supports Fedora and Void Linux. See the distribution-specific instructions below.

---

## 2. Clone this repository

```bash
git clone https://github.com/jackdanyell/imac18-3-cs8409-linux-audio.git
cd imac18-3-cs8409-linux-audio
```

---

## 3. Run the iMac18,3 installer

```bash
sudo ./install-imac18-3.sh
```

The installer performs two hardware checks before starting the DKMS installation:

1. It verifies that the machine identifies as `iMac18,3`.
2. It verifies that a CS8409 HDA codec is present.

A supported system should report something similar to:

```text
==========================================
 iMac18,3 CS8409 Linux Audio Driver
==========================================

Detected machine : iMac18,3
Board            : Mac-BE088AF8C5EB4FA2
HDA codec        : CS8409/CS42L83

Hardware check: OK

Starting DKMS installation...
```

The system may also show an additional HDMI HDA codec such as:

```text
HDA codec        : R6xx HDMI
```

This is normal on iMacs with AMD graphics.

---

## 4. Reboot

After the installation completes:

```bash
sudo reboot
```

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
snd-hda-macbookpro/0.1, <kernel>, x86_64: installed (Original modules exist)
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

The project has been tested on:

```text
6.18.43-1-lts
```

Newer kernels should be considered **untested until verified**.

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
    /usr/src/snd-hda-macbookpro-0.1 \
    /var/lib/dkms/snd-hda-macbookpro \
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
sudo dkms remove snd_hda_macbookpro/0.1 -k "$(uname -r)"
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
sudo pacman -S --needed gcc linux-headers make patch wget dkms
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
pacman -Q linux-headers
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
sudo find /var/lib/dkms/snd-hda-macbookpro \
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
* DKMS-managed installation on kernel `6.18.43-1-lts`

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

---

# Disclaimer

This is community-developed kernel driver software.

Installing an out-of-tree kernel module modifies the Linux kernel module stack and may taint the kernel.

Use at your own risk.

Always keep a working kernel available so that you can boot into it if a future kernel update causes a regression.
