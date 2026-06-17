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
}:
let
  version = "6.6.52";
  modDirVersion = version;

  src = fetchFromGitHub {
    owner = "compulab-yokneam";
    repo = "linux-compulab";
    rev = "b78b36c033a5095df9c46b119dfbec5a1e9033ad";
    hash = "sha256-KI5TpFUegz1vvz7wi214LrsGfq8BJOIgZHredcJRB1Q=";
  };

  # Generate kernel config by running make defconfig
  # This creates a proper .config from Compulab's i.MX93 defconfig
  configfile = stdenv.mkDerivation {
    name = "linux-compulab-mx93-config-${version}";
    inherit src;

    depsBuildBuild = [ stdenv.cc ];
    nativeBuildInputs = [
      flex
      bison
      bc
      perl
      openssl
      elfutils
    ];

    buildPhase = ''
      # Generate config from Compulab's i.MX93 defconfig
      make ARCH=arm64 compulab-mx93_defconfig

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

      # Netfilter modules for NixOS firewall
      # (compulab-mx93_defconfig has most netfilter support but missing these)
      ./scripts/config --module CONFIG_NETFILTER_XT_MATCH_PKTTYPE
      ./scripts/config --module CONFIG_NETFILTER_XT_MATCH_LIMIT
      ./scripts/config --module CONFIG_NETFILTER_XT_MATCH_MULTIPORT
      ./scripts/config --module CONFIG_NETFILTER_XT_MATCH_COMMENT
      ./scripts/config --module CONFIG_NFT_LOG
      ./scripts/config --module CONFIG_NFT_LIMIT
      ./scripts/config --module CONFIG_NFT_REJECT
      ./scripts/config --module CONFIG_NFT_COUNTER

      # Refresh config to resolve dependencies
      make ARCH=arm64 olddefconfig
    '';

    installPhase = ''
      cp .config $out
    '';
  };
in
linuxManualConfig {
  inherit
    version
    modDirVersion
    src
    configfile
    ;

  # Allow evaluation-time import of config
  allowImportFromDerivation = true;

  extraMeta = {
    branch = "6.6";
    platforms = [ "aarch64-linux" ];
  };
}
