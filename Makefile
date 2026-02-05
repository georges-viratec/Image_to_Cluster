.PHONY: help install build import deploy cleanup all status port-forward check clean test

# Variables
CLUSTER_NAME = lab
IMAGE_NAME = custom-nginx-app
IMAGE_TAG = latest
APP_NAME = custom-nginx
PORT = 8081
SERVICE_NAME = custom-nginx-service

# Couleurs pour l'affichage
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
BLUE = \033[0;34m
CYAN = \033[0;36m
NC = \033[0m

##@ Aide

help: ## Afficher ce message d'aide
	@echo "$(BLUE)╔═══════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║          IMAGE TO CLUSTER - Séquence 3 Makefile               ║$(NC)"
	@echo "$(BLUE)╚═══════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(CYAN)Usage: make [target]$(NC)"
	@echo ""
	@echo "$(YELLOW)Commandes principales:$(NC)"
	@echo "  $(GREEN)make install$(NC)       - Installer Packer et Ansible"
	@echo "  $(GREEN)make build$(NC)         - Builder l'image Docker avec Packer"
	@echo "  $(GREEN)make deploy$(NC)        - Déployer l'application sur K3d avec Ansible"
	@echo "  $(GREEN)make all$(NC)           - Exécuter tout le workflow (build + deploy)"
	@echo "  $(GREEN)make status$(NC)        - Afficher le statut du déploiement"
	@echo "  $(GREEN)make port-forward$(NC)  - Activer le port-forwarding (port $(PORT))"
	@echo "  $(GREEN)make cleanup$(NC)       - Supprimer l'application du cluster"
	@echo "  $(GREEN)make clean$(NC)         - Nettoyage complet (image + déploiement)"
	@echo ""
	@echo "$(YELLOW)Commandes de vérification:$(NC)"
	@echo "  $(GREEN)make check$(NC)         - Vérifier les prérequis"
	@echo "  $(GREEN)make test$(NC)          - Tester la configuration Ansible"
	@echo ""

##@ Installation

install: ## Installer Packer et Ansible
	@echo "$(YELLOW)🔧 Installation de Packer et Ansible...$(NC)"
	@if [ -f install-packer-ansible.sh ]; then \
		chmod +x install-packer-ansible.sh && ./install-packer-ansible.sh; \
	else \
		echo "$(YELLOW)Installation de Packer...$(NC)"; \
		wget -q -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg; \
		echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $$(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null; \
		sudo apt update -qq && sudo apt install -y packer > /dev/null 2>&1; \
		echo "$(YELLOW)⚙️  Installation d'Ansible...$(NC)"; \
		sudo apt install -y software-properties-common > /dev/null 2>&1; \
		sudo add-apt-repository --yes --update ppa:ansible/ansible > /dev/null 2>&1; \
		sudo apt install -y ansible > /dev/null 2>&1; \
	fi
	@echo "$(GREEN)Installation terminée !$(NC)"
	@echo "$(CYAN)Versions installées:$(NC)"
	@packer version
	@ansible --version | head -1

check: ## Vérifier les prérequis (K3d, Docker, Packer, Ansible)
	@echo "$(YELLOW)Vérification des prérequis...$(NC)"
	@echo -n "  Docker:    "
	@docker --version > /dev/null 2>&1 && echo "$(GREEN)✓$(NC)" || echo "$(RED)✗ (non installé)$(NC)"
	@echo -n "  K3d:       "
	@k3d version > /dev/null 2>&1 && echo "$(GREEN)✓$(NC)" || echo "$(RED)✗ (non installé)$(NC)"
	@echo -n "  Packer:    "
	@packer version > /dev/null 2>&1 && echo "$(GREEN)✓$(NC)" || echo "$(RED)✗ (installer avec 'make install')$(NC)"
	@echo -n "  Ansible:   "
	@ansible --version > /dev/null 2>&1 && echo "$(GREEN)✓$(NC)" || echo "$(RED)✗ (installer avec 'make install')$(NC)"
	@echo -n "  Cluster:   "
	@k3d cluster list | grep -q $(CLUSTER_NAME) && echo "$(GREEN)✓ ($(CLUSTER_NAME) actif)$(NC)" || echo "$(RED)✗ (créer avec 'make setup-cluster')$(NC)"

##@ Build de l'image

build: ## Builder l'image Docker avec Packer
	@echo "$(YELLOW)Build de l'image $(IMAGE_NAME):$(IMAGE_TAG) avec Packer...$(NC)"
	@cd packer && \
		packer init nginx-image.pkr.hcl && \
		packer build nginx-image.pkr.hcl
	@echo "$(GREEN)Image buildée avec succès !$(NC)"
	@docker images | grep $(IMAGE_NAME)

import: ## Importer l'image dans K3d
	@echo "$(YELLOW)Import de l'image dans K3d...$(NC)"
	@k3d image import $(IMAGE_NAME):$(IMAGE_TAG) -c $(CLUSTER_NAME)
	@echo "$(GREEN)Image importée dans le cluster $(CLUSTER_NAME) !$(NC)"

##@ Déploiement

deploy: ## Déployer l'application avec Ansible
	@echo "$(YELLOW)Déploiement de l'application avec Ansible...$(NC)"
	@cd ansible && ansible-playbook playbooks/deploy-app.yml
	@echo "$(GREEN)Application déployée !$(NC)"
	@echo ""
	@echo "$(CYAN)Pour accéder à l'application:$(NC)"
	@echo "  make port-forward"

test: ## Tester la configuration Ansible (dry-run)
	@echo "$(YELLOW)Test de la configuration Ansible...$(NC)"
	@cd ansible && ansible-playbook playbooks/deploy-app.yml --check
	@echo "$(GREEN)Configuration Ansible valide !$(NC)"

##@ Workflow complet

all: build import deploy status ## Exécuter le workflow complet (build + import + deploy)
	@echo ""
	@echo "$(GREEN)╔═══════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(GREEN)║               DÉPLOIEMENT RÉUSSI !                            ║$(NC)"
	@echo "$(GREEN)╚═══════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(CYAN)Prochaine étape:$(NC)"
	@echo "   make port-forward    $(YELLOW)# Pour accéder à l'application$(NC)"

##@ Gestion du cluster

setup-cluster: ## Créer le cluster K3d (1 master + 2 workers)
	@echo "$(YELLOW)🏗️  Création du cluster K3d...$(NC)"
	@k3d cluster create $(CLUSTER_NAME) --servers 1 --agents 2
	@echo "$(GREEN)Cluster $(CLUSTER_NAME) créé !$(NC)"
	@kubectl get nodes

status: ## Afficher le statut du déploiement
	@echo "$(CYAN)═══════════════════════════════════════════════════════════════$(NC)"
	@echo "$(CYAN)           STATUT DU DÉPLOIEMENT$(NC)"
	@echo "$(CYAN)═══════════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@echo "$(YELLOW)Images Docker locales:$(NC)"
	@docker images | grep $(IMAGE_NAME) || echo "  $(RED)Aucune image trouvée$(NC)"
	@echo ""
	@echo "$(YELLOW)Deployments Kubernetes:$(NC)"
	@kubectl get deployments -l app=$(APP_NAME) 2>/dev/null || echo "  $(RED)Aucun deployment trouvé$(NC)"
	@echo ""
	@echo "$(YELLOW)Pods:$(NC)"
	@kubectl get pods -l app=$(APP_NAME) 2>/dev/null || echo "  $(RED)Aucun pod trouvé$(NC)"
	@echo ""
	@echo "$(YELLOW)Services:$(NC)"
	@kubectl get svc $(SERVICE_NAME) 2>/dev/null || echo "  $(RED)Aucun service trouvé$(NC)"
	@echo ""

port-forward: ## Activer le port-forwarding pour accéder à l'application
	@echo "$(YELLOW)Activation du port-forwarding sur le port $(PORT)...$(NC)"
	@echo "$(CYAN)➜ Appuyez sur Ctrl+C pour arrêter$(NC)"
	@echo ""
	@echo "$(GREEN)Application accessible sur: http://localhost:$(PORT)$(NC)"
	@echo ""
	@kubectl port-forward service/$(SERVICE_NAME) $(PORT):80

logs: ## Afficher les logs des pods
	@echo "$(YELLOW)Logs des pods $(APP_NAME)...$(NC)"
	@kubectl logs -l app=$(APP_NAME) --all-containers=true --tail=50

describe: ## Afficher les détails du déploiement
	@echo "$(YELLOW)Détails du deployment:$(NC)"
	@kubectl describe deployment $(APP_NAME)-app
	@echo ""
	@echo "$(YELLOW)Détails du service:$(NC)"
	@kubectl describe service $(SERVICE_NAME)

##@ Nettoyage

cleanup: ## Supprimer l'application du cluster (via Ansible)
	@echo "$(YELLOW)Suppression de l'application...$(NC)"
	@cd ansible && ansible-playbook playbooks/cleanup-app.yml
	@echo "$(GREEN)Application supprimée du cluster !$(NC)"

clean: cleanup ## Nettoyage complet (application + image Docker locale)
	@echo "$(YELLOW)Suppression de l'image Docker locale...$(NC)"
	@docker rmi $(IMAGE_NAME):$(IMAGE_TAG) 2>/dev/null || echo "  $(YELLOW)Image déjà supprimée$(NC)"
	@echo "$(GREEN)Nettoyage complet terminé !$(NC)"

destroy-cluster: ## DANGER: Supprimer complètement le cluster K3d
	@echo "$(RED)ATTENTION: Ceci va supprimer le cluster $(CLUSTER_NAME) !$(NC)"
	@echo -n "$(YELLOW)Êtes-vous sûr ? [y/N] $(NC)" && read ans && [ $${ans:-N} = y ]
	@k3d cluster delete $(CLUSTER_NAME)
	@echo "$(GREEN)Cluster $(CLUSTER_NAME) supprimé !$(NC)"

##@ Utilitaires

shell: ## Ouvrir un shell dans un pod de l'application
	@echo "$(YELLOW)Ouverture d'un shell dans le pod...$(NC)"
	@kubectl exec -it $$(kubectl get pod -l app=$(APP_NAME) -o jsonpath='{.items[0].metadata.name}') -- /bin/sh

restart: ## Redémarrer l'application
	@echo "$(YELLOW)Redémarrage de l'application...$(NC)"
	@kubectl rollout restart deployment $(APP_NAME)-app
	@kubectl rollout status deployment $(APP_NAME)-app
	@echo "$(GREEN)Application redémarrée !$(NC)"

scale: ## Scaler l'application (usage: make scale REPLICAS=3)
	@echo "$(YELLOW)Scaling à $(REPLICAS) replicas...$(NC)"
	@kubectl scale deployment $(APP_NAME)-app --replicas=$(REPLICAS)
	@kubectl rollout status deployment $(APP_NAME)-app
	@echo "$(GREEN)Application scalée à $(REPLICAS) replicas !$(NC)"

##@ CI/CD

ci: check test build ## Pipeline CI (vérification + test + build)
	@echo "$(GREEN)Pipeline CI réussie !$(NC)"

cd: import deploy status ## Pipeline CD (import + déploiement)
	@echo "$(GREEN)Pipeline CD réussie !$(NC)"

pipeline: ci cd ## Pipeline complète CI/CD
	@echo "$(GREEN)Pipeline CI/CD complète réussie !$(NC)"