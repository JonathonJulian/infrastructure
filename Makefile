.PHONY: deploy-k8s destroy-k8s help

# Full deployment flow
deploy-k8s:
	@echo "Deploying infrastructure with Terraform..."
	cd terraform/deployments/k8s && terraform init && terraform apply -auto-approve
	@echo "Deploying Kubernetes cluster with RKE2..."
	cd ansible && ansible-playbook -i inventory/rke2.ini rke2-cluster.yaml
	kubectl get nodes

# Full destruction flow
destroy-k8s:
	@echo "Destroying infrastructure with Terraform..."
	cd terraform/deployments/k8s && terraform init && terraform destroy -auto-approve

# Default target
help:
	@echo "Available Commands:"
	@echo "  deploy-k8s  - Deploy or update Kubernetes cluster"
	@echo "  destroy-k8s - Destroy Kubernetes cluster"
