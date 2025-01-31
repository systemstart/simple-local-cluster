ROOT:= $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
KUBECONFIG=$(ROOT)/.kubeconfig

ifneq (,$(wildcard ./.env))
    include .env
    export
else
   $(error no .env found)
endif

restart:
	docker compose restart

up:
	docker compose up --build --remove-orphans -d

logs:
	docker compose logs -f

config:
	docker compose config

down:
	docker compose down --remove-orphans

rm:
	docker compose rm -vfs && docker volume prune -f

tail:
	docker compose logs -f

.PHONY: get-kubeconfig
get-kubeconfig: $(KUBECONFIG)


$(KUBECONFIG):
	@docker compose cp k3s:/etc/rancher/k3s/k3s.yaml $(KUBECONFIG) && \
		chmod -v 600 $(KUBECONFIG) && \
		sed -i "s/127\.0\.0\.1/$(PRIVATE_IP)/" $(KUBECONFIG) && \
		sed -i "s/default/$(CLUSTER_NAME)/g" $(KUBECONFIG)

install-3rdparty: $(KUBECONFIG)
	kubectl --kubeconfig $(KUBECONFIG) apply -f https://github.com/carvel-dev/secretgen-controller/releases/latest/download/release.yml

define RESOLVED_CONF
[Resolve]\n
Domains=~$(DOMAIN)\n
Cache=no\n
DNS=$(PRIVATE_IP):1053%lo#$(DOMAIN)\n
endef

export RESOLVED_CONF
write-resolved-conf.d:
	sudo mkdir -p /etc/systemd/resolved.conf.d
	echo $$RESOLVED_CONF | \
		sudo tee /etc/systemd/resolved.conf.d/$(DOMAIN).conf 
	sudo systemctl restart systemd-resolved
