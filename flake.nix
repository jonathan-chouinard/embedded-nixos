{
  description = "Embedded NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    comin = {
      url = "github:nlewo/comin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {nixpkgs, ...} @ inputs: {
    # Raspberry Pi 4 configuration
    nixosConfigurations.rpi4-device = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      specialArgs = {inherit inputs;};
      modules = [
        ./modules/hardware/rpi4.nix
        ./modules/configuration.nix
        ./modules/sd-image.nix
      ];
    };

    images.rpi4-sd = inputs.self.nixosConfigurations.rpi4-device.config.system.build.sdImage;
  };
}
