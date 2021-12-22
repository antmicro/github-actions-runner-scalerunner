#!/bin/sh

target_disk=/dev/disk/by-id/scsi-0Google_PersistentDisk_scalerunner-boot-disk
target_partition=${target_disk}-part2
target_mount=/mnt

timeout_ctr=0
timeout_max=10

if [ "$(whoami)" != 'root' ]; then
	echo 'root required'
	exit 2
fi

# Legacy fallback.
if [ ! -b "$target_disk" ]; then
	echo "$target_disk not found, will use fallback"
	target_disk=/dev/sda
	target_partition=2
fi

# Round up the result, we only care if it is non-zero.
target_free_space=$(sfdisk -F $target_disk | awk 'NR==1{ printf("%d\n",$4 + 0.5) }')

echo "$target_partition;$target_free_space"


# Create the partition and format it if it is not present.
if [ ! -b "$target_partition" ]; then
    echo "target partition not found, formatting disk"

    # Bail if no partition is found and there's no free space on the disk.
    if [ "$target_free_space" -eq 0 ]; then
        echo "no free unpartitioned space"
        exit 1
    fi

    # This will create a second partition on the disk (first is used as a boot partition for GRUB).
    # The sleep between write is necessary to avoid errors due to timing.
	(echo n; echo p; echo 2; echo; echo; sleep 1; echo w; echo q;) | fdisk \
		--wipe always \
		--wipe-partition always \
		$target_disk

    # Wait for the partition to appear.
    while [ ! -b "$target_partition" ]
    do
	    sync
	    partprobe

        if [ "$timeout_ctr" -eq "$timeout_max" ]; then
            echo "timeout waiting for $target_partition"
            exit 1
        fi

        timeout_ctr=$((timeout_ctr+=1))
        echo "waiting for $target_partition $timeout_ctr/$timeout_max"
        sleep 1
    done

	mke2fs $target_partition
	sync
fi

echo "mounting $target_partition -> $target_mount"
mount $target_partition $target_mount

# Print debug information.
df -h $target_partition
fdisk -l $target_disk
