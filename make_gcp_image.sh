#!/bin/bash

base_dir=`pwd`
out_dir=$base_dir/output
grub_path=`realpath grub-legacy`
grub_path_build=$grub_path/build
grub_s1=$grub_path_build/stage1/stage1
grub_s2=$grub_path_build/stage2/stage2

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

    dd if=$grub_s1 of=$out_dir/disk.raw bs=512 count=1
    dd if=$grub_s2 of=$out_dir/disk.raw bs=512 seek=1

    pecho "clearing partition table (leaving MBR intact)"
    dd if=/dev/zero of=$out_dir/disk.raw bs=1 count=64 seek=446 conv=notrunc

    truncate -s 200M $out_dir/disk.raw

    cd $base_dir
}

prepare_fat() {
    pecho "$(fdisk --version)"

    ( echo "n" ; echo p ; echo 1 ; echo "2048"; echo 409599; echo w; echo q ) | fdisk $out_dir/disk.raw
    ( echo t; echo 6; echo ; echo w; echo q ) | fdisk $out_dir/disk.raw
    ( echo a; echo w; echo q ) | fdisk $out_dir/disk.raw

    truncate -s 199M $out_dir/disk.fat
    mkfs.fat $out_dir/disk.fat

    cp $base_dir/buildroot/output/build/linux-*/arch/x86/boot/bzImage $out_dir

    mmd -i $out_dir/disk.fat ::boot
    mmd -i $out_dir/disk.fat ::boot/grub
    mcopy -i $out_dir/disk.fat $base_dir/menu.lst '::boot/grub/menu.lst'
    mcopy -i $out_dir/disk.fat $out_dir/bzImage '::.'

    dd conv=notrunc if=$out_dir/disk.fat of=$out_dir/disk.raw bs=512 seek=2048
}

mkdir -p $out_dir
make_grub
prepare_fat
