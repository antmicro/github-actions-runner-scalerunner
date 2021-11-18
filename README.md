# Worker image for GitHub Actions custom runner

Copyright (c) 2020-2021 [Antmicro](https://www.antmicro.com)

This project contains the scripts and configuration files for building an image used by [Antmicro's GitHub Actions runner](https://github.com/antmicro/runner).

## Usage

Build the Buildroot-based image first by running `cd buildroot && make BR2_EXTERNAL=../overlay/ scalenode_gcp_defconfig && make`.

Then, run `./make_gcp_image.sh`.
This will prepare a disk with [grub-legacy](https://github.com/antmicro/grub-legacy) as MBR bootloader with configuration and kernel image on a 200MB FAT partition.

Next run `./upload_gcp_image $GCP_PROJECT $GCP_BUCKET`.
The tar archive created in the previous step will be uploaded to a Google Cloud Storage bucket and a ready-to-use image will be created.
This step is described more in-depth in the [Google Cloud documentation page on importing images](https://cloud.google.com/compute/docs/import/import-existing-image#import_image).

## Testing

It is possible to test the image locally by running the `./run_qemu.sh` script.

The SSH server will be accessible at port 9022 on `localhost`.
