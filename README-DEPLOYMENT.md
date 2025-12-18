# Guide de Déploiement Homify sur tmc.supahuman.site

## 📋 Prérequis

- Un serveur Ubuntu/Debian avec accès root
- Le domaine tmc.supahuman.site pointant vers votre serveur
- Une connexion internet pour télécharger les dépendances

## 🚀 Instructions de Déploiement

### 1. Préparation

```bash
# Connectez-vous à votre serveur en SSH
ssh root@your-server-ip

# Téléchargez les fichiers de déploiement
# (Copiez les fichiers deploy.sh et nginx.conf sur votre serveur)

# Rendez le script exécutable
chmod +x deploy.sh
```

### 2. Exécution du Script

```bash
# Exécutez le script de déploiement
sudo ./deploy.sh
```

Le script va :
- ✅ Mettre à jour le système
- ✅ Installer toutes les dépendances (Docker, NGINX, PostgreSQL, Redis, Node.js)
- ✅ Configurer la base de données
- ✅ Créer les répertoires nécessaires
- ✅ Configurer NGINX
- ✅ Configurer le firewall
- ✅ Créer les services systemd
- ✅ Configurer la rotation des logs

### 3. Configuration SSL (Optionnel)

Le script vous demandera si vous voulez configurer SSL avec Let's Encrypt :
- Répondez `y` pour activer HTTPS
- Répondez `n` pour garder HTTP seulement

### 4. Transfert de votre Code

Après l'exécution du script, copiez votre projet :

```bash
# Sur votre machine locale, copiez les fichiers du projet
scp -r /chemin/vers/homify/* root@your-server-ip:/var/www/homify/

# Ou utilisez rsync pour synchroniser
rsync -avz --progress /chemin/vers/homify/ root@your-server-ip:/var/www/homify/
```

Structure attendue sur le serveur :
```
/var/www/homify/
├── frontend/          # Code React/Vite
├── backend/           # Code Django
├── nginx.conf         # Configuration NGINX
└── logs/              # Logs de l'application
```

## 🔧 Configuration Post-Déploiement

### 1. Variables d'Environnement

Éditez le fichier `.env` du backend :
```bash
nano /var/www/homify/backend/.env
```

Modifiez les variables suivantes :
```env
SECRET_KEY=votre-cle-secrete-unique
EMAIL_HOST_USER=votre-email@gmail.com
EMAIL_HOST_PASSWORD=votre-mot-de-passe-app-gmail
DATABASE_URL=postgresql://homify_user:votre_mot_de_passe@localhost:5432/homify_db
```

### 2. Base de Données

Créez un superutilisateur Django :
```bash
cd /var/www/homify/backend
python3 manage.py createsuperuser
```

### 3. Test du Déploiement

Vérifiez que tous les services fonctionnent :
```bash
# Vérifier les services systemd
systemctl status homify-backend
systemctl status nginx

# Tester l'accès web
curl -I http://tmc.supahuman.site
curl -I http://tmc.supahuman.site/api/
```

## 📊 URLs d'Accès

Après le déploiement réussi :

- **Site Principal** : http://tmc.supahuman.site
- **API Backend** : http://tmc.supahuman.site/api/
- **Admin Django** : http://tmc.supahuman.site/admin/
- **Documentation API** : http://tmc.supahuman.site/docs/

## 🛠️ Commandes de Maintenance

### Gestion des Services

```bash
# Redémarrer le backend
systemctl restart homify-backend

# Redémarrer NGINX
systemctl restart nginx

# Voir les logs du backend
journalctl -u homify-backend -f

# Voir les logs NGINX
tail -f /var/log/nginx/homify_access.log
tail -f /var/log/nginx/homify_error.log
```

### Mise à Jour du Code

```bash
# Arrêter les services
systemctl stop homify-backend

# Mettre à jour le code
cd /var/www/homify
git pull origin main  # ou copier les nouveaux fichiers

# Reconstruire le frontend (si nécessaire)
cd frontend
npm run build

# Appliquer les migrations Django (si nécessaire)
cd ../backend
python3 manage.py migrate
python3 manage.py collectstatic --noinput

# Redémarrer les services
systemctl start homify-backend
systemctl reload nginx
```

### Sauvegarde

```bash
# Sauvegarder la base de données
sudo -u postgres pg_dump homify_db > /var/www/homify/backups/db_backup_$(date +%Y%m%d_%H%M%S).sql

# Sauvegarder les fichiers media
tar -czf /var/www/homify/backups/media_backup_$(date +%Y%m%d_%H%M%S).tar.gz /var/www/homify/backend/media/
```

## 🔒 Sécurité

### Firewall
Le firewall UFW est configuré avec :
- SSH (port 22)
- HTTP (port 80)
- HTTPS (port 443)
- Accès local au backend (port 8000)

### Fichiers Sensibles
Les fichiers suivants contiennent des informations sensibles :
- `/var/www/homify/backend/.env` - Variables d'environnement
- Certificats SSL dans `/etc/letsencrypt/`

## 🐛 Dépannage

### Problèmes Courants

**1. Le site ne se charge pas**
```bash
# Vérifier les logs
journalctl -u homify-backend -n 50
tail -n 50 /var/log/nginx/homify_error.log

# Vérifier les services
systemctl status nginx
systemctl status homify-backend
```

**2. Erreur 502 Bad Gateway**
```bash
# Vérifier que le backend fonctionne
curl http://127.0.0.1:8000

# Redémarrer le backend
systemctl restart homify-backend
```

**3. Problèmes de permissions**
```bash
# Réparer les permissions
chown -R www-data:www-data /var/www/homify
chmod -R 755 /var/www/homify
```

**4. Base de données inaccessible**
```bash
# Vérifier PostgreSQL
systemctl status postgresql
sudo -u postgres psql -l

# Tester la connexion
sudo -u postgres psql -U homify_user -d homify_db -h localhost
```

## 📞 Support

Si vous rencontrez des problèmes :

1. Consultez les logs avec les commandes ci-dessus
2. Vérifiez que tous les services sont actifs
3. Assurez-vous que les variables d'environnement sont correctes
4. Vérifiez que le domaine pointe bien vers votre serveur

## 🔄 Mises à Jour

Pour mettre à jour le déploiement :

1. Sauvegardez vos données
2. Copiez les nouveaux fichiers
3. Exécutez les migrations si nécessaire
4. Redémarrez les services

Le script `deploy.sh` peut être réexécuté en mode "mise à jour" en commentant les parties d'installation initiales.
