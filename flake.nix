{
  description = "NixOS hardware support for embedded devices";

  inputs = {
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = {nixos-hardware, ...}: {
    nixosModules = {
      compulab-iot-din-imx8p = ./modules/compulab/iot-din-imx8p;
      rpi4 = {
        imports = [
          nixos-hardware.nixosModules.raspberry-pi-4
          ./modules/rpi4
        ];
      };
    };
  };
}
