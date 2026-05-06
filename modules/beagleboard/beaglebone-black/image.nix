# SD card image builder for BeagleBone Black
#
# Creates a bootable SD card image following BeagleBone boot conventions:
# - Small FAT32 partition 1 (placeholder, U-Boot expects 2 partitions)
# - ext4 root partition 2 with NixOS and /boot directory
#
# The BBB U-Boot loads /boot/uEnv.txt and uses uname_r to find:
# - /boot/vmlinuz-${uname_r}
# - /boot/initrd.img-${uname_r}
# - /boot/dtbs/${uname_r}/${fdtfile}
{
  config,
  pkgs,
  modulesPath,
  ...
}: let
  kernelPath = "${config.boot.kernelPackages.kernel}";
  initrdPath = "${config.system.build.initialRamdisk}/initrd";
  toplevel = "${config.system.build.toplevel}";

  # BeagleBone U-Boot uEnv.txt format
  # Following the standard BBB boot convention
  uEnvTxt = pkgs.writeText "uEnv.txt" ''
    # NixOS uEnv.txt for BeagleBone Black
    # Following BeagleBone boot conventions

    # Kernel version identifier - U-Boot uses this to find boot files
    uname_r=nixos

    # Boot arguments
    cmdline=init=${toplevel}/init root=LABEL=NIXOS_SD rootfstype=ext4 rootwait console=ttyO0,115200n8

    # Disable video overlay (headless server)
    disable_uboot_overlay_video=1
    disable_uboot_overlay_audio=1
  '';
in {
  imports = [
    "${modulesPath}/installer/sd-card/sd-image.nix"
  ];

  image.baseName = "beaglebone-black";

  sdImage = {
    compressImage = false;
    # Small FAT partition to maintain partition numbering (U-Boot expects p2 for root)
    firmwareSize = 32;
    # Leave space at start for potential U-Boot installation
    firmwarePartitionOffset = 4;

    # Empty firmware partition - just a placeholder
    populateFirmwareCommands = "";

    # Put boot files on root partition following BBB conventions
    populateRootCommands = ''
      mkdir -p ./files/boot/dtbs/nixos

      # Copy uEnv.txt
      cp ${uEnvTxt} ./files/boot/uEnv.txt

      # Kernel: /boot/vmlinuz-nixos
      cp ${kernelPath}/zImage ./files/boot/vmlinuz-nixos

      # Initrd: /boot/initrd.img-nixos
      cp ${initrdPath} ./files/boot/initrd.img-nixos

      # Device tree: /boot/dtbs/nixos/am335x-boneblack.dtb
      cp ${kernelPath}/dtbs/am335x-boneblack.dtb ./files/boot/dtbs/nixos/am335x-boneblack.dtb
    '';
  };
}
