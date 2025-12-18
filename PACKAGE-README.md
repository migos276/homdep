# 🚀 Package de Déploiement Homify pour tmc.supahuman.site

## 📦 Contenu du Package

Ce package contient tous les fichiers nécessaires pour déployer votre projet Homify sur le domaine **tmc.supahuman.site** avec NGINX :

### Fichiers de Configuration
- **`nginx.conf`** - Configuration NGINX complète avec reverse proxy
- **`backend.env.template`** - Template pour les variables d'environnement Django

### Scripts de Déploiement
- **`deploy.sh`** - Script complet de déploiement (recommandé)
- **`quick-deploy.sh`** - Script de déploiement rapide
- **`check-deployment.sh`** - Script de vérification post-déploiement

### Documentation
- **`README-DEPLOYMENT.md`** - Guide complet de déploiement
- **`PACKAGE-README.md`** - Ce fichier

## 🎯 Déploiement Rapide

### Option 1 : Déploiement Complet (Recommandé)
```bash
# 1. Copiez tous les fichiers sur votre serveur
scp nginx.conf deploy.sh check-deployment.sh backend.env.template root@your-server:/tmp/

# 2. Connectez-vous au serveur
ssh root@your-server

# 3. Exécutez le script de déploiement
cd /tmp
chmod +x deploy.sh check-deployment.sh
sudo ./deploy.sh

# 4. Copiez votre code source
# (Voir instructions dans README-DEPLOYMENT.md)

# 5. Vérifiez le déploiement
sudo ./check-deployment.sh
```


### Option 2 : Déploiement Rapide Complet (Recommandé pour déploiement immédiat)
```bash
# 1. Copiez TOUS les fichiers du projet sur le serveur
# IMPORTANT : Incluez les dossiers src/, backend_homify/, et tous les fichiers de config
scp -r nginx.conf quick-deploy.sh backend.env.template src/ backend_homify/ package.json vite.config.ts tailwind.config.js *.json *.md *.png root@your-server:/tmp/

# 2. Exécutez le déploiement rapide complet
ssh root@your-server
cd /tmp
chmod +x quick-deploy.sh
sudo ./quick-deploy.sh

# Le script va automatiquement :
# - Installer toutes les dépendances (NGINX, PostgreSQL, Redis, Node.js)
# - Copier le frontend (src/, package.json, etc.) et le construire avec npm
# - Copier le backend (backend_homify/) et le configurer avec Django
# - Configurer la base de données PostgreSQL
# - Configurer NGINX pour servir le frontend et proxy vers l'API Django
# - Démarrer tous les services
# - Votre site sera immédiatement disponible sur tmc.supahuman.site
```

## 🔧 Configuration Requise

### 1. Variables d'Environnement
Copiez `backend.env.template` vers `/var/www/homify/backend/.env` et modifiez :
- `SECRET_KEY` - Clé secrète Django unique
- `EMAIL_HOST_USER` - Votre email
- `EMAIL_HOST_PASSWORD` - Mot de passe d'application Gmail
- `DATABASE_URL` - Credentials de base de données

### 2. Transfert du Code
Structure attendue sur le serveur :
```
/var/www/homify/
├── frontend/          # Code React/Vite (built)
├── backend/           # Code Django
├── logs/              # Logs de l'application
└── backups/           # Sauvegardes
```

## 🌐 URLs d'Accès

Après déploiement réussi :
- **Site Principal** : http://tmc.supahuman.site
- **API Backend** : http://tmc.supahuman.site/api/
- **Admin Django** : http://tmc.supahuman.site/admin/

## 🛠️ Commandes de Maintenance

```bash
# Redémarrer les services
sudo systemctl restart homify-backend nginx

# Voir les logs
sudo journalctl -u homify-backend -f
sudo tail -f /var/log/nginx/homify_access.log

# Vérifier le statut
sudo ./check-deployment.sh

# Mettre à jour le code
cd /var/www/homify
git pull origin main
sudo systemctl restart homify-backend
```

## 🔒 Sécurité

Le déploiement inclut :
- ✅ Configuration firewall UFW
- ✅ Headers de sécurité NGINX
- ✅ Configuration SSL (optionnel avec Let's Encrypt)
- ✅ Variables d'environnement sécurisées
- ✅ Permissions de fichiers appropriées

## 📋 Checklist de Déploiement

- [ ] Domaine tmc.supahuman.site pointe vers le serveur
- [ ] Script de déploiement exécuté avec succès
- [ ] Code source copié sur le serveur
- [ ] Variables d'environnement configurées
- [ ] Base de données initialisée
- [ ] Frontend construit et déployé
- [ ] Backend configuré et démarré
- [ ] NGINX configuré et actif
- [ ] Tests d'accès web réussis
- [ ] SSL configuré (optionnel)

## 🆘 Support

En cas de problème :
1. Consultez le `README-DEPLOYMENT.md` pour le guide détaillé
2. Exécutez `./check-deployment.sh` pour diagnostiquer
3. Vérifiez les logs avec les commandes ci-dessus
4. Assurez-vous que le domaine pointe correctement

## 📞 Prochaines Étapes

1. **Préparation** : Configurez votre serveur Ubuntu/Debian
2. **Déploiement** : Utilisez `deploy.sh` ou `quick-deploy.sh`
3. **Configuration** : Personnalisez les variables d'environnement
4. **Tests** : Vérifiez avec `check-deployment.sh`
5. **Production** : Configurez SSL et optimisez les performances

---

**Votre projet Homify sera bientôt en ligne sur tmc.supahuman.site ! 🎉**
