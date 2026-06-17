# Raspberry Pi 4

| Spec           | Value                         |
|----------------|-------------------------------|
| Architecture   | `aarch64-linux`               |
| Kernel         | Upstream (via nixos-hardware) |
| Device Tree    | Provided by nixos-hardware    |
| Serial Console | N/A (HDMI/USB default)        |

## Overview

This module provides NixOS support for the Raspberry Pi 4. It builds on top of
`nixos-hardware.nixosModules.raspberry-pi-4` which provides the kernel, device
tree, and firmware.

## Custom Configuration

- Minimal initrd modules (xhci_pci, usbhid, usb_storage, mmc_block)
- Disabled redistributable firmware to reduce image size (~900MB savings)
- Filesystem labels: `NIXOS_SD` (root), `FIRMWARE` (boot)

## Usage

```nix
{
  imports = [ embedded-nixos.nixosModules.rpi4 ];
}
```

## Resources

- [Raspberry Pi Documentation](https://www.raspberrypi.com/documentation/)
- [nixos-hardware raspberry-pi-4](https://github.com/NixOS/nixos-hardware/tree/master/raspberry-pi/4)
