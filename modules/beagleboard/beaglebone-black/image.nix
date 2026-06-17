# SD card image builder for BeagleBone Black
{
  config,
  pkgs,
  modulesPath,
  ...
}:
let
  # U-Boot boot script for BeagleBone Black
  # Uses sysboot to load extlinux.conf from partition 2 (root)
  bootCmd = pkgs.writeText "boot.cmd" ''
    setenv fdt_addr_r 0x88000000
    setenv ramdisk_addr_r 0x88080000
    sysboot mmc 0:2 any ''${scriptaddr} /boot/extlinux/extlinux.conf
  '';

  bootScr = pkgs.runCommand "boot.scr" { nativeBuildInputs = [ pkgs.ubootTools ]; } ''
    mkimage -A arm -O linux -T script -C none -n "NixOS Boot Script" -d ${bootCmd} $out
  '';
in
{
  imports = [
    "${modulesPath}/installer/sd-card/sd-image.nix"
  ];

  image.baseName = "beaglebone-black";

  sdImage = {
    compressImage = true;
    firmwareSize = 32;
    firmwarePartitionOffset = 4;

    populateFirmwareCommands = ''
      # U-Boot boot script on FAT partition
      cp ${bootScr} firmware/boot.scr
    '';

    populateRootCommands = ''
      # Use standard NixOS extlinux layout for upgrade compatibility
      ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
    '';
  };
}
