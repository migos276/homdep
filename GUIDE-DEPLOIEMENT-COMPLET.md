# Guide Complet de Déploiement - Homify

## 📋 Vue d'ensemble

J'ai créé tous les fichiers nécessaires pour déployer vos projets Homify sur vos domaines :

### Fichiers créés :
1. **nginx-homify-back.conf** - Configuration Nginx pour le backend Django
2. **nginx-homify-front.conf** - Configuration Nginx pour le frontend React  
3. **deploy-backend.sh** - Script automatisé pour déployer le backend
4. **deploy-frontend.sh** - Script automatisé pour déployer le frontend

## 🏗️ Architecture de déploiement

```
Internet
├── homify-back.supahuman.site
│   ├── Nginx (Reverse Proxy)
│   ├── Django API (Port 8000)
│   ├── PostgreSQL (Port 5432)
│   ├── Redis (Port 6379)
│   └── Static/Media files
│
└── homify-front.supahuman.site
    ├── Nginx (Static Files Server)
    ├── React Build (dist/)
    └── Proxy API vers backend
```

## 🚀 Instructions de déploiement

### Prérequis
- Serveur Ubuntu/Debian
- Accès root (sudo)
- Domaines pointant vers votre serveur
- Ports 80/443 ouverts

### Étapes de déploiement

#### 1. Préparation du serveur
```bash
# Se connecter au serveur en SSH
ssh user@votre-serveur

# Télécharger les fichiers
# (Vous devez transférer les fichiers créés vers votre serveur)

# Rendre les scripts exécutables
chmod +x deploy-backend.sh deploy-frontend.sh
```

#### 2. Déploiement du Backend (homify-back.supahuman.site)
```bash
# Exécuter le script de déploiement backend
sudo ./deploy-backend.sh
```

Ce script va :
- ✅ Installer Docker, Python, PostgreSQL, Redis
- ✅ Configurer l'utilisateur système `homify-backend`
- ✅ Déployer Django avec Gunicorn
- ✅ Configurer Nginx avec rate limiting
- ✅ Installer les certificats SSL Let's Encrypt
- ✅ Configurer les sauvegardes automatiques
- ✅ Créer le superutilisateur Django

#### 3. Déploiement du Frontend (homify-front.supahuman.site)
```bash
# Exécuter le script de déploiement frontend
sudo ./deploy-frontend.sh
```

Ce script va :
- ✅ Installer Node.js, npm, yarn
- ✅ Copier et build le projet React
- ✅ Configurer Nginx pour les fichiers statiques
- ✅ Configurer le proxy vers l'API
- ✅ Installer les certificats SSL
- ✅ Optimiser les performances

## 🔧 Configuration détaillée

### Variables d'environnement Backend

Le script créera automatiquement un fichier `.env` avec :

```env
DEBUG=False
SECRET_KEY=générée-automatiquement
ALLOWED_HOSTS=homify-back.supahuman.site,localhost,127.0.0.1

# Database
DB_NAME=homify_db
DB_USER=homify_user
DB_PASSWORD=générée-automatiquement
DB_HOST=db
DB_PORT=5432

# Redis
REDIS_URL=redis://redis:6379/0

# CORS
CORS_ALLOWED_ORIGINS=https://homify-front.supahuman.site
CSRF_TRUSTED_ORIGINS=https://homify-front.supahuman.site
```

### Variables d'environnement Frontend

```env
VITE_API_URL=https://homify-back.supahuman.site/api
VITE_APP_NAME=Homify
VITE_APP_VERSION=1.0.0
VITE_APP_ENV=production
```

## 🔐 Sécurité implémentée

### Rate Limiting
- **API** : 10 requêtes/seconde par IP
- **Login** : 5 tentatives/minute par IP
- **Frontend** : 30 requêtes/seconde par IP

### Headers de sécurité
- X-Frame-Options: SAMEORIGIN
- X-XSS-Protection: 1; mode=block
- X-Content-Type-Options: nosniff
- Content-Security-Policy configurée
- HTTPS forcé

### Protection des fichiers
- Accès bloqué aux fichiers sensibles (.env, .log, .sql)
- Upload sécurisé avec validation d'extension
- Taille maximum : 100MB

## 📊 Monitoring et logs

### Fichiers de logs
```bash
# Backend
tail -f /var/www/homify-back/logs/django.log
docker-compose -f /var/www/homify-back/docker-compose.prod.yml logs -f

# Frontend  
tail -f /var/log/nginx/homify-front-access.log
tail -f /var/log/nginx/homify-front-error.log
```

### Status des services
```bash
sudo systemctl status nginx
sudo systemctl status docker
sudo docker-compose -f /var/www/homify-back/docker-compose.prod.yml ps
```

## 💾 Sauvegardes automatiques

### Backend
- **Base de données** : Sauvegarde quotidienne à 2h00
- **Fichiers media** : Sauvegarde quotidienne à 2h00
- **Rétention** : 30 jours

