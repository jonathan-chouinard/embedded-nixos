{modulesPath, ...}: {
  imports = [
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
  ];

  image.baseName = "rpi4";
  sdImage.compressImage = false;
}
