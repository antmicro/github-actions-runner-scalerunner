#!/bin/bash

source common.sh

project=$1
bucket=gs://$2
tar_arch=$(tar_path)
image_name=$(basename $tar_arch .tar.gz)

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

upload_archive
create_image
