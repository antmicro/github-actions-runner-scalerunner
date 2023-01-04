#!/bin/bash

base_dir=`pwd`
out_dir=$base_dir/output

grub_path=`realpath grub-legacy`
grub_path_build=$grub_path/build
grub_s1=$grub_path_build/stage1/stage1
grub_s2=$grub_path_build/stage2/stage2

bzimage=$base_dir/buildroot/output/images/bzImage
fat_part=$out_dir/disk.fat
raw_disk=$out_dir/disk.raw

# Fallback for arm64
if [ ! -f "$bzimage" ]; then
    bzimage=$base_dir/buildroot/output/images/Image
fi

architecture_from_raw_disk() {
    # Skip to MBR partition entry #1 (0x01BE == 446) and read partition type byte (0x01BE + 0x04 = 0x01C2 == 450).
    local part_type="$(dd if=$1 bs=1 skip=450 count=1 status=none | od -A n -t x1 | sed 's/^ *//')"

    # FAT partition volume is located in the Extended BIOS Parameter block.
    # We detect the partition type from the MBR partition table -- 06 is FAT16, EF is EFI.
    # An assumption is made that the EFI partition is formatted in FAT32 (even though the spec doesn't enforce this).
    # In FAT12 and FAT16 the volume field is located at 0x02B (43) and in FAT32 at 0x47 (71).
    local fat_label_offset="$([ "$part_type" == "06" ] && echo 43 || echo 71)"

    # Skip partition table onto the first partition and read 11 bytes (max size) of the partition volume field.
    # The field is padded with spaces so we use xargs to strip trailing spaces as well.
    local fat_label="$(dd if=$1 bs=512 skip=2048 | dd bs=1 skip=$fat_label_offset count=11 status=none | xargs)"

    # Provide compatibility for images with no label.
    if [ "$fat_label" == "NO NAME" ]; then
        echo "x86"
        return
    fi

    # Strip the prefix (usually 'GHA_') to obtain the architecture.
    echo $fat_label | cut -d_ -f2
}

__get_image_arch() {
    if [ -f "$bzimage" ]; then
        file -b $bzimage \
            | sed -e "s#^Linux kernel ##" | cut -d' ' -f1 \
            | tr [:upper:] [:lower:]
    fi
}
image_arch="$(__get_image_arch)"


__tar_path() {
    checksum_short=$(git rev-parse --short HEAD)
    echo "$out_dir/scalenode-$checksum_short--$image_arch.tar.gz"
}
tar_path="$(__tar_path)"

pecho() {
    printf '\x1b[1;32m>> \x1b[1;33m%s \x1b[0m%s\n' "${FUNCNAME[1]}" "$1"
}
