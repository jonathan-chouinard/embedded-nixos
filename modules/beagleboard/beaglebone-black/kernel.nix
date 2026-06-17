{
  buildPackages,
  linuxManualConfig,
  fetchFromGitHub,
  ...
}:
let
  version = "6.6.58";
  modDirVersion = version;

  src = fetchFromGitHub {
    owner = "beagleboard";
    repo = "linux";
    rev = "3d519995234675748a38b1e3bc087baa03e3ac25"; # v6.6.58-ti-arm32-r12 branch
    hash = "sha256-nvG6/v0oXsTlhOjALENMkaXSbNolZrp/AHi7jAAaQ+s=";
  };

  configfile = buildPackages.stdenv.mkDerivation {
    name = "linux-beagleboard-config-${version}";
    inherit src;

    nativeBuildInputs = with buildPackages; [
      flex
      bison
      bc
      perl
      openssl
      elfutils
    ];

    buildPhase = ''
      # Generate config from BeagleBoard.org's defconfig
      make ARCH=arm bb.org_defconfig

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

      # GPIO sysfs for debugging
      ./scripts/config --enable CONFIG_GPIO_SYSFS

      # Disable EFI (not applicable to ARM embedded)
      ./scripts/config --disable CONFIG_EFI

      # Refresh config to resolve dependencies
      make ARCH=arm olddefconfig
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
    platforms = [ "armv7l-linux" ];
  };
}
