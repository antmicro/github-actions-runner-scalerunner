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
