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

image_arch="$(architecture_from_raw_disk $test_disk)"
pecho "detected image architecture is $image_arch"

pecho "removing $known_host_str"
ssh-keygen -f "$HOME/.ssh/known_hosts" -R $known_host_str


case $image_arch in
    x86)
        qemu-system-x86_64 \
            -drive if=none,id=scalerunner-boot-disk,format=raw,file=$test_disk \
            -cpu host \
            --enable-kvm \
            -m 2G \
            -nographic \
            -nic user,model=virtio-net-pci,hostfwd=tcp::9022-:22 \
            -device virtio-scsi-pci,id=scsi0 \
            -device scsi-hd,drive=scalerunner-boot-disk,vendor=Google,product=PersistentDisk;;
    arm64)
        qemu-system-aarch64 \
            -nographic \
            -M virt -m 2G \
            -cpu max -smp 4 \
            -device virtio-rng \
            -bios /usr/share/qemu-efi-aarch64/QEMU_EFI.fd \
            -drive file=$test_disk,if=none,id=scalerunner-boot-disk,format=raw \
            -device nvme,serial=deadbeef,drive=scalerunner-boot-disk \
            -nic user,model=virtio-net-pci,hostfwd=tcp::9022-:22;;
esac
