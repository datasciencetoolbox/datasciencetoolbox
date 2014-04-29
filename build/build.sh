#!/usr/bin/env bash

DST_VERSION="$(cat version)"

DST_BOX="dst-${DST_VERSION}.box"
DST_URL="https://data-science-toolbox.s3.amazonaws.com/${DST_BOX}"
AWS_REGION=$(cat ~/.aws/config | grep region | cut -d= -f2 | tr -d ' ')

echo "AWS_REGION: ${AWS_REGION}" 
echo -n 'DST_URL: '
echo $DST_URL | tee url

#sleep 5

## Update version of dst package and try to upload package to PyPi
#< ../manager/setup.py.j2 sed "s/{{version}}/${DST_VERSION}/" > ../manager/setup.py
#( cd ../manager; python setup.py sdist upload )


#echo "Current boxes:"
#aws s3api list-objects --bucket data-science-toolbox | jq '.Contents[].Key' | tr -d \"

echo "URL: ${DST_URL}"

rm -rf output-virtualbox-iso
rm -rf packer_virtualbox-iso_virtualbox.box

#1. build AMI and Vagrant with Packer
echo "Build AMI and Vagrant with Packer"
packer build -var-file=variables.json -var "dst_version=${DST_VERSION}" -only=virtualbox-iso dst.json 

# virtualbox-iso
# amazon-ebs


##2. Rename and upload Vagrant box to S3
echo "Rename and upload Vagrant box to S3"
mv packer_virtualbox-iso_virtualbox.box boxes/$DST_BOX #
#aws s3 cp boxes/$DST_BOX s3://data-science-toolbox/$DST_BOX --acl public-read
#mv packer_virtualbox-iso_virtualbox.box boxes/$DST_BOX && aws s3 cp boxes/$DST_BOX s3://data-science-toolbox/ --acl public-read

###Update local Vagrant box
vagrant box remove dst
vagrant box add dst boxes/$DST_BOX


#echo "Current boxes:"
#aws s3api list-objects --bucket data-science-toolbox | jq '.Contents[].Key' | tr -d \"


##4. Make AMI public
#AMI_ID=$(aws ec2 describe-images --owner self | jq '.Images[] | select(.Name=="dst-'${DST_VERSION}'") |  .ImageId' | tr -d \")
#echo "AMI_ID: ${AMI_ID}"
#aws ec2 create-tags --resources $AMI_ID --tags Key=Name,Value='Data Science Toolbox'
#aws ec2 modify-image-attribute --image-id $AMI_ID --launch-permission "{\"Add\": [{\"Group\":\"all\"}]}"

#aws ec2 copy-image --source-image-id $AMI_ID --source-region $AWS_REGION --region us-west-2 --name "dst-${DST_VERSION}"

####aws ec2 copy-image --source-image-id $AMI_ID --source-region $AWS_REGION --region eu-west-1 --name "dst-${DST_VERSION}"


#3. Copy AMI to other regions
#OTHER_REGIONS=$(aws ec2 describe-regions | jq '.Regions[].RegionName' | tr -d \" | grep -v $AWS_REGION)
#for r in $OTHER_REGIONS; do
	#echo "Copying AMI to region: $r"
	#aws ec2 copy-image --source-image-id $AMI_ID --source-region $AWS_REGION --region $r --name "dst-${DST_VERSION}"
#done


#REGIONS=$(aws ec2 describe-regions | jq '.Regions[].RegionName' | tr -d \" | grep ap-southeast-2)
#echo "region,ami_id" > amis.csv
#for r in $REGIONS; do
	#OTHER_AMI_ID=$(aws ec2 describe-images --owner self --region $r | jq '.Images[] | select(.Name=="dst-'${DST_VERSION}'") | .ImageId' | tr -d \")

	#echo "${r},${OTHER_AMI_ID}" | tee -a amis.csv

	#aws ec2 create-tags --resources $OTHER_AMI_ID --tags Key=Name,Value='Data Science Toolbox' --region $r
	#aws ec2 modify-image-attribute --image-id $OTHER_AMI_ID --launch-permission "{\"Add\": [{\"Group\":\"all\"}]}" --region $r
	#aws ec2 modify-image-attribute --image-id $OTHER_AMI_ID --description "Data Science Toolbox -- Start doing data science in minutes. Visit http://datasciencetoolbox.org for more information." --region $r
	#echo 
	#echo
#done

#5. Create static HTML
#REGIONS=$(aws ec2 describe-regions | jq '.Regions[].RegionName' | tr -d \")
#echo "region_code,region_name,ami_id" > amis.csv
#for REGION_CODE in $REGIONS; do
	#OTHER_AMI_ID=$(aws ec2 describe-images --owner self --region $REGION_CODE | jq '.Images[] | select(.Name=="dst-'${DST_VERSION}'") | .ImageId' | tr -d \")
	#REGION_NAME=$(cat regions.csv | grep $REGION_CODE | cut -d, -f2)
	#echo "${REGION_CODE},${REGION_NAME},${OTHER_AMI_ID}" | tee -a amis.csv
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
