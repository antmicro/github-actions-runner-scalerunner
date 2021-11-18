#!/bin/sh

target_disk=/dev/sda
target_partition=${target_disk}2
target_mount=/mnt

timeout_ctr=0
timeout_max=10

if [ "$(whoami)" != 'root' ]; then
	echo 'root required'
	exit 2
fi

# Round up the result, we only care if it is non-zero.
target_free_space=$(sfdisk -F $target_disk | awk 'NR==1{ printf("%d\n",$4 + 0.5) }')

echo "$target_partition;$target_free_space"

if [ "$target_free_space" -eq 0 ]; then
    echo "no free unpartitioned space"
    exit 1
fi

while [ ! -b "$target_partition" ]
do
	if [ "$timeout_ctr" -eq "$timeout_max" ]; then
		echo "timeout waiting for $target_partition"
		exit 1
	fi

    # This will create a second partition on the disk (first is used as a boot partition for GRUB).
    # The sleep between write is necessary to avoid errors due to timing.
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
        timeout_ctr=$((timeout_ctr+=1))
		echo "waiting for $target_partition $timeout_ctr/$timeout_max"
		sleep 1
	fi
done

# Print debug information.
df -h $target_partition
fdisk -l $target_disk