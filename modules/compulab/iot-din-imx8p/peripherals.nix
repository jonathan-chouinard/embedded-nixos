# IOT-DIN-IMX8PLUS peripheral configuration
#
# Optional hardware that may produce errors at boot if not installed:
# - MCP251xFD CAN controllers (SPI) - "Failed to detect MCP251xFD"
# - DI8O8 digital I/O modules (I2C 0x20-0x23) - "pca953x failed writing register"
# - TPM may report self-test errors
#
# See modules/hardware/iot-din-imx8p/optional-packages.txt for debugging tools.
{
  lib,
  pkgs,
  ...
}: {
  boot.kernelModules = let
    bluetooth = ["btusb" "bluetooth"];
    can = ["can" "can_raw" "flexcan" "mcp251xfd"];
    gpio = ["gpio_generic"];
    i2c = ["i2c_imx"];
    one-wire = ["w1_gpio"];
    rtc = ["rtc_abx80x"];
    serial = ["imx6_uart"];
    spi = ["spi_imx"];
    tpm = ["tpm" "tpm_tis_i2c"];
    usb = ["cdc_acm" "option" "qmi_wwan" "cdc_mbim"];
    watchdog = ["imx2_wdt"];
    wifi = ["mwifiex" "mwifiex_sdio"];
  in
    lib.flatten [bluetooth can gpio i2c one-wire rtc serial spi tpm usb watchdog wifi];

  # Configure available CAN interfaces at boot
  systemd.services.can-setup = {
    description = "Configure CAN bus interfaces";
    wantedBy = ["multi-user.target"];
    after = ["network-pre.target"];
    before = ["network.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      for iface in can0 can1 flexcan0; do
        if ${pkgs.iproute2}/bin/ip link show $iface &>/dev/null; then
          ${pkgs.iproute2}/bin/ip link set $iface type can bitrate 500000
          ${pkgs.iproute2}/bin/ip link set $iface up
        fi
      done
    '';
  };

  services.udev.extraRules = ''
    # CAN
    SUBSYSTEM=="net", KERNEL=="can*", MODE="0660", GROUP="dialout"
    SUBSYSTEM=="net", KERNEL=="flexcan*", MODE="0660", GROUP="dialout"

    # Serial (RS485/RS232)
    SUBSYSTEM=="tty", KERNEL=="ttymxc*", MODE="0660", GROUP="dialout"

    # Cellular modem
    SUBSYSTEM=="tty", KERNEL=="ttyUSB*", MODE="0660", GROUP="dialout"
    SUBSYSTEM=="net", KERNEL=="wwan*", MODE="0660", GROUP="networkmanager"

    # GPIO
    SUBSYSTEM=="gpio", MODE="0660", GROUP="gpio"

    # TPM
    SUBSYSTEM=="tpm", MODE="0660", GROUP="tss"

    # 1-Wire
    SUBSYSTEM=="w1*", MODE="0660", GROUP="dialout"
  '';

  users.groups.gpio = {};
}
