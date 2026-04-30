# NixOS eMMC installation script for IOT-DIN-IMX8PLUS
# Copies the running system from USB to internal eMMC using rsync.

USB="/dev/sda"
EMMC="/dev/mmcblk2"

check_devices() {
    if [[ ! -b "$USB" ]]; then
        echo "Error: Source device $USB not found"
        exit 1
    fi
    
    local root_dev
    root_dev=$(findmnt -n -o SOURCE /)
    if [[ "$root_dev" == "${EMMC}"* ]]; then
        echo "Error: Already running from eMMC"
        exit 1
    fi
}

confirm() {
    echo "Install NixOS from $USB to $EMMC"
    echo "WARNING: This will ERASE ALL DATA on $EMMC"
    read -r -p "Continue? (yes/no): " response
    [[ "$response" == "yes" ]] || exit 0
}

copy_partition_table() {
    echo "Copying partition table..."
    umount "${EMMC}"* 2>/dev/null || true
    dd if=/dev/zero of="$EMMC" bs=1M count=1 status=none
    
    # Copy table with open-ended last partition (fills available space)
    sfdisk --dump "$USB" | sed '$ d;/last-lba/d;' | sfdisk "$EMMC"
    local last_start
    last_start=$(sfdisk --dump "$USB" | tail -1 | sed -n 's/.*start=\s*\([0-9]*\).*/\1/p')
    echo "${last_start},+" | sfdisk "$EMMC" --append
    
    partprobe "$EMMC"
    sleep 1
}

format_partitions() {
    echo "Formatting partitions..."
    mkfs.vfat -n FIRMWARE "${EMMC}p1"
    mkfs.ext4 -F -L NIXOS_SD "${EMMC}p2"
}

sync_boot() {
    echo "Syncing boot partition..."
    mount -o ro "${USB}1" /tmp/emmc-src
    mount "${EMMC}p1" /tmp/emmc-dst
    rsync -rltD --info=progress2 /tmp/emmc-src/ /tmp/emmc-dst/
    umount /tmp/emmc-dst
    umount /tmp/emmc-src
}

sync_root() {
    echo "Syncing root partition..."
    mount --bind / /tmp/emmc-src
    mount "${EMMC}p2" /tmp/emmc-dst
    rsync -aHAX --info=progress2 \
        --exclude=/dev --exclude=/proc --exclude=/sys --exclude=/tmp \
        --exclude=/run --exclude=/mnt --exclude=/media --exclude=/lost+found \
        /tmp/emmc-src/ /tmp/emmc-dst/
    umount /tmp/emmc-dst
    umount /tmp/emmc-src
}

cleanup() {
    umount /tmp/emmc-src /tmp/emmc-dst 2>/dev/null || true
    rmdir /tmp/emmc-src /tmp/emmc-dst 2>/dev/null || true
}

main() {
    trap cleanup EXIT
    
    check_devices
    confirm
    
    copy_partition_table
    format_partitions
    
    mkdir -p /tmp/emmc-src /tmp/emmc-dst
    sync_boot
    sync_root
    
    sync
    echo ""
    echo "Installation complete. You can now reboot and remove the USB drive."
    read -r -p "Reboot now? (yes/no): " response
    [[ "$response" == "yes" ]] && reboot
}

main
