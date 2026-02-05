# 1. Appliquer le Deployment
kubectl apply -f deployment.yml
# 2. Appliquer le Service
kubectl apply -f service.yml
# 3. Vérifier le déploiement
kubectl get deployments
kubectl get pods
kubectl get services
# 4. Voir les détails
kubectl describe deployment custom-nginx-app
kubectl describe service custom-nginx-service