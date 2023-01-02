#!/bin/bash

set -e

source common.sh

export PATH="$PATH:/usr/sbin"

check_image() {
    if [ ! -f $bzimage ]; then
        pecho "Kernel image not found at $bzimage"
        pecho "Build the image first."
        exit 1
    fi
    pecho "$bzimage is $image_arch"
}

partition_size() {
    image_size=`stat --format="%s" $bzimage`
    padding=`echo 10 | numfmt --from-unit=Mi`
    part_size=`expr $image_size + $padding`
    # make sure part_size is in 512 blocks, as gcp requires it
    part_size=$((((part_size / 512) + 1) * 512))

    echo $part_size
}

make_grub() {
    pecho "configuring and compiling grub legacy..."

    mkdir -p $grub_path_build
    cd $grub_path && ./autogen.sh
    cd $grub_path_build && CFLAGS+=" -static -fno-strict-aliasing -fno-stack-protector" ../configure --host x86_64
    cd $grub_path_build && make

    part_size=$(partition_size)
    blocks=`expr $part_size / 512`

    pecho "blocks: $blocks"

    dd if=/dev/zero of=$raw_disk bs=512 count=$blocks

    ls -alh $raw_disk

    pecho "copying stage binaries"

    dd if=$grub_s1 of=$raw_disk bs=512 count=1 conv=notrunc
    dd if=$grub_s2 of=$raw_disk bs=512 seek=1 conv=notrunc

    ls -alh $raw_disk

    pecho "clearing partition table (leaving MBR intact)"
    dd if=/dev/zero of=$raw_disk bs=1 count=64 seek=446 conv=notrunc

    ls -alh $raw_disk

    cd $base_dir
}

prepare_efistub_bootdisk() {
    part_size=$(partition_size)
    blocks=`expr $part_size / 512`

    pecho "blocks: $blocks"

    dd if=/dev/zero of=$raw_disk bs=512 count=$blocks

    ls -alh $raw_disk

    pecho "creating raw disk with bootable EFI partition"
    ( echo "n" ; echo p ; echo 1 ; echo; echo; echo w; echo q ) | fdisk $raw_disk
    ( echo t; echo ef; echo ; echo w; echo q ) | fdisk $raw_disk
    ( echo a; echo w; echo q ) | fdisk $raw_disk

    pecho "preparing fat32 partition"
    truncate -s $part_size $fat_part
    mkfs.fat -F 32 -n "GHA_$image_arch" $fat_part

    cp $bzimage $out_dir

    pecho "copying EFISTUB kernel to fat32 partition"
    mmd -i $fat_part ::EFI
    mmd -i $fat_part ::EFI/BOOT
    mcopy -i $fat_part $out_dir/Image '::EFI/BOOT/BOOTAA64.EFI'

    pecho "copying fat32 to raw disk" 
    dd conv=notrunc if=$fat_part of=$raw_disk bs=512 seek=2048 
}

prepare_bootdisk() {
    pecho "$(fdisk --version)"

    pecho "creating raw disk with bootable fat16 partition"
    ( echo "n" ; echo p ; echo 1 ; echo; echo; echo w; echo q ) | fdisk $raw_disk
    ( echo t; echo 6; echo ; echo w; echo q ) | fdisk $raw_disk
    ( echo a; echo w; echo q ) | fdisk $raw_disk

    pecho "preparing fat16 partition"
    truncate -s $part_size $fat_part
    mkfs.fat -F 16 -n "GHA_$image_arch" $fat_part

    cp $bzimage $out_dir

    pecho "copying grub and kernel to fat16 partition"
    mmd -i $fat_part ::boot
    mmd -i $fat_part ::boot/grub
    mcopy -i $fat_part $base_dir/menu.lst '::boot/grub/menu.lst'
    mcopy -i $fat_part $out_dir/bzImage '::.'

    ls -alh $raw_disk

    pecho "copying fat16 to raw disk" 
    dd conv=notrunc if=$fat_part of=$raw_disk bs=512 seek=2048 

    ls -alh $raw_disk

    cd $base_dir
}

make_tar() {
    pecho "$(basename $tar_path)"
    tar -Sczf $tar_path -C `dirname $raw_disk` disk.raw
}

check_image
mkdir -p $out_dir

case "$image_arch" in
    x86)
        make_grub
        prepare_bootdisk
        ;;
    arm64)
        prepare_efistub_bootdisk
        ;;
    *)
        pecho "unknown or unsupported architecture"
        exit 1
        ;;
esac

make_tar
