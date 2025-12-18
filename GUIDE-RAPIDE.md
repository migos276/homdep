# 🚀 Guide de Déploiement Rapide - Homify sur tmc.supahuman.site

## ⚡ Déploiement en 3 Étapes

### Étape 1 : Préparation du Serveur
```bash
# Connectez-vous à votre serveur (Ubuntu/Debian)
ssh root@your-server-ip

# Mettez à jour le système
apt update && apt upgrade -y
```

### Étape 2 : Transfert des Fichiers
```bash
# Sur votre machine locale, copiez TOUS les fichiers vers le serveur
# IMPORTANT : Incluez tous les dossiers et fichiers de votre projet

scp -r \
  nginx.conf \
  quick-deploy.sh \
  backend.env.template \
  src/ \
  backend_homify/ \
  package.json \
  vite.config.ts \
  tailwind.config.js \
  postcss.config.js \
  tsconfig*.json \
  eslint.config.js \
  *.md \
  *.png \
  root@your-server-ip:/tmp/
```

### Étape 3 : Déploiement Automatique
```bash
# Sur le serveur, exécutez le script de déploiement
cd /tmp
chmod +x quick-deploy.sh
sudo ./quick-deploy.sh

# C'est tout ! Votre site sera disponible sur tmc.supahuman.site
```

## 🎯 Ce que fait le Script Automatiquement

✅ **Installe toutes les dépendances :**
- NGINX (serveur web)
- PostgreSQL (base de données)
- Redis (cache)
- Node.js & npm (pour le frontend)
- Python & pip (pour le backend)

✅ **Configure l'environnement :**
- Base de données PostgreSQL avec utilisateur homify_user
- Variables d'environnement Django
- Répertoires et permissions

✅ **Déploie votre code :**
- Copie et construit le frontend React/Vite
- Copie et configure le backend Django
- Applique les migrations Django
- Collecte les fichiers statiques

✅ **Configure NGINX :**
- Serve le frontend sur tmc.supahuman.site
- Proxy les requêtes /api/ vers Django
- Configuration sécurisée avec headers

✅ **Démarre les services :**
- Service systemd pour Django
- Redémarrage automatique en cas de panne

## 🌐 Accès à votre Site

Après le déploiement, votre site sera accessible sur :

- **🏠 Site Principal** : http://tmc.supahuman.site
- **🔌 API Backend** : http://tmc.supahuman.site/api/
- **⚙️ Admin Django** : http://tmc.supahuman.site/admin/

## 📋 Personnalisation Post-Déploiement

### 1. Variables d'Environnement
```bash
# Éditez le fichier d'environnement
nano /var/www/homify/backend/.env
```

Modifiez ces variables importantes :
```env
SECRET_KEY=votre-cle-secrete-unique-et-forte
EMAIL_HOST_USER=votre-email@gmail.com
EMAIL_HOST_PASSWORD=votre-mot-de-passe-application-gmail
```

### 2. Créer un Superutilisateur Django
```bash
cd /var/www/homify/backend
python3 manage.py createsuperuser
```

### 3. Configurer SSL (Recommandé)
```bash
# Installez Certbot
apt install -y certbot python3-certbot-nginx

# Configurez SSL pour votre domaine
certbot --nginx -d tmc.supahuman.site -d www.tmc.supahuman.site
```

## 🔧 Commandes de Maintenance

```bash
# Redémarrer les services
sudo systemctl restart homify-backend nginx

# Voir les logs en temps réel
sudo journalctl -u homify-backend -f
sudo tail -f /var/log/nginx/homify_access.log

# Vérifier le statut
sudo systemctl status homify-backend nginx

# Tester la configuration NGINX
sudo nginx -t
```

## 🆘 Dépannage Rapide

### Le site ne se charge pas
```bash
# Vérifiez les services
sudo systemctl status homify-backend nginx

# Consultez les logs
sudo journalctl -u homify-backend --no-pager -n 20
```

### Erreur 502 Bad Gateway
```bash
# Redémarrez le backend
sudo systemctl restart homify-backend

# Vérifiez qu'il fonctionne localement
curl http://127.0.0.1:8000
```

### Problèmes de permissions
```bash
# Réparez les permissions
sudo chown -R www-data:www-data /var/www/homify
sudo chmod -R 755 /var/www/homify
```

## 📞 Vérification Complète

```bash
# Exécutez le script de vérification
sudo ./check-deployment.sh
```

## 🎉 Résultat Final

Après ces 3 étapes, vous aurez :

- ✅ Un site web complet sur tmc.supahuman.site
- ✅ Frontend React/Vite servit par NGINX
- ✅ API Django avec base de données PostgreSQL
- ✅ Configuration sécurisée et optimisée
- ✅ Services redémarrant automatiquement
- ✅ Logs et monitoring configurés

**Votre projet Homify sera en ligne et fonctionnel ! 🚀**
