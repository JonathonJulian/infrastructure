# Kubernetes on Proxmox Infrastructure Makefile
# Manages deployment and configuration of Kubernetes cluster with Proxmox CSI integration

#############################
# Variables
#############################
SHELL := /bin/bash
.PHONY: help deploy-k8s destroy-k8s setup-ansible install-charts update-charts clean configure-vault fix-vault-csi deploy-twingate store-proxmox-token

# Configuration
PROXMOX_TOKEN ?= $(shell if command -v vault >/dev/null && [ -n "$$VAULT_ADDR" ]; then \
	vault kv get -field=token -mount=proxmox credentials/root 2>/dev/null || echo "$(PROXMOX_TOKEN_ENV)"; \
	else \
	echo "$(PROXMOX_TOKEN_ENV)"; \
	fi)

# Verify token exists
ifeq ($(strip $(PROXMOX_TOKEN)),)
$(warning PROXMOX_TOKEN is not set, Proxmox operations will fail)
endif

TERRAFORM_DIR = terraform/deployments/k8s
ANSIBLE_DIR = ansible
CHARTS_DIR = charts
KUBE_NAMESPACE = kube-system
TWINGATE_NAMESPACE = twingate-system

# Check if vault is available
VAULT_AVAILABLE := $(shell command -v vault >/dev/null && echo 1 || echo 0)
VAULT_ADDR ?= https://vault.lab.local:8200
VAULT_SKIP_VERIFY ?= true

