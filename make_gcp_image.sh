#!/bin/bash

base_dir=`pwd`
out_dir=$base_dir/output
grub_path=`realpath grub-legacy`
grub_path_build=$grub_path/build
grub_s1=$grub_path_build/stage1/stage1
grub_s2=$grub_path_build/stage2/stage2

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

    cp $grub_s1 $out_dir
    cp $grub_s2 $out_dir

    cd $base_dir
}

mkdir -p $out_dir
make_grub
