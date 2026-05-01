# embedded-nixos

NixOS hardware support for embedded devices.

## Supported Devices

- **iot-din-imx8p** - Compulab IOT-DIN-IMX8PLUS
- **rpi4** - Raspberry Pi 4

## Usage

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    embedded-nixos.url = "github:jonathan-chouinard/embedded-nixos";
  };

  outputs = { nixpkgs, embedded-nixos, ... }: {
    nixosConfigurations.my-device = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        embedded-nixos.nixosModules.iot-din-imx8p
        ./configuration.nix
      ];
    };

    packages.aarch64-linux.image =
      self.nixosConfigurations.my-device.config.system.build.sdImage;
  };
}
```

## What's Included

### iot-din-imx8p

- Compulab kernel 6.6.52 with device tree
- Boot configuration (extlinux + boot.scr for U-Boot)
- initrd with eMMC, USB, and network drivers
- Peripheral support (CAN, serial, GPIO)
- SD/eMMC image generation
- `nixos-install-emmc` tool for flashing to internal eMMC

### rpi4

- nixos-hardware Raspberry Pi 4 support
- SD image generation

## Building an Image

```bash
nix build .#nixosConfigurations.my-device.config.system.build.sdImage
```

The image will be at `result/sd-image/*.img`.
