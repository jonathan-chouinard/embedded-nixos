# Compulab Linux Kernel for IOT-DIN-IMX8PLUS
#
# This packages Compulab's linux-compulab kernel which includes:
# - Full device tree support for IOT-DIN-IMX8PLUS
# - Proper USB3/DWC3 driver support
# - All peripheral drivers (CAN, RS485, modem, WiFi, GPIO, GPS, TPM)
#
# Based on kernel version 6.6.52 from Compulab's BSP
#
# Uses linuxManualConfig for full control over kernel config,
# bypassing NixOS's common-config.nix which adds x86-specific options.
{
  stdenv,
  linuxManualConfig,
  fetchFromGitHub,
  flex,
  bison,
  bc,
  perl,
  openssl,
  elfutils,
  ...
}: let
  version = "6.6.52";
  modDirVersion = version;

  src = fetchFromGitHub {
    owner = "compulab-yokneam";
    repo = "linux-compulab";
    rev = "linux-compulab_v${version}";
    hash = "sha256-ML0+HLygVg+ZZzynCaf3Idbyr7swdwY8cy2PlYks/O8=";
  };

  # Generate kernel config by running make defconfig
  # This creates a proper .config from Compulab's defconfig
  configfile = stdenv.mkDerivation {
    name = "linux-compulab-config-${version}";
    inherit src;

    depsBuildBuild = [stdenv.cc];
    nativeBuildInputs = [
      flex
      bison
      bc
      perl
      openssl
      elfutils
    ];

    buildPhase = ''
      # Generate config from Compulab's defconfig
      make ARCH=arm64 compulab_v8_defconfig

      # Fix shebang in config script
      patchShebangs scripts/config

      # Apply additional settings for NixOS compatibility
      # Ensure required options for systemd/NixOS are enabled
      ./scripts/config --enable CONFIG_CGROUPS
      ./scripts/config --enable CONFIG_INOTIFY_USER
      ./scripts/config --enable CONFIG_SIGNALFD
      ./scripts/config --enable CONFIG_TIMERFD
      ./scripts/config --enable CONFIG_EPOLL
      ./scripts/config --enable CONFIG_UNIX
      ./scripts/config --enable CONFIG_SYSFS
      ./scripts/config --enable CONFIG_PROC_FS
      ./scripts/config --enable CONFIG_FHANDLE
      ./scripts/config --enable CONFIG_AUTOFS_FS
      ./scripts/config --enable CONFIG_TMPFS_POSIX_ACL
      ./scripts/config --enable CONFIG_TMPFS_XATTR
      ./scripts/config --enable CONFIG_SECCOMP

      # Ensure ext4 and USB storage for boot
      ./scripts/config --enable CONFIG_EXT4_FS
      ./scripts/config --enable CONFIG_USB_STORAGE
      ./scripts/config --enable CONFIG_USB_UAS

      # GPIO sysfs for debugging
      ./scripts/config --enable CONFIG_GPIO_SYSFS

      # Disable EFI (not applicable to ARM embedded)
      ./scripts/config --disable CONFIG_EFI

      # Refresh config to resolve dependencies
      make ARCH=arm64 olddefconfig
    '';

    installPhase = ''
      cp .config $out
    '';
  };
in
  linuxManualConfig {
    inherit version modDirVersion src configfile;

    # Allow evaluation-time import of config
    allowImportFromDerivation = true;

    extraMeta = {
      branch = "6.6";
      platforms = ["aarch64-linux"];
    };
  }
