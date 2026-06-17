# eMMC/USB image builder for IOT-DIN-IMX8PLUS
{
  config,
  pkgs,
  modulesPath,
  ...
}:
let
  # U-Boot boot script for automatic boot via bsp_bootcmd
  bootCmd = pkgs.writeText "boot.cmd" ''
    setenv ramdisk_addr_r 0x43800000
    setenv fdt_addr_r 0x43000000
    sysboot usb 0:1 any ''${scriptaddr} /extlinux/extlinux.conf
    sysboot mmc 2:1 any ''${scriptaddr} /extlinux/extlinux.conf
  '';

  bootScr = pkgs.runCommand "boot.scr" { nativeBuildInputs = [ pkgs.ubootTools ]; } ''
    mkimage -A arm64 -O linux -T script -C none -n "NixOS Boot Script" -d ${bootCmd} $out
  '';
in
{
  imports = [
    "${modulesPath}/installer/sd-card/sd-image.nix"
  ];

  image.baseName = "iot-din-imx8p";

  sdImage = {
    compressImage = true;
    firmwareSize = 256;
    firmwarePartitionOffset = 8;

    populateFirmwareCommands = ''
      # Use standard NixOS extlinux layout for upgrade compatibility
      ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./firmware

      # Add U-Boot boot script
      cp ${bootScr} firmware/boot.scr
    '';

    populateRootCommands = "";
  };
}