### Frontend
- **Build** : Sauvegarde quotidienne à 3h00
- **Rétention** : 30 jours

## 🔄 Déploiement de mises à jour

### Backend
```bash
cd /var/www/homify-back
sudo -u homify-backend git pull origin main  # Si Git
# Ou copier manuellement les nouveaux fichiers
docker-compose -f docker-compose.prod.yml up -d --build
```

### Frontend
```bash
sudo /var/www/homify-front/deploy.sh
```

## 🛠️ Commandes utiles

### Gestion des services
```bash
# Redémarrer le backend
sudo docker-compose -f /var/www/homify-back/docker-compose.prod.yml restart

# Redémarrer Nginx
sudo systemctl reload nginx

# Voir les processus Docker
sudo docker ps

# Gestion des volumes
sudo docker volume ls
```

### Base de données
```bash
# Se connecter à PostgreSQL
sudo docker-compose -f /var/www/homify-back/docker-compose.prod.yml exec db psql -U homify_user homify_db

# Sauvegarde manuelle
sudo /var/www/homify-back/backup.sh

# Restaurer une sauvegarde
sudo docker-compose -f /var/www/homify-back/docker-compose.prod.yml exec -T db psql -U homify_user homify_db < backup.sql
```

### SSL/Certificats
```bash
# Vérifier les certificats
sudo certbot certificates

# Renouveler manuellement
sudo certbot renew

# Status du renouvellement automatique
sudo systemctl status certbot.timer
```

## 🔧 Dépannage

### Problèmes courants

#### 1. Backend inaccessible
```bash
# Vérifier les logs
sudo docker-compose -f /var/www/homify-back/docker-compose.prod.yml logs web

# Vérifier la base de données
sudo docker-compose -f /var/www/homify-back/docker-compose.prod.yml logs db

# Tester la connectivité
curl -v http://localhost:8000/api/
```

#### 2. Frontend ne charge pas
```bash
# Vérifier la configuration Nginx
sudo nginx -t

# Voir les logs d'erreur
sudo tail -f /var/log/nginx/homify-front-error.log

# Vérifier les fichiers build
ls -la /var/www/homify-front/dist/
```

#### 3. Problèmes SSL
```bash
# Vérifier les certificats
sudo certbot certificates

# Re-générer un certificat
sudo certbot delete --cert-name homify-back.supahuman.site
sudo certbot --nginx -d homify-back.supahuman.site
```

#### 4. Erreurs CORS
- Vérifier `ALLOWED_HOSTS` dans le backend
- Vérifier `CORS_ALLOWED_ORIGINS` dans le backend
- S'assurer que les domaines sont exacts

## 📈 Optimisations de performance

### Backend
- **Gunicorn** : 4 workers, 2 threads
- **Redis** : Cache et sessions
- **PostgreSQL** : Optimisations de configuration
- **Static files** : Servis par Nginx

### Frontend  
- **Build optimisé** : Vite production build
- **Compression** : Gzip + Brotli
- **Cache** : Headers optimisés pour les assets
- **CDN** : Prêt pour CloudFlare

## 🌐 URLs finales

Après déploiement :

- **Frontend** : https://homify-front.supahuman.site
- **Backend API** : https://homify-back.supahuman.site/api/
- **Documentation API** : https://homify-back.supahuman.site/api/docs/
- **Admin Django** : https://homify-back.supahuman.site/admin/

## ✅ Checklist de vérification

### Backend
- [ ] Nginx configuré et démarré
- [ ] Django accessible via HTTPS
- [ ] Base de données fonctionnelle
- [ ] Redis connecté
- [ ] Certificat SSL valide
- [ ] Superutilisateur créé
- [ ] Migrations appliquées
- [ ] Fichiers statiques collectés

### Frontend
- [ ] Site accessible via HTTPS
- [ ] Build React fonctionnel
- [ ] API calls vers le backend
- [ ] Certificat SSL valide
- [ ] Assets optimisés
- [ ] Routes SPA configurées

## 🚨 Points d'attention

1. **Mots de passe** : Changez les mots de passe générés automatiquement
2. **Email** : Configurez un vrai serveur email pour les notifications
3. **Monitoring** : Envisagez d'ajouter un système de monitoring (Prometheus, Grafana)
4. **Backups** : Testez régulièrement la restauration des sauvegardes
5. **Logs** : Surveillez les logs pour détecter les problèmes tôt
6. **Sécurité** : Mettez à jour régulièrement les packages système

## 📞 Support

En cas de problème :
1. Consultez les logs : `/var/www/homify-back/logs/` et `/var/log/nginx/`
2. Vérifiez les services : `systemctl status nginx docker`
3. Testez la connectivité : `curl` vers les endpoints
4. Vérifiez les certificats : `certbot certificates`

Tous les scripts incluent une gestion d'erreurs et des messages de statut détaillés pour faciliter le dépannage.
