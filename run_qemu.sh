#!/bin/bash

set -e

source common.sh

test_disk=$out_dir/disk.raw.test
known_host_str="[localhost]:9022"

if [ ! -f $test_disk ]; then
    pecho "creating test disk $test_disk"
    cp $raw_disk $test_disk
    fallocate -l 1G $test_disk
fi

pecho "removing $known_host_str"
ssh-keygen -f "$HOME/.ssh/known_hosts" -R $known_host_str

qemu-system-x86_64 \
    -drive if=none,id=drive0,format=raw,file=$test_disk \
    -cpu host \
    --enable-kvm \
    -m 2G \
    -nographic \
    -nic user,model=virtio-net-pci,hostfwd=tcp::9022-:22 \
    -device virtio-scsi-pci,id=scsi0 \
    -device scsi-hd,drive=drive0
