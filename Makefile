.PHONY: deploy-k8s destroy-k8s help setup-ansible

# Setup Ansible dependencies
setup-ansible:
	@echo "Installing Ansible dependencies..."
	ansible-galaxy install -r ansible/requirements.yaml
	pip install -r ansible/requirements.txt

# Full deployment flow
deploy-k8s: setup-ansible
	@echo "Deploying infrastructure with Terraform..."
	cd terraform/deployments/k8s && terraform init && terraform apply -auto-approve || { echo "⛔ Terraform deployment failed"; exit 1; }
	@echo "✅ Terraform deployment successful"
	@echo "Deploying Kubernetes cluster with RKE2..."
	cd ansible && ansible-playbook -i inventory/rke2.ini rke2-cluster.yaml || { echo "⛔ Ansible deployment failed"; exit 1; }
	@echo "✅ Kubernetes cluster deployment successful"
	kubectl get nodes || echo "⚠️ Unable to get nodes, check your kubeconfig"

# Full destruction flow
destroy-k8s:
	@echo "Destroying infrastructure with Terraform..."
	cd terraform/deployments/k8s && terraform init && terraform destroy -auto-approve || { echo "⛔ Terraform destruction failed"; exit 1; }
	@echo "✅ Infrastructure destroyed successfully"

# Default target
help:
	@echo "Available Commands:"
	@echo "  deploy-k8s  - Deploy or update Kubernetes cluster"
	@echo "  destroy-k8s - Destroy Kubernetes cluster"
	@echo "  setup-ansible - Install required Ansible dependencies"
