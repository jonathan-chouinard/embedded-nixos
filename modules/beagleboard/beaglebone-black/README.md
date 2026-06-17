# BeagleBone Black

| Spec           | Value                                   |
|----------------|-----------------------------------------|
| Architecture   | `armv7l-linux`                          |
| CPU            | TI AM335x (ARM Cortex-A8)               |
| Kernel         | BeagleBoard.org TI-patched Linux 6.6.58 |
| Device Tree    | `am335x-boneblack.dtb`                  |
| Serial Console | `ttyO0` @ 115200 baud                   |

## Overview

This module provides NixOS support for the BeagleBone Black using the official
BeagleBoard.org TI-patched kernel. The kernel includes full device tree support
for AM335x boards, PRU (Programmable Real-time Unit) support, and TI-specific
driver patches.

## Peripherals

| Peripheral | Interface           | Notes                        |
|------------|---------------------|------------------------------|
| ADC        | IIO (`iio:device*`) | 8 channels, 12-bit           |
| GPIO       | sysfs/chardev       | Full header access           |
| I2C        | `/dev/i2c-*`        | 3 buses (I2C0, I2C1, I2C2)   |
| SPI        | `/dev/spidev*`      | Multiple buses               |
| PWM        | sysfs               | Multiple channels            |
| UART       | `/dev/ttyO*`        | Multiple ports               |
| PRU        | remoteproc          | Programmable real-time units |

Most drivers are built into the kernel (`=y`) rather than as modules, so no
explicit module loading is required.

## User Groups

Add users to these groups for hardware access:

- `dialout` - Serial ports, ADC, USB gadget
- `gpio` - GPIO and PWM access
- `i2c` - I2C bus access
- `spi` - SPI bus access

## Usage

```nix
{
  imports = [ embedded-nixos.nixosModules.beaglebone-black ];
}
```

## Resources

- [BeagleBoard.org](https://beagleboard.org/black)
- [BeagleBoard Linux Kernel](https://github.com/beagleboard/linux)
- [AM335x Technical Reference Manual](https://www.ti.com/product/AM3358)
