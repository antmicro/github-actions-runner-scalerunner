#!/bin/sh

coordinator_boot_disk=/dev/disk/by-id/scsi-0Google_PersistentDisk_persistent-disk-0
# part1 is used as a boot partition
coordinator_boot_disk_target_partition=${coordinator_boot_disk}-part2
coordinator_boot_disk_mnt=/mnt/boot-persistent
coordinator_sif_disk=/dev/disk/by-id/scsi-0Google_PersistentDisk_gharunnersifimagedisk
coordinator_sif_disk_target_partition=${coordinator_sif_disk}-part1
coordinator_sif_disk_mnt=/mnt/sif
coordinator_persistent_disk=/dev/disk/by-id/scsi-0Google_PersistentDisk_gharunnerpersistentdisk
coordinator_persistent_disk_target_partition=${coordinator_persistent_disk}-part1
coordinator_persistent_disk_mnt=/mnt/persistent
coordinator_log_disk=/dev/disk/by-id/scsi-0Google_PersistentDisk_gharunnerlogs
coordinator_log_disk_target_partition=${coordinator_log_disk}-part1
coordinator_log_disk_mnt=/mnt/log

worker_boot_disk=/dev/disk/by-id/scsi-0Google_PersistentDisk_scalerunner-boot-disk
# part1 is used as a boot partition
worker_boot_disk_target_partition=${worker_boot_disk}-part2
worker_boot_disk_mnt=/mnt

timeout_ctr=0
timeout_max=10

check_root() {
    if [ "$(whoami)" != 'root' ]; then
	    echo 'root required'
	    exit 2
    fi
}

prepare_mount() {
    # Round up the result, we only care if it is non-zero.
    target_free_space=$(sfdisk -F $1 | awk 'NR==1{ printf("%d\n",$4 + 0.5) }')

    echo "$2;$target_free_space"
    # Create the partition and format it if it is not present.
    if [ ! -b "$2" ]; then
	echo "target partition not found, formatting disk"

	# Bail if no partition is found and there's no free space on the disk.
	if [ "$target_free_space" -eq 0 ]; then
	    echo "no free unpartitioned space"
	    exit 1
	fi

	# This will create a partition on the disk
	# The sleep between write is necessary to avoid errors due to timing.
	    (echo n; echo p; echo ; echo; echo; sleep 1; echo w; echo q;) | fdisk \
		    --wipe always \
		    --wipe-partition always \
		    $1

	# Wait for the partition to appear.
	while [ ! -b "$2" ]
	do
		sync
		partprobe

	    if [ "$timeout_ctr" -eq "$timeout_max" ]; then
		echo "timeout waiting for $2"
		exit 1
	    fi

	    timeout_ctr=$((timeout_ctr+=1))
	    echo "waiting for $2 $timeout_ctr/$timeout_max"
	    sleep 1
	done

	    mke2fs $2
	    sync
    fi
}

do_mount() {
    echo "mounting $1 -> $2"
    mkdir -p $2
    mount $1 $2
}

debug() {
    # Print debug information.
    df -h $1
    fdisk -l $2
}

check_root

if [ -b ${coordinator_boot_disk} ]; then
    echo "Detected coordinator machine!"
    # we are in coordinator machine
    prepare_mount ${coordinator_boot_disk} ${coordinator_boot_disk_target_partition}
    do_mount ${coordinator_boot_disk_target_partition} ${coordinator_boot_disk_mnt}
    debug ${coordinator_boot_disk_target_partition} ${coordinator_boot_disk}

    if [ -b ${coordinator_sif_disk} ]; then
	prepare_mount ${coordinator_sif_disk} ${coordinator_sif_disk_target_partition}
	do_mount ${coordinator_sif_disk_target_partition} ${coordinator_sif_disk_mnt}
	debug ${coordinator_sif_disk_target_partition} ${coordinator_sif_disk}
    else
	echo "Couldn't find sif disk, skipping mounting it"
    fi

    if [ -b ${coordinator_persistent_disk} ]; then
	prepare_mount ${coordinator_persistent_disk} ${coordinator_persistent_disk_target_partition}
	do_mount ${coordinator_persistent_disk_target_partition} ${coordinator_persistent_disk_mnt}
	debug ${coordinator_persistent_disk_target_partition} ${coordinator_persistent_disk}
    else
	echo "Couldn't find persistent disk, skipping mounting it"
    fi

    if [ -b ${coordinator_log_disk} ]; then
	prepare_mount ${coordinator_log_disk} ${coordinator_log_disk_target_partition}
	do_mount ${coordinator_log_disk_target_partition} ${coordinator_log_disk_mnt}
	debug ${coordinator_log_disk_target_partition} ${coordinator_log_disk}
    else
	echo "Couldn't find log disk, skipping mounting it"
    fi
elif [ -b ${worker_boot_disk} ]; then
    echo "Detected worker machine!"
    prepare_mount ${worker_boot_disk} ${worker_boot_disk_target_partition}
    do_mount ${worker_boot_disk_target_partition} ${worker_boot_disk_mnt}
    debug ${worker_boot_disk_target_partition} ${worker_target_disk}
else
    echo "Couldn't find any disk, skipping prepare_disk"
fi



