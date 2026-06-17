# Compulab IOT-DIN-IMX8PLUS

| Spec           | Value                          |
|----------------|--------------------------------|
| Architecture   | `aarch64-linux`                |
| CPU            | NXP i.MX8M Plus                |
| Kernel         | Compulab linux-compulab 6.6.52 |
| Device Tree    | `compulab/iotdin-imx8p.dtb`    |
| Serial Console | `ttymxc1` @ 115200 baud        |
| Early Console  | `ec_imx6q,0x30890000,115200`   |

## Overview

This module provides NixOS support for the Compulab IOT-DIN-IMX8PLUS industrial
IoT gateway using Compulab's BSP kernel.

## Peripherals

| Peripheral  | Driver             | Device             | Notes                               |
|------------ |--------------------|--------------------|-------------------------------------|
| CAN         | flexcan, mcp251xfd | `can*`             | FlexCAN + SPI MCP251xFD controllers |
| RS485/RS232 | imx6_uart          | `ttymxc*`          | Serial ports                        |
| WiFi        | mwifiex_sdio       | `wlan*`            | SDIO WiFi                           |
| Bluetooth   | btusb              | `hci*`             | USB Bluetooth                       |
| GPIO        | gpio_generic       | sysfs/chardev      | Digital I/O                         |
| I2C         | i2c_imx            | `/dev/i2c-*`       | Multiple buses                      |
| SPI         | spi_imx            | `/dev/spidev*`     | Multiple buses                      |
| TPM         | tpm_tis_i2c        | `/dev/tpm*`        | TPM 2.0 on I2C                      |
| RTC         | rtc_abx80x         | `/dev/rtc*`        | External RTC                        |
| 1-Wire      | w1_gpio            | `/sys/bus/w1`      | GPIO 1-Wire                         |
| Cellular    | qmi_wwan, cdc_mbim | `wwan*`, `ttyUSB*` | Optional modem                      |
| Watchdog    | imx2_wdt           | `/dev/watchdog`    | i.MX watchdog                       |

## Optional Hardware Notes

Some peripherals are optional and may produce errors at boot if not installed:

- **MCP251xFD CAN controllers** - "Failed to detect MCP251xFD"
- **DI8O8 digital I/O modules** (I2C 0x20-0x23) - "pca953x failed writing register"
- **TPM** - May report self-test errors

These messages are harmless if the hardware is not present.

## User Groups

Add users to these groups for hardware access:

- `dialout` - Serial, CAN, 1-Wire
- `gpio` - GPIO access
- `tss` - TPM access
- `networkmanager` - Cellular modem

## Usage

```nix
{
  imports = [ embedded-nixos.nixosModules.compulab-iot-din-imx8p ];
}
```

## Resources

- [Compulab IOT-DIN-IMX8PLUS](https://www.compulab.com/products/iot-gateways/iot-din-imx8plus-industrial-din-rail-iot-gateway/)
- [Compulab Linux Kernel](https://github.com/compulab-yokneam/linux-compulab)
