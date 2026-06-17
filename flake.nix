{
  description = "NixOS hardware support for embedded devices";

  inputs = {
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = { nixos-hardware, ... }: {
    nixosModules = {
      beaglebone-black = ./modules/beagleboard/beaglebone-black;
      rpi4 = {
        imports = [
          nixos-hardware.nixosModules.raspberry-pi-4
          ./modules/raspberry-pi/rpi4
        ];
      };
    };
  };
}
