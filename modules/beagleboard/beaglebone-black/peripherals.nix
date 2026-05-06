# BeagleBone Black peripheral configuration
#
# Configures BBB-specific hardware permissions for:
# - ADC (8 channels, 12-bit)
# - GPIO
# - I2C buses (I2C0, I2C1, I2C2)
# - SPI buses
# - PWM
# - UART
#
# Note: All essential drivers (ADC, GPIO, I2C, SPI, PWM, UART, USB, Ethernet,
# Watchdog, RTC, Crypto, eMMC/SD) are built into the kernel (=y) by
# bb.org_defconfig, so no kernel modules need to be loaded.
{
  services.udev.extraRules = ''
    # Serial (UART)
    SUBSYSTEM=="tty", KERNEL=="ttyO*", MODE="0660", GROUP="dialout"
    SUBSYSTEM=="tty", KERNEL=="ttyS*", MODE="0660", GROUP="dialout"

    # GPIO - allow gpio group access
    SUBSYSTEM=="gpio", MODE="0660", GROUP="gpio"
    KERNEL=="gpiochip*", SUBSYSTEM=="gpio", MODE="0660", GROUP="gpio"

    # ADC - IIO subsystem
    SUBSYSTEM=="iio", MODE="0660", GROUP="dialout"
    KERNEL=="iio:device*", SUBSYSTEM=="iio", MODE="0660", GROUP="dialout"

    # PWM
    SUBSYSTEM=="pwm", MODE="0660", GROUP="gpio"

    # I2C
    SUBSYSTEM=="i2c-dev", MODE="0660", GROUP="i2c"

    # SPI
    SUBSYSTEM=="spidev", MODE="0660", GROUP="spi"

    # USB gadget
    SUBSYSTEM=="udc", MODE="0660", GROUP="dialout"
  '';

  # Create necessary groups for hardware access
  users.groups = {
    gpio = {};
    i2c = {};
    spi = {};
  };
}
