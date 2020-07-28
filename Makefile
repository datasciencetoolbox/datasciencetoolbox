docker:
	packer build -only docker -var-file variables.json template.json
