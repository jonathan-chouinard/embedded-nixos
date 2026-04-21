# embedded-nixos

NixOS hardware support for embedded devices.

## Supported Devices

| Device           | SoC             | Description                         |
|------------------|-----------------|-------------------------------------|

All modules provide SD/eMMC image generation.
Devices with eMMC storage include a `nixos-install-emmc` tool for flashing to internal eMMC.

## Usage

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    embedded-nixos.url = "github:jonathan-chouinard/embedded-nixos";
  };

  outputs = { nixpkgs, embedded-nixos, ... }: {
    nixosConfigurations.my-device = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        embedded-nixos.nixosModules.rpi4
        ./configuration.nix
      ];
    };

    packages.aarch64-linux.image =
      self.nixosConfigurations.my-device.config.system.build.sdImage;
  };
}
```

## Building an Image

```bash
nix build .#nixosConfigurations.my-device.config.system.build.sdImage
```

The image will be at `result/sd-image/*.img`.
