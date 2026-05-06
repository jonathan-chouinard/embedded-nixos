# BeagleBone Black hardware configuration
{
  lib,
  pkgs,
  ...
}: let
  linuxBeagleBone = pkgs.callPackage ./kernel.nix {};

  # eMMC installation script with runtime dependencies
  installEmmc = pkgs.writeShellApplication {
    name = "nixos-install-emmc";
    runtimeInputs = with pkgs; [
      rsync
      dosfstools # mkfs.vfat
      e2fsprogs # mkfs.ext4
      util-linux # findmnt, sfdisk, mount, umount
      parted # partprobe
      coreutils # dd, sed, sync, mkdir, rmdir, sleep
    ];
    text = builtins.readFile ./install-emmc.sh;
  };
in {
  imports = [
    ./peripherals.nix
    ./image.nix
  ];

  nixpkgs.hostPlatform = lib.mkDefault "armv7l-linux";

  # Disable kernel config checks - BeagleBoard's config may not have all NixOS expected options
  system.requiredKernelConfig = lib.mkForce [];

  boot = {
    kernelPackages = pkgs.linuxPackagesFor linuxBeagleBone;

    initrd = {
      # BeagleBoard's bb.org_defconfig builds most drivers as built-in (=y),
      # not modules (=m). Setting availableKernelModules to empty avoids
      # "module not found" errors for drivers that are compiled into the kernel.
      includeDefaultModules = lib.mkForce false;
      availableKernelModules = lib.mkForce [];
      kernelModules = lib.mkForce [];
    };

    kernelParams = [
      "console=ttyO0,115200n8"
      "earlyprintk"
    ];

    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };

  hardware = {
    deviceTree = {
      enable = true;
      name = "am335x-boneblack.dtb";
    };
    enableRedistributableFirmware = lib.mkForce false;
  };

  fileSystems."/".options = ["noatime"];

  powerManagement = {
    enable = true;
    cpuFreqGovernor = lib.mkDefault "ondemand";
  };

  # Include eMMC installation tool
  environment.systemPackages = [installEmmc];
}
