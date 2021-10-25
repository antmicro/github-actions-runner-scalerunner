#!/bin/bash

set -e

source common.sh

export PATH="$PATH:/usr/sbin"

check_image() {
    if [ ! -f $bzimage ]; then
        pecho "bzImage not found at $bzimage"
        pecho "Build the image first."
        exit 1
    fi
}

partition_size() {
    image_size=`stat --format="%s" $bzimage`
    padding=`echo 10 | numfmt --from-unit=Mi`
    part_size=`expr $image_size + $padding`

    echo $part_size
}

make_grub() {
    pecho "configuring and compiling grub legacy..."

    mkdir -p $grub_path_build
    cd $grub_path && ./autogen.sh
    cd $grub_path_build && CFLAGS+=" -static -fno-strict-aliasing -fno-stack-protector" ../configure --host x86_64
    cd $grub_path_build && make

    pecho "copying stage binaries"

    dd if=$grub_s1 of=$raw_disk bs=512 count=1
    dd if=$grub_s2 of=$raw_disk bs=512 seek=1

    pecho "clearing partition table (leaving MBR intact)"
    dd if=/dev/zero of=$raw_disk bs=1 count=64 seek=446 conv=notrunc

    cd $base_dir
}

prepare_bootdisk() {
    part_size=$(partition_size)
    disk_size_before=`stat --format="%s" $raw_disk`
    disk_size_after=`expr $disk_size_before + $part_size`

    pecho "fat part;disk size: $part_size;$disk_size_after"
    truncate -s $disk_size_after $raw_disk

    pecho "$(fdisk --version)"

    pecho "creating raw disk with bootable fat16 partition"
    ( echo "n" ; echo p ; echo 1 ; echo; echo; echo w; echo q ) | fdisk $raw_disk
    ( echo t; echo 6; echo ; echo w; echo q ) | fdisk $raw_disk
    ( echo a; echo w; echo q ) | fdisk $raw_disk

    pecho "preparing fat16 partition"
    truncate -s $part_size $fat_part
    mkfs.fat $fat_part

    cp $bzimage $out_dir

    pecho "copying grub and kernel to fat16 partition"
    mmd -i $fat_part ::boot
    mmd -i $fat_part ::boot/grub
    mcopy -i $fat_part $base_dir/menu.lst '::boot/grub/menu.lst'
    mcopy -i $fat_part $out_dir/bzImage '::.'

    pecho "copying fat16 to raw disk" 
    dd conv=notrunc if=$fat_part of=$raw_disk bs=512 seek=2048

    cd $base_dir
}

make_tar() {
    tar_arch=$(tar_path)
    pecho "$(basename $tar_arch)"
    tar -Sczf $tar_arch -C `dirname $raw_disk` disk.raw
}

check_image
mkdir -p $out_dir
make_grub
prepare_bootdisk
make_tar
