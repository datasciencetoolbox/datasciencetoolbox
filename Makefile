DOCKER_REPO = datasciencetoolbox
DOCKER_NAME = dsatcl2e

docker-build:
	ansible-playbook playbook-tools.yml playbook-user.yml --check && ANSIBLE_NOCOWS=1 packer build -only docker -var-file variables.json template.json

docker-run:
	docker run -it --rm -p 8000:8000 $(DOCKER_REPO)/$(DOCKER_NAME)

docker-stop:
	docker stop $$(docker ps | awk '/$(DOCKER_REPO)\/$(DOCKER_NAME)/ {print $$1}') 2>/dev/null || echo "Image $(DOCKER_REPO)/$(DOCKER_NAME) not running"

docker-remove:
	docker rmi $$(docker images | awk '/$(DOCKER_REPO)\/$(DOCKER_NAME)/ {print $$3}') 2>/dev/null || echo "Image $(DOCKER_REPO)/$(DOCKER_NAME) not found"
