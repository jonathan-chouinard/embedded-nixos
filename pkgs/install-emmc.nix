# nixos-install-emmc: Copy the running NixOS system to internal eMMC storage
#
# Usage: nixos-install-emmc <target-device>
# Example: nixos-install-emmc /dev/mmcblk0
#
# The source device is auto-detected from the running root filesystem.
{
  writeShellApplication,
  rsync,
  dosfstools,
  e2fsprogs,
  util-linux,
  parted,
  coreutils,
}:
writeShellApplication {
  name = "nixos-install-emmc";
  runtimeInputs = [
    rsync
    dosfstools # mkfs.vfat
    e2fsprogs # mkfs.ext4
    util-linux # findmnt, sfdisk, lsblk, mount, umount
    parted # partprobe
    coreutils # dd, sync, mkdir, rmdir, sleep
  ];
  text = ''
    usage() {
        echo "Usage: nixos-install-emmc <target-device>"
        echo ""
        echo "Copy the running NixOS system to internal eMMC storage."
        echo "The source device is auto-detected from the running root filesystem."
        echo ""
        echo "Example: nixos-install-emmc /dev/mmcblk0"
        exit 1
    }

    # Determine partition suffix based on device type
    # mmcblk/nvme devices use "p1", "p2", etc.
    # Other devices (sda, sdb) use "1", "2", etc.
    get_part_suffix() {
        local dev="$1"
        if [[ "$dev" == *mmcblk* ]] || [[ "$dev" == *nvme* ]]; then
            echo "p"
        else
            echo ""
        fi
    }

    detect_source() {
        local root_part root_disk
        root_part=$(findmnt -n -o SOURCE /)
        
        if [[ -z "$root_part" ]]; then
            echo "Error: Could not detect root filesystem device"
            exit 1
        fi
        
        # Get the parent disk of the partition
        root_disk=$(lsblk -no PKNAME "$root_part" 2>/dev/null | head -1)
        
        if [[ -z "$root_disk" ]]; then
            echo "Error: Could not detect source disk from $root_part"
            exit 1
        fi
        
        echo "/dev/$root_disk"
    }

    check_devices() {
        if [[ ! -b "$SOURCE" ]]; then
            echo "Error: Source device $SOURCE not found"
            exit 1
        fi

        if [[ ! -b "$EMMC" ]]; then
            echo "Error: Target device $EMMC not found"
            exit 1
        fi

        if [[ "$SOURCE" == "$EMMC" ]]; then
            echo "Error: Source and target are the same device ($SOURCE)"
            exit 1
        fi

        local root_part
        root_part=$(findmnt -n -o SOURCE /)
        if [[ "$root_part" == "''${EMMC}"* ]]; then
            echo "Error: Already running from target device $EMMC"
            echo "Boot from external media to install to eMMC"
            exit 1
        fi
    }

    confirm() {
        echo "Source: $SOURCE (auto-detected from running system)"
        echo "Target: $EMMC"
        echo ""
        echo "WARNING: This will ERASE ALL DATA on $EMMC"
        echo ""
        read -r -p "Continue? (y/N): " response
        [[ "$response" == "y" ]] || exit 0
    }

    copy_partition_table() {
        echo "Copying partition table..."
        umount "''${EMMC}"* 2>/dev/null || true
        dd if=/dev/zero of="$EMMC" bs=1M count=1 status=none

        # Copy table with open-ended last partition (fills available space)
        sfdisk --dump "$SOURCE" | sed '$ d;/last-lba/d;' | sfdisk "$EMMC"
        local last_start
        last_start=$(sfdisk --dump "$SOURCE" | tail -1 | sed -n 's/.*start=\s*\([0-9]*\).*/\1/p')
        echo "''${last_start},+" | sfdisk "$EMMC" --append

        partprobe "$EMMC"
        sleep 1
    }

    format_partitions() {
        echo "Formatting partitions..."
        mkfs.vfat -n FIRMWARE "''${EMMC}''${EMMC_PART_SUFFIX}1"
        mkfs.ext4 -F -L NIXOS_SD "''${EMMC}''${EMMC_PART_SUFFIX}2"
    }

    sync_boot() {
        echo "Syncing boot partition..."
        mount -o ro "''${SOURCE}''${SOURCE_PART_SUFFIX}1" /tmp/emmc-src
        mount "''${EMMC}''${EMMC_PART_SUFFIX}1" /tmp/emmc-dst
        rsync -rltD --info=progress2 /tmp/emmc-src/ /tmp/emmc-dst/
        umount /tmp/emmc-dst
        umount /tmp/emmc-src
    }

    sync_root() {
        echo "Syncing root partition..."
        mount --bind / /tmp/emmc-src
        mount "''${EMMC}''${EMMC_PART_SUFFIX}2" /tmp/emmc-dst
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

    # Main

    [[ $# -ne 1 ]] && usage
    [[ "$1" == "-h" || "$1" == "--help" ]] && usage

    EMMC="$1"
    SOURCE=$(detect_source)
    SOURCE_PART_SUFFIX=$(get_part_suffix "$SOURCE")
    EMMC_PART_SUFFIX=$(get_part_suffix "$EMMC")

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
    echo "Installation complete. You can now reboot and remove the boot media."
    read -r -p "Reboot now? (y/N): " response
    [[ "$response" == "y" ]] && reboot
  '';
}
