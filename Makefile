# Kubernetes on Proxmox Infrastructure Makefile
# Manages deployment and configuration of Kubernetes cluster with Proxmox CSI integration

#############################
# Variables
#############################
SHELL := /bin/bash
.PHONY: deploy-k8s destroy-k8s setup-ansible install-charts update-charts clean

# Configuration
PROXMOX_TOKEN ?= $(PROXMOX_TOKEN_ENV)
TERRAFORM_DIR = terraform/deployments/k8s
ANSIBLE_DIR = ansible
CHARTS_DIR = charts
KUBE_NAMESPACE = kube-system

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
# Setup Commands
#############################

setup-ansible:
	$(INFO)Installing Ansible dependencies...${NC}
	@ansible-galaxy install -r $(ANSIBLE_DIR)/requirements.yaml
	@pip install -r $(ANSIBLE_DIR)/requirements.txt
	$(SUCCESS)Ansible dependencies installed successfully${NC}

#############################
# Deployment Commands
#############################

deploy-k8s: setup-ansible
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

destroy-k8s:
	$(INFO)Destroying infrastructure...${NC}
	@cd $(TERRAFORM_DIR) && terraform init && \
		terraform destroy -var="proxmox_token=$(PROXMOX_TOKEN)" -auto-approve || \
		{ $(ERROR)Terraform destruction failed${NC}; exit 1; }
	$(SUCCESS)Infrastructure destroyed successfully${NC}

#############################
# Chart Management
#############################

install-charts:
	$(INFO)Installing Helm charts...${NC}
	@helm upgrade -i proxmox-controllers ./$(CHARTS_DIR)/proxmox/ \
		-n $(KUBE_NAMESPACE) -f ./$(CHARTS_DIR)/proxmox/values.yaml || \
		{ $(ERROR)Chart installation failed${NC}; exit 1; }
	$(SUCCESS)Charts installed successfully${NC}

update-charts:
	$(INFO)Updating Helm charts...${NC}
	@helm repo update
	@helm upgrade proxmox-controllers ./$(CHARTS_DIR)/proxmox/ \
		-n $(KUBE_NAMESPACE) -f ./$(CHARTS_DIR)/proxmox/values.yaml || \
		{ $(ERROR)Chart update failed${NC}; exit 1; }
	$(SUCCESS)Charts updated successfully${NC}

#############################
# Cleanup
#############################

clean:
	$(INFO)Cleaning up temporary files...${NC}
	@find . -name "*.retry" -delete
	@find . -name ".terraform.lock.hcl" -delete
	@find . -name ".terraform" -type d -exec rm -rf {} +
	@find . -name "*.tfstate*" -delete
	@rm -rf $(ANSIBLE_DIR)/inventory/*
	$(SUCCESS)Cleanup complete${NC}

#