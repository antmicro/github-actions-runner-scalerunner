#!/bin/sh

nvme_json=$(nvme id-ns $1 -b | dd bs=1 skip=384 status=none)
disk_name=$(echo $nvme_json | sed 's/.*"device_name":"\{0,1\}\([^,"]*\)"\{0,1\}.*/\1/')

echo "ID_SERIAL_SHORT=${disk_name}"
echo "ID_SERIAL=\"Google_PersistentDisk_${disk_name}\""