# Colors and formatting
BLUE := \033[1;34m
GREEN := \033[1;32m
RED := \033[1;31m
YELLOW := \033[1;33m
NC := \033[0m # No Color
INFO := @echo "\n${BLUE}ℹ️ "
SUCCESS := @echo "\n${GREEN}✅ "
ERROR := @echo "\n${RED}⛔ "
WARN := @echo "\n${YELLOW}⚠️ "

#############################
# Help
#############################

help: ## Show this help message
	@printf "\033[33m%s:\033[0m\n" 'Infrastructure Management Commands'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help


#############################
# Deployment Commands
#############################

deploy-k8s: ## Deploy Kubernetes cluster using Terraform and Ansible
	$(INFO)Starting full infrastructure deployment...${NC}
	@cd $(TERRAFORM_DIR) && terraform init && \
		terraform apply -var="proxmox_token=$(PROXMOX_TOKEN)" -auto-approve || \
		{ $(ERROR)Terraform deployment failed${NC}; exit 1; }

	$(INFO)Configuring Kubernetes cluster...${NC}
	@cd $(ANSIBLE_DIR) && ansible-playbook -i inventory/rke2.ini rke2-cluster.yaml || \
		{ $(ERROR)Ansible deployment failed${NC}; exit 1; }

	$(INFO)Installing Proxmox CSI and cloud controllers...${NC}
	@kubectl get nodes &>/dev/null || \
		{ $(WARN)Unable to get nodes, check your kubeconfig${NC}; exit 1; }
	@helm upgrade -i proxmox-controllers ./$(CHARTS_DIR)/proxmox/ \
		-n $(KUBE_NAMESPACE) -f ./$(CHARTS_DIR)/proxmox/values.yaml || \
		{ $(ERROR)Helm chart installation failed${NC}; exit 1; }

	$(SUCCESS)Kubernetes cluster deployment complete${NC}
	@kubectl get nodes

destroy-k8s: ## Destroy the entire Kubernetes infrastructure
	$(INFO)Destroying infrastructure...${NC}
	@cd $(TERRAFORM_DIR) && terraform init && \
		terraform destroy -var="proxmox_token=$(PROXMOX_TOKEN)" -auto-approve || \
		{ $(ERROR)Terraform destruction failed${NC}; exit 1; }
	$(SUCCESS)Infrastructure destroyed successfully${NC}

#############################
# Chart Management
#############################

store-proxmox-token: ## Store Proxmox token in Vault for secure integration
	$(INFO)Storing Proxmox token in Vault...${NC}
	@if [ -z "$$VAULT_TOKEN" ]; then \
		read -p "Enter your Vault token: " TOKEN; \
		export VAULT_TOKEN=$$TOKEN; \
	fi; \
	chmod +x ./$(CHARTS_DIR)/proxmox/store-proxmox-token.sh && \
	PROXMOX_TOKEN="$(PROXMOX_TOKEN)" ./$(CHARTS_DIR)/proxmox/store-proxmox-token.sh || \
		{ $(ERROR)Failed to store Proxmox token in Vault${NC}; exit 1; }
	$(SUCCESS)Proxmox token stored successfully in Vault${NC}

install-charts: ## Install Proxmox CSI Helm charts
	$(INFO)Installing Helm charts...${NC}
	@if [ "$(VAULT_AVAILABLE)" -eq 1 ]; then \
		$(INFO)Vault available, using secure token integration...${NC}; \
		helm upgrade -i proxmox-controllers ./$(CHARTS_DIR)/proxmox/ \
			-n $(KUBE_NAMESPACE) -f ./$(CHARTS_DIR)/proxmox/values.yaml || \
			{ $(ERROR)Chart installation failed${NC}; exit 1; }; \
	else \
		$(WARN)Vault not available, using environment variable for token...${NC}; \
		PROXMOX_TOKEN="$(PROXMOX_TOKEN)" helm upgrade -i proxmox-controllers ./$(CHARTS_DIR)/proxmox/ \
			-n $(KUBE_NAMESPACE) -f ./$(CHARTS_DIR)/proxmox/values.yaml || \
			{ $(ERROR)Chart installation failed${NC}; exit 1; }; \
	fi
	$(SUCCESS)Charts installed successfully${NC}

update-charts: ## Update Proxmox CSI Helm charts to latest version
	$(INFO)Updating Helm charts...${NC}
	@helm repo update
	@if [ "$(VAULT_AVAILABLE)" -eq 1 ]; then \
		$(INFO)Vault available, using secure token integration...${NC}; \
		helm upgrade proxmox-controllers ./$(CHARTS_DIR)/proxmox/ \
			-n $(KUBE_NAMESPACE) -f ./$(CHARTS_DIR)/proxmox/values.yaml || \
			{ $(ERROR)Chart update failed${NC}; exit 1; }; \
	else \
		$(WARN)Vault not available, using environment variable for token...${NC}; \
		PROXMOX_TOKEN="$(PROXMOX_TOKEN)" helm upgrade proxmox-controllers ./$(CHARTS_DIR)/proxmox/ \
			-n $(KUBE_NAMESPACE) -f ./$(CHARTS_DIR)/proxmox/values.yaml || \
			{ $(ERROR)Chart update failed${NC}; exit 1; }; \
	fi
	$(SUCCESS)Charts updated successfully${NC}

#############################
# Vault Integration
#############################

configure-vault: ## Configure Vault with Kubernetes authentication
	$(INFO)Configuring Vault for Kubernetes authentication...${NC}
	@if [ -z "$$VAULT_TOKEN" ]; then \
		read -p "Enter your Vault root token: " TOKEN; \
		export VAULT_TOKEN=$$TOKEN; \
	fi; \
	chmod +x ./$(CHARTS_DIR)/vault/setup-k8s-auth.sh && \
	./$(CHARTS_DIR)/vault/setup-k8s-auth.sh || \
		{ $(ERROR)Failed to configure Vault Kubernetes auth${NC}; exit 1; }
	$(SUCCESS)Vault Kubernetes authentication configured successfully${NC}

fix-vault-csi: ## Fix the Vault CSI Provider arguments
	$(INFO)Fixing Vault CSI Provider arguments...${NC}
	@kubectl patch daemonset vault-csi-provider -n $(KUBE_NAMESPACE) --type='json' \
		-p='[{"op": "replace", "path": "/spec/template/spec/containers/0/args", "value": ["--endpoint=/provider/vault.sock", "--hmac-secret-name=vault-csi-provider-hmac-key", "-debug"]}]' || \
		{ $(ERROR)Failed to patch Vault CSI provider${NC}; exit 1; }
	$(SUCCESS)Vault CSI provider patched successfully${NC}

deploy-twingate: ## Deploy Twingate operator with API key from Vault
	$(INFO)Deploying Twingate operator with Vault integration...${NC}
	@# First, create the Kubernetes secret with API key from Vault
	@chmod +x operators/twingate/create-secret.sh
	@./operators/twingate/create-secret.sh || { $(ERROR)Failed to create Twingate API key secret${NC}; exit 1; }
	@# Deploy the Twingate operator using Helm OCI registry
	@kubectl create namespace $(TWINGATE_NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	@helm upgrade --install twop \
		oci://ghcr.io/twingate/helmcharts/twingate-operator \
		--namespace $(TWINGATE_NAMESPACE) \
		--wait \
		-f operators/twingate/values.yaml || \
		{ $(ERROR)Failed to deploy Twingate operator${NC}; exit 1; }
	$(SUCCESS)Twingate operator deployed successfully${NC}
	@echo "To verify the deployment:"
	@echo "  kubectl get pods -n $(TWINGATE_NAMESPACE)"

#############################
# Cleanup
#############################

clean: ## Clean up temporary files and build artifacts
	$(INFO)Cleaning up temporary files...${NC}
	@find . -name "*.retry" -delete
	@find . -name ".terraform.lock.hcl" -delete
	@find . -name ".terraform" -type d -exec rm -rf {} +
	@find . -name "*.tfstate*" -delete
	@rm -rf $(ANSIBLE_DIR)/inventory/*
	@rm -f $(ANSIBLE_DIR)/tf_output.json
	$(SUCCESS)Cleanup complete${NC}
