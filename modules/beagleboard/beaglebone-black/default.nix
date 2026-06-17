# BeagleBone Black hardware configuration
{ lib, pkgs, ... }:
let
  linuxBeagleBone = pkgs.callPackage ./kernel.nix { };
  installEmmc = pkgs.callPackage ../../pkgs/install-emmc.nix { };
in
{
  imports = [
    ./peripherals.nix
    ./image.nix
  ];

  nixpkgs.hostPlatform = lib.mkDefault "armv7l-linux";

  # Disable kernel config checks - BeagleBoard's config may not have all NixOS expected options
  system.requiredKernelConfig = lib.mkForce [ ];

  boot = {
    kernelPackages = pkgs.linuxPackagesFor linuxBeagleBone;

    initrd = {
      # BeagleBoard's bb.org_defconfig builds most drivers as built-in (=y),
      # not modules (=m). Setting availableKernelModules to empty avoids
      # "module not found" errors for drivers that are compiled into the kernel.
      includeDefaultModules = lib.mkForce false;
      availableKernelModules = lib.mkForce [ ];
      kernelModules = lib.mkForce [ ];
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

  fileSystems = {
    "/".options = [ "noatime" ];
  };

  powerManagement = {
    enable = true;
    cpuFreqGovernor = lib.mkDefault "ondemand";
  };

  environment.systemPackages = [
    installEmmc
  ];
}
