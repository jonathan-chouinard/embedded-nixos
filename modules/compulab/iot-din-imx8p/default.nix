# Compulab IOT-DIN-IMX8PLUS hardware configuration
{ lib, pkgs, ... }:
let
  linuxCompulab = pkgs.callPackage ./kernel.nix { };
  installEmmc = pkgs.callPackage ../../pkgs/install-emmc.nix { };
in
{
  imports = [
    ./peripherals.nix
    ./image.nix
  ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  # Disable kernel config checks - Compulab's config doesn't have NixOS expected options
  system.requiredKernelConfig = lib.mkForce [ ];

  boot = {
    kernelPackages = pkgs.linuxPackagesFor linuxCompulab;

    initrd = {
      includeDefaultModules = lib.mkForce false;
      availableKernelModules = lib.mkForce [
        # eMMC
        "mmc_block"
        "sdhci_esdhc_imx"

        # USB
        "xhci_hcd"
        "xhci_pci"
        "xhci_plat_hcd"
        "dwc3"
        "usb_storage"
        "uas"
        "usbhid"
        "sd_mod"

        # Filesystems
        "ext4"

        # Network
        "fec"
      ];
      kernelModules = lib.mkForce [ ];
    };

    kernelParams = [
      "console=ttymxc1,115200"
      "earlycon=ec_imx6q,0x30890000,115200"
    ];

    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };

  hardware = {
    deviceTree = {
      enable = true;
      name = "compulab/iotdin-imx8p.dtb";
    };
    enableRedistributableFirmware = lib.mkForce false;
  };

  fileSystems = {
    "/" = {
      options = [ "noatime" ];
    };
    "/boot" = {
      device = "/dev/disk/by-label/FIRMWARE";
      fsType = "vfat";
    };
  };

  powerManagement = {
    enable = true;
    cpuFreqGovernor = lib.mkDefault "ondemand";
  };

  environment.systemPackages = [
    installEmmc
  ];
}
