# SD/USB image builder for IOT-LINK (i.MX93)
{
  config,
  pkgs,
  modulesPath,
  ...
}:
let
  # U-Boot boot script for i.MX93
  bootCmd = pkgs.writeText "boot.cmd" ''
    setenv fdt_addr_r 0x83000000
    setenv ramdisk_addr_r 0x83800000
    sysboot usb 0:1 any ''${scriptaddr} /extlinux/extlinux.conf
    sysboot mmc 0:1 any ''${scriptaddr} /extlinux/extlinux.conf
  '';

  bootScr = pkgs.runCommand "boot.scr" { nativeBuildInputs = [ pkgs.ubootTools ]; } ''
    mkimage -A arm64 -O linux -T script -C none -n "NixOS Boot Script" -d ${bootCmd} $out
  '';
in
{
  imports = [
    "${modulesPath}/installer/sd-card/sd-image.nix"
  ];

  image.baseName = "iot-link";

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
