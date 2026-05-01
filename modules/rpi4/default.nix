# Raspberry Pi 4 hardware configuration
{lib, ...}: {
  imports = [
    ./image.nix
  ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  # Override nixos-hardware's initrd modules to avoid dw-hdmi error from vc4
  boot.initrd.availableKernelModules = lib.mkForce [
    "xhci_pci"
    "usbhid"
    "usb_storage"
    "mmc_block"
  ];

  # Disable heavy linux-firmware package (~900MB)
  hardware.enableRedistributableFirmware = lib.mkForce false;

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = ["noatime"];
    };

    "/boot/firmware" = {
      device = "/dev/disk/by-label/FIRMWARE";
      fsType = "vfat";
      options = ["nofail" "noauto"];
    };
  };
}
