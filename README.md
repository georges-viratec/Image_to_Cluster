# Image to Cluster - Séquence 3

## Description

Ce projet permet de créer une image Docker personnalisée avec Packer, puis de la déployer automatiquement sur un cluster Kubernetes K3d via Ansible. L'ensemble du workflow est automatisé via un Makefile.

## Architecture

L'architecture cible comprend :
- Une image Nginx personnalisée construite avec Packer
- Un cluster K3d (1 master + 2 workers)
- Un déploiement Kubernetes avec 2 replicas
- Un service exposé sur le port 30080

## Prérequis

- Docker
- K3d
- Git
- GitHub Codespace ou environnement Linux

Les outils Packer et Ansible seront installés automatiquement.

## Structure du projet
```
.
├── Makefile                      # Automatisation complète
├── README.md                     # Documentation
├── index.html                    # Page HTML personnalisée
├── install-packer-ansible.sh     # Script d'installation
├── ansible/
│   ├── ansible.cfg               # Configuration Ansible
│   ├── inventory/
│   │   ├── hosts.yml             # Inventaire
│   │   └── group_vars/
│   │       └── all.yml           # Variables globales
│   └── playbooks/
│       ├── deploy-app.yml        # Playbook de déploiement
│       ├── cleanup-app.yml       # Playbook de nettoyage
│       └── setup-cluster.yml     # Playbook setup cluster
├── k8s/
│   ├── deployment.yml            # Manifest Deployment
│   └── service.yml               # Manifest Service
└── packer/
    ├── nginx-image.pkr.hcl       # Template Packer
    └── index.html                # Fichier HTML pour l'image
```

## Installation rapide

### 1. Cloner le repository
```bash
git clone https://github.com/georges-viratec/Image_to_Cluster.git
cd Image_to_Cluster
```

### 2. Créer le cluster K3d
```bash
k3d cluster create lab --servers 1 --agents 2
```

### 3. Installer les outils
```bash
make install
```

### 4. Déployer l'application
```bash
make all
```

Cette commande unique exécute tout le workflow :
- Build de l'image avec Packer
- Import dans K3d
- Déploiement via Ansible

### 5. Accéder à l'application
```bash
make port-forward
```

Ouvrir l'onglet PORTS dans Codespaces et rendre public le port 8081.
Accéder à l'application via l'URL fournie.

## Utilisation du Makefile

### Commandes principales
```bash
make help           # Afficher l'aide
make check          # Vérifier les prérequis
make install        # Installer Packer et Ansible
make build          # Builder l'image Docker
make deploy         # Déployer sur K3d
make all            # Workflow complet
make status         # Statut du déploiement
make port-forward   # Accéder à l'application
make cleanup        # Supprimer l'application
make clean          # Nettoyage complet
```

### Commandes avancées
```bash
make test           # Tester la config Ansible
make logs           # Voir les logs
make describe       # Détails du déploiement
make restart        # Redémarrer l'application
make scale REPLICAS=3  # Scaler à 3 replicas
make shell          # Shell dans un pod
```

### Pipeline CI/CD
```bash
make pipeline       # Pipeline complète CI/CD
make ci             # Check + Test + Build
make cd             # Import + Deploy
```

## Workflow détaillé

### Étape 1 : Build de l'image
```bash
cd packer
packer init nginx-image.pkr.hcl
packer build nginx-image.pkr.hcl
```

Cette étape crée une image Docker `custom-nginx-app:latest` basée sur Nginx Alpine avec votre fichier HTML personnalisé.

### Étape 2 : Import dans K3d
```bash
k3d image import custom-nginx-app:latest -c lab
```

L'image est importée dans le cluster K3d pour être disponible aux pods Kubernetes.

### Étape 3 : Déploiement Ansible
```bash
cd ansible
ansible-playbook playbooks/deploy-app.yml
```

Ansible déploie automatiquement :
- Le Deployment Kubernetes (2 replicas)
- Le Service NodePort (port 30080)

### Étape 4 : Vérification
```bash
kubectl get deployments
kubectl get pods
kubectl get services
```

### Étape 5 : Port-forwarding
```bash
kubectl port-forward service/custom-nginx-service 8081:80
```

## Configuration

### Variables Ansible

Modifier `ansible/inventory/group_vars/all.yml` :
```yaml
cluster_name: lab
image_name: custom-nginx-app
image_tag: latest
app_name: custom-nginx
k8s_namespace: default
replicas: 2
service_port: 80
node_port: 30080
```

### Variables Packer

Modifier `packer/nginx-image.pkr.hcl` :
```hcl
variable "image_name" {
  default = "custom-nginx-app"
}

variable "image_tag" {
  default = "latest"
}
```

## Dépannage

### L'image n'existe pas
```bash
make build
docker images | grep custom-nginx-app
```

### Le cluster n'existe pas
```bash
k3d cluster create lab --servers 1 --agents 2
kubectl get nodes
```

### Port déjà utilisé
```bash
pkill -f "port-forward"
make port-forward
```

### Variables Ansible non chargées

Vérifier que `group_vars/all.yml` est dans `ansible/inventory/group_vars/`.

### Permissions Ansible
```bash
chmod 755 ansible/
find ansible/ -type f -exec chmod 644 {} \;
```

## Nettoyage

### Supprimer l'application
```bash
make cleanup
```

### Nettoyage complet
```bash
make clean
```

### Supprimer le cluster
```bash
k3d cluster delete lab
```

## Tests

### Vérifier la configuration Ansible
```bash
make test
```

### Vérifier les prérequis
```bash
make check
```

### Pipeline CI
```bash
make ci
```

## Technologies utilisées

- Docker : Conteneurisation
- Packer : Build d'images
- Ansible : Automatisation du déploiement
- Kubernetes (K3d) : Orchestration
- Nginx : Serveur web
- Make : Automatisation du workflow

## Licence

Ce projet est un exercice pédagogique dans le cadre de l'atelier "From Image to Cluster".

## Auteur

Lucken N'Landou @georges-viratec
