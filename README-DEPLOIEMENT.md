# 🚀 DÉPLOIEMENT HOMIFY - FICHIERS CRÉÉS

## ✅ Fichiers générés

| Fichier | Description | Usage |
|---------|-------------|-------|
| `nginx-homify-back.conf` | Configuration Nginx pour Django API | `/etc/nginx/sites-available/homify-back` |
| `nginx-homify-front.conf` | Configuration Nginx pour React frontend | `/etc/nginx/sites-available/homify-front` |
| `deploy-backend.sh` | Script de déploiement backend Django | `sudo ./deploy-backend.sh` |
| `deploy-frontend.sh` | Script de déploiement frontend React | `sudo ./deploy-frontend.sh` |
| `GUIDE-DEPLOIEMENT-COMPLET.md` | Documentation complète | Guide détaillé |

## 🎯 Actions à effectuer

### 1. Transfert vers votre serveur
```bash
# Transférer tous les fichiers vers votre serveur
scp *.conf deploy-*.sh user@votre-serveur:/tmp/homify/
```

### 2. Sur votre serveur (Ubuntu/Debian)
```bash
# Se connecter au serveur
ssh user@votre-serveur

# Aller dans le répertoire des fichiers
cd /tmp/homify

# Rendre les scripts exécutables
chmod +x *.sh

# Déployer le backend
sudo ./deploy-backend.sh

# Déployer le frontend  
sudo ./deploy-frontend.sh
```

## 🔗 URLs finales attendues

- **Frontend** : https://homify-front.supahuman.site
- **Backend API** : https://homify-back.supahuman.site/api/
- **Documentation** : https://homify-back.supahuman.site/api/docs/
- **Admin Django** : https://homify-back.supahuman.site/admin/

## ⚙️ Configuration incluse

### Sécurité
- ✅ Rate limiting (API: 10/s, Login: 5/min)
- ✅ Headers de sécurité (CSP, XSS, etc.)
- ✅ HTTPS forcé avec SSL Let's Encrypt
- ✅ Protection fichiers sensibles

### Performance  
- ✅ Compression Gzip + Brotli
- ✅ Cache optimisé pour assets
- ✅ Gunicorn (4 workers, 2 threads)
- ✅ Redis pour cache

### Monitoring
- ✅ Logs détaillés
- ✅ Sauvegardes automatiques (2h/3h)
- ✅ Health checks
- ✅ Status services

## 🛠️ Technologies utilisées

- **Backend** : Django + Gunicorn + PostgreSQL + Redis + Docker
- **Frontend** : React + Vite + Nginx  
- **Reverse Proxy** : Nginx avec SSL
- **Base de données** : PostgreSQL (Docker)
- **Cache** : Redis (Docker)
- **SSL** : Let's Encrypt + Auto-renewal

## 📋 Checklist post-déploiement

- [ ] Vérifier que les deux domaines répondent
- [ ] Tester l'API via https://homify-back.supahuman.site/api/
- [ ] Vérifier la documentation Swagger
- [ ] Tester le login admin Django
- [ ] Vérifier les sauvegardes
- [ ] Tester les mises à jour (scripts deploy.sh)

## 🆘 Support

En cas de problème, consultez :
1. **Logs** : `/var/www/homify-back/logs/` et `/var/log/nginx/`
2. **Status** : `sudo systemctl status nginx docker`
3. **Configuration** : Guide complet dans `GUIDE-DEPLOIEMENT-COMPLET.md`

---

**🎉 Votre infrastructure Homify est prête à être déployée !**
