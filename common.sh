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

pecho() {
    printf '\x1b[1;32m>> \x1b[1;33m%s \x1b[0m%s\n' "${FUNCNAME[1]}" "$1"
}

tar_path() {
    checksum_short=$(git rev-parse --short HEAD)
    echo "$out_dir/scalenode-$checksum_short.tar.gz"
}
