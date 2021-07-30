#!/bin/bash

base_dir=`pwd`
out_dir=$base_dir/output
stamp=`date +%Y-%m-%d--%H-%M-%S`

grub_path=`realpath grub-legacy`
grub_path_build=$grub_path/build
grub_s1=$grub_path_build/stage1/stage1
grub_s2=$grub_path_build/stage2/stage2

fat_part=$out_dir/disk.fat
raw_disk=$out_dir/disk.raw
tar_arch=$out_dir/scalenode-$stamp.tar.gz

export PATH="$PATH:/usr/sbin"

pecho() {
    printf '\x1b[1;32m>> \x1b[1;33m%s \x1b[0m%s\n' "${FUNCNAME[1]}" "$1"
}

make_grub() {
    pecho "configuring and compiling grub legacy..."

    mkdir -p $grub_path_build
    cd $grub_path && ./autogen.sh
    cd $grub_path_build CFLAGS+=" -static -fno-strict-aliasing -fno-stack-protector" ../configure
    cd $grub_path_build && make

    pecho "copying stage binaries"

    dd if=$grub_s1 of=$raw_disk bs=512 count=1
    dd if=$grub_s2 of=$raw_disk bs=512 seek=1

    pecho "clearing partition table (leaving MBR intact)"
    dd if=/dev/zero of=$raw_disk bs=1 count=64 seek=446 conv=notrunc

    truncate -s 200M $raw_disk

    cd $base_dir
}

prepare_bootdisk() {
    pecho "$(fdisk --version)"

    pecho "creating raw disk with bootable fat16 partition"
    ( echo "n" ; echo p ; echo 1 ; echo "2048"; echo 409599; echo w; echo q ) | fdisk $raw_disk
    ( echo t; echo 6; echo ; echo w; echo q ) | fdisk $raw_disk
    ( echo a; echo w; echo q ) | fdisk $raw_disk

    pecho "preparing fat16 partition"
    truncate -s 199M $fat_part
    mkfs.fat $fat_part

    cp $base_dir/buildroot/output/build/linux-*/arch/x86/boot/bzImage $out_dir

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
    pecho "$(basename $tar_arch)"
    tar -Sczf $tar_arch $raw_disk
}

mkdir -p $out_dir
make_grub
prepare_bootdisk
make_tar
