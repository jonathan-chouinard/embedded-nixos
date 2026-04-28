# eMMC/USB image builder for IOT-DIN-IMX8PLUS
{
  config,
  pkgs,
  modulesPath,
  ...
}: let
  # U-Boot boot script for automatic boot via bsp_bootcmd
  # Uses standard Compulab memory addresses
  # Tries USB first (development/recovery), then eMMC (production)
  bootCmd = pkgs.writeText "boot.cmd" ''
    setenv ramdisk_addr_r 0x43800000
    setenv fdt_addr_r 0x43000000
    sysboot usb 0:1 any ''${scriptaddr} /extlinux/extlinux.conf
    sysboot mmc 2:1 any ''${scriptaddr} /extlinux/extlinux.conf
  '';

  bootScr =
    pkgs.runCommand "boot.scr" {
      nativeBuildInputs = [pkgs.ubootTools];
    } ''
      mkimage -A arm64 -O linux -T script -C none -n "NixOS Boot Script" -d ${bootCmd} $out
    '';

  extlinuxConf = pkgs.writeText "extlinux.conf" ''
    TIMEOUT 30
    DEFAULT nixos

    LABEL nixos
        MENU LABEL NixOS
        LINUX /Image
        INITRD /initrd
        FDT /dtbs/compulab/iotdin-imx8p.dtb
        APPEND init=${config.system.build.toplevel}/init root=LABEL=NIXOS_SD rootfstype=ext4 rootwait ${toString config.boot.kernelParams}
  '';
in {
  imports = [
    "${modulesPath}/installer/sd-card/sd-image.nix"
  ];

  image.baseName = "iot-din-imx8p";

  sdImage = {
    compressImage = false;
    firmwareSize = 256;
    firmwarePartitionOffset = 8;

    populateFirmwareCommands = ''
      mkdir -p firmware/extlinux
      cp ${extlinuxConf} firmware/extlinux/extlinux.conf
      cp ${bootScr} firmware/boot.scr
      cp ${config.boot.kernelPackages.kernel}/Image firmware/Image
      cp ${config.system.build.initialRamdisk}/initrd firmware/initrd
      mkdir -p firmware/dtbs/compulab
      cp -r ${config.boot.kernelPackages.kernel}/dtbs/compulab/* firmware/dtbs/compulab/
    '';

    populateRootCommands = "";
  };
}
