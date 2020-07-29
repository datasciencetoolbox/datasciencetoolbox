docker-build:
	packer build -only docker -var-file variables.json template.json

docker-run:
	docker run -it --rm datasciencetoolbox/dsatcl2e
