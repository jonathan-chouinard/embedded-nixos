# Compulab IOT-LINK

| Spec           | Value                                           |
|----------------|-------------------------------------------------|
| Architecture   | `aarch64-linux`                                 |
| CPU            | NXP i.MX9352 (dual-core ARM Cortex-A55, 1.7GHz) |
| RAM            | 1GB - 2GB LPDDR4                                |
| Storage        | 16GB - 64GB eMMC                                |
| Kernel         | Compulab linux-compulab 6.6.52                  |
| Device Tree    | `compulab/iot-link.dtb`                         |
| Serial Console | `ttyLP0` @ 115200 baud                          |
| Early Console  | `imx_lpuart,0x44380000,115200`                  |

## Overview

This module provides NixOS support for the Compulab IOT-LINK industrial IoT
gateway based on the NXP i.MX93 SoC.

## Peripherals

| Peripheral    | Driver             | Device             | Notes                                                   |
|---------------|--------------------|--------------------|---------------------------------------------------------|
| CAN-FD        | flexcan            | `can0`, `can1`     | i.MX93 FlexCAN (optional, ordered as FACAN/FBCAN)       |
| RS485         | fsl_lpuart         | `ttyLP4`, `ttyLP6` | LPUART with MAX13488 (optional, ordered as FARS4/FBRS4) |
| WiFi 6        | mlan, moal         | `wlan*`            | NXP IW611 (optional)                                    |
| Bluetooth 5.4 | btnxpuart          | `hci*`             | NXP IW611 (optional)                                    |
| Ethernet      | fec                | `eth*`             | 1x GbE                                                  |
| GPIO          | gpio_generic       | sysfs/chardev      | Digital I/O (optional)                                  |
| I2C           | i2c_imx_lpi2c      | `/dev/i2c-*`       | i.MX93 LPI2C                                            |
| SPI           | spi_fsl_lpspi      | `/dev/spidev*`     | i.MX93 LPSPI                                            |
| TPM 2.0       | tpm_tis_i2c        | `/dev/tpm*`        | Infineon SLB9673 on I2C                                 |
| RTC           | rtc_abx80x         | `/dev/rtc*`        | AM1805 + i.MX93 internal                                |
| Cellular      | qmi_wwan, cdc_mbim | `wwan*`, `ttyUSB*` | SIMCOM SIM7672 or Telit LE910 (optional)                |
| Wireless Mesh | -                  | -                  | Nordic nRF52840 / Silicon Labs MGM240 (optional)        |
| Watchdog      | imx2_wdt           | `/dev/watchdog`    | i.MX93 watchdog                                         |

**Note:** CAN and RS485 are mutually exclusive on each port (A/B).

## User Groups

Add users to these groups for hardware access:

- `dialout` - Serial, CAN, LEDs
- `gpio` - GPIO access
- `tss` - TPM access
- `networkmanager` - Cellular modem

## Usage

```nix
{
  imports = [ embedded-nixos.nixosModules.compulab-iot-link ];
}
```

## Resources

- [Compulab IOT-LINK Product Page](https://www.compulab.com/products/iot-gateways/iot-link-industrial-iot-gateway/)
- [Compulab Linux Kernel](https://github.com/compulab-yokneam/linux-compulab)
