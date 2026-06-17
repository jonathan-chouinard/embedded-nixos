{
  lib,
  pkgs,
  ...
}:
{
  boot.kernelModules =
    let
      bluetooth = [
        "btnxpuart"
        "bluetooth"
        "btusb"
      ];
      can = [
        "can"
        "can_raw"
        "flexcan"
      ];
      gpio = [ "gpio_generic" ];
      i2c = [ "i2c_imx_lpi2c" ];
      rtc = [ "rtc_abx80x" ];
      serial = [ "fsl_lpuart" ];
      spi = [ "spi_fsl_lpspi" ];
      tpm = [
        "tpm"
        "tpm_tis_i2c"
      ];
      usb = [
        "cdc_acm"
        "option"
        "qmi_wwan"
        "cdc_mbim"
        "cdc_ether"
      ];
      watchdog = [ "imx2_wdt" ];
      wifi = [
        "mlan"
        "moal"
      ];
      ethernet = [ "fec" ];
    in
    lib.flatten [
      bluetooth
      can
      gpio
      i2c
      rtc
      serial
      spi
      tpm
      usb
      watchdog
      wifi
      ethernet
    ];

  # Configure available CAN interfaces at boot
  # IOT-LINK can have up to 2 CAN ports (can0/can1) depending on configuration
  systemd.services.can-setup = {
    description = "Configure CAN bus interfaces";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-pre.target" ];
    before = [ "network.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      for iface in can0 can1; do
        if ${pkgs.iproute2}/bin/ip link show $iface &>/dev/null; then
          ${pkgs.iproute2}/bin/ip link set $iface type can bitrate 500000
          ${pkgs.iproute2}/bin/ip link set $iface up
        fi
      done
    '';
  };

  services.udev.extraRules = ''
    # CAN interfaces
    SUBSYSTEM=="net", KERNEL=="can*", MODE="0660", GROUP="dialout"

    # Serial ports - i.MX93 uses LPUART (ttyLP*)
    # RS485 Port A: ttyLP6, RS485 Port B: ttyLP4
    SUBSYSTEM=="tty", KERNEL=="ttyLP*", MODE="0660", GROUP="dialout"

    # Cellular modem
    SUBSYSTEM=="tty", KERNEL=="ttyUSB*", MODE="0660", GROUP="dialout"
    SUBSYSTEM=="tty", KERNEL=="ttyACM*", MODE="0660", GROUP="dialout"
    SUBSYSTEM=="net", KERNEL=="wwan*", MODE="0660", GROUP="networkmanager"

    # GPIO - Digital I/O pins
    SUBSYSTEM=="gpio", MODE="0660", GROUP="gpio"

    # TPM
    SUBSYSTEM=="tpm", MODE="0660", GROUP="tss"

    # LEDs
    SUBSYSTEM=="leds", MODE="0660", GROUP="dialout"
  '';

  users.groups.gpio = { };
}
