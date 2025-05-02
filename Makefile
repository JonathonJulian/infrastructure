# Unified Infrastructure and Proxmox CSI Makefile

# Infrastructure Variables
.PHONY: deploy-k8s destroy-k8s setup-ansible
PROXMOX_TOKEN ?= $(PROXMOX_TOKEN_ENV)

#############################
# Infrastructure Commands
#############################

# Setup Ansible dependencies
setup-ansible:
	@echo "Installing Ansible dependencies..."
	ansible-galaxy install -r ansible/requirements.yaml
	pip install -r ansible/requirements.txt

# Full deployment flow
deploy-k8s: setup-ansible
	@echo "Deploying infrastructure with Terraform..."
	cd terraform/deployments/k8s && terraform init && terraform apply -var="proxmox_token=$(PROXMOX_TOKEN)" -auto-approve || { echo "⛔ Terraform deployment failed"; exit 1; }
	cd ansible && ansible-playbook -i inventory/rke2.ini rke2-cluster.yaml || { echo "⛔ Ansible deployment failed"; exit 1; }
	@echo "✅ Kubernetes cluster deployment successful"
	kubectl get nodes || echo "⚠️ Unable to get nodes, check your kubeconfig"
	helm upgrade -i proxmox-controllers ./charts/proxmox/ -n kube-system -f ./charts/proxmox/values.yaml


# Full destruction flow
destroy-k8s:
	@echo "Destroying infrastructure with Terraform..."
	cd terraform/deployments/k8s && terraform init && terraform destroy -var="proxmox_token=$(PROXMOX_TOKEN)" -auto-approve || { echo "⛔ Terraform destruction failed"; exit 1; }
	@echo "✅ Infrastructure destroyed successfully"

#