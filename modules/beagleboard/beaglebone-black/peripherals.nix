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
    gpio = { };
    i2c = { };
    spi = { };
  };
}
