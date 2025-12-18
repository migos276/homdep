# Plan de Déploiement Homify

## Vue d'ensemble
Déploiement de deux applications sur des domaines séparés :
- **homify-back.supahuman.site** : API Backend Django
- **homify-front.supahuman.site** : Interface Frontend React

## Architecture de déploiement

```
Internet
    |
    ├── homify-front.supahuman.site (Nginx + Static files)
    │   └── Build React (dist/)
    │
    └── homify-back.supahuman.site (Nginx + Django + PostgreSQL + Redis)
        ├── Django API (port 8000)
        ├── PostgreSQL (port 5432)
        ├── Redis (port 6379)
        └── Static/Media files
```

## Configuration requise

### Backend (homify-back.supahuman.site)
- **Port interne Django** : 8000
- **Base de données** : PostgreSQL (production)
- **Cache** : Redis
- **Fichiers statiques** : /var/www/homify-back/static/
- **Fichiers media** : /var/www/homify-back/media/

### Frontend (homify-front.supahuman.site)
- **Port interne Nginx** : 80/443
- **Fichiers statiques** : /var/www/homify-front/dist/
- **Build React** : Production ready

## Fichiers à créer

1. **nginx-homify-back.conf** : Configuration Nginx pour l'API
2. **nginx-homify-front.conf** : Configuration Nginx pour le frontend
3. **deploy-backend.sh** : Script de déploiement du backend
4. **deploy-frontend.sh** : Script de déploiement du frontend

## Variables d'environnement à configurer

### Backend
- DEBUG=False
- ALLOWED_HOSTS=homify-back.supahuman.site
- DATABASE_URL (PostgreSQL production)
- SECRET_KEY (production)
- REDIS_URL

### Frontend  
- VITE_API_URL=https://homify-back.supahuman.site/api

## Étapes de déploiement

1. **Installation des prérequis** (Nginx, Docker, Node.js, Python)
2. **Configuration de la base de données PostgreSQL**
3. **Déploiement du backend Django**
4. **Build et déploiement du frontend React**
5. **Configuration des certificats SSL**
6. **Tests de fonctionnement**
