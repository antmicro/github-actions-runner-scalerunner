#!/bin/bash

pecho() {
    printf '\x1b[1;32m>> \x1b[1;33m%s \x1b[0m%s\n' "${FUNCNAME[1]}" "$1"
}

make_grub() {
    pecho "Configuring and compiling GRUB Legacy..."

    cd grub-legacy
    mkdir -p build
    ./autogen.sh
    cd build
    CFLAGS+=" -static -fno-strict-aliasing -fno-stack-protector" ../configure
    make

    pecho "Done!"
}

mkdir -p output
make_grub
