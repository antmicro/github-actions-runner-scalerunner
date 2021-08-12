#!/bin/bash

set -e

source common.sh

project=$1
bucket=gs://$2
tar_arch="${3:-`tar_path`}"
image_name=$(basename $tar_arch .tar.gz)

usage() {
    pecho "`basename $0` PROJECT BUCKET [TAR_PATH]"
    exit 1
}

upload_archive() {
    pecho "uploading to $bucket"
    gsutil cp $tar_arch $bucket
}

create_image() {
    pecho "creating image $image_name in $project"
    gcloud compute images create $image_name \
        --source-uri $bucket/$(basename $tar_arch) \
        --project $project
}

if [ "$1" == "-h" ] || [ "$1" == "--help" ] || [ "$#" -lt 2 ]; then
    usage
fi

pecho "tar to upload: $tar_arch"
upload_archive
create_image
