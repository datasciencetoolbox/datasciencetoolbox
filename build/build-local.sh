#!/usr/bin/env bash

DST_VERSION="0.1.1"

rm -rf output-virtualbox-iso

echo "Build AMI and Vagrant with Packer"
packer build -var-file=variables.json -var "dst_version=${DST_VERSION}" dst.json -only=virtualbox-iso
