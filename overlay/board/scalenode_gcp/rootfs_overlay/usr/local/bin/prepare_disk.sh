#!/bin/sh

target_disk=/dev/sda
target_partition=${target_disk}2
target_mount=/mnt
timeout_ctr=0
timeout_max=10

if [ `whoami` != 'root' ]; then
	echo 'root required'
	exit 2
fi

echo "$target_partition"

while [ ! -b "$target_partition" ]
do
	if [ "$timeout_ctr" -eq "$timeout_max" ]; then
		echo "timeout waiting for $target_partition"
		exit 1
	fi

	(echo n; echo p; echo 2; echo; echo; sleep 1; echo w; echo q;) | fdisk \
		--wipe always \
		--wipe-partition always \
		/dev/sda
	sync
	partprobe
	mke2fs $target_partition
	sync
	mount $target_partition $target_mount

	if [ ! -b $target_partition ]; then
		let timeout_ctr++
		echo "waiting for $target_partition $timeout_ctr/$timeout_max"
		sleep 1
	fi
done

df -h $target_partition
fdisk -l $target_disk
