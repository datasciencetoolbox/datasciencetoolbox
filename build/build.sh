#!/usr/bin/env bash

DST_VERSION="0.1.3"

DST_BOX="dst-${DST_VERSION}.box"
DST_URL="https://data-science-toolbox.s3.amazonaws.com/${DST_BOX}"
AWS_REGION=$(cat ~/.aws/config | grep region | cut -d= -f2 | tr -d ' ')

echo $DST_URL > url

#echo "Current boxes:"
#aws s3api list-objects --bucket data-science-toolbox | jq '.Contents[].Key' | tr -d \"

#echo "URL: ${DST_URL}"

rm -rf output-virtualbox-iso
rm -rf packer_virtualbox-iso_virtualbox.box

##1. build AMI and Vagrant with Packer
echo "Build AMI and Vagrant with Packer"
packer build -var-file=variables.json -var "dst_version=${DST_VERSION}" -only=amazon-ebs,virtualbox-iso dst.json 

##2. Rename and upload Vagrant box to S3
#echo "Rename and upload Vagrant box to S3"
#mv packer_virtualbox-iso_virtualbox.box boxes/$DST_BOX && aws s3 cp boxes/$DST_BOX s3://data-science-toolbox/ --acl public-read

#echo "Current boxes:"
#aws s3api list-objects --bucket data-science-toolbox | jq '.Contents[].Key' | tr -d \"

#4. Make AMI public
#AMI_ID=$(aws ec2 describe-images --owner self | jq '.Images[] | select(.Name=="dst-'${DST_VERSION}'") |  .ImageId' | tr -d \")
#aws ec2 modify-image-attribute --image-id $AMI_ID --launch-permission "{\"Add\": [{\"Group\":\"all\"}]}"

##3. Copy AMI to other regions
#OTHER_REGIONS=$(aws ec2 describe-regions | jq '.Regions[].RegionName' | tr -d \" | grep -v $AWS_REGION)
#for r in $OTHER_REGIONS; do
	#echo "Copying AMI to region: $r"
	#aws ec2 copy-image --source-image-id $AMI_ID --source-region $AWS_REGION --region $r --name "dst-${DST_VERSION}"
#done

#5. Create static HTML
#REGIONS=$(aws ec2 describe-regions | jq '.Regions[].RegionName' | tr -d \")
#echo "region,ami_id" > amis.csv
#for r in $REGIONS; do
	#AMI_ID=$(aws ec2 describe-images --owner self --region $r | jq '.Images[] | select(.Name=="dst-'${DST_VERSION}'") | .ImageId' | tr -d \")
	#echo "${r},${AMI_ID}" | tee -a amis.csv
#done

# Deregister other AMIs
#All AMIs registered using the image bundle must be de-registered using ec2-deregister.
#The image bundle should be deleted from Amazon S3 using ec2-delete-bundle or any other tool that can delete files in Amazon S3.

#OTHER_REGIONS=$(aws ec2 describe-regions | jq '.Regions[].RegionName' | tr -d \" | grep -v $AWS_REGION)
#for r in $OTHER_REGIONS; do
	#echo "Deregistering AMI to region: $r"
	#aws ec2 copy-image --source-image-id $AMI_ID --source-region $AWS_REGION --region $r --name "dst-${DST_VERSION}"
#done

#6. Upload HTML to Github
#7. Deregister old AMIs
