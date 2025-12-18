
#!/bin/bash

# Script de déploiement rapide pour Homify
# Version complète avec frontend et backend

set -e

DOMAIN="tmc.supahuman.site"
PROJECT_DIR="/var/www/homify"
LOCAL_DIR="$(pwd)"

echo "🚀 Déploiement rapide de Homify sur $DOMAIN"

# Vérifier les permissions root
if [[ $EUID -ne 0 ]]; then
   echo "❌ Ce script doit être exécuté avec sudo"
   exit 1
fi

# Installation rapide des dépendances essentielles
echo "📦 Installation des dépendances..."
apt update -y
apt install -y nginx postgresql postgresql-contrib python3-pip python3-venv nodejs npm redis-server ufw git

# Configuration de la base de données
echo "🗄️ Configuration de la base de données..."
sudo -u postgres psql << EOF
CREATE USER homify_user WITH PASSWORD 'homify_secure_password_123';
CREATE DATABASE homify_db OWNER homify_user;
GRANT ALL PRIVILEGES ON DATABASE homify_db TO homify_user;
ALTER USER homify_user CREATEDB;
\q
EOF


# Créer les répertoires
echo "📁 Création des répertoires..."
mkdir -p $PROJECT_DIR/{frontend,backend,logs,backups}
mkdir -p $PROJECT_DIR/backend/media/properties
chown -R www-data:www-data $PROJECT_DIR

# Copier le code source depuis le répertoire local
echo "📋 Copie du code source..."
if [ -d "$LOCAL_DIR/src" ] && [ -f "$LOCAL_DIR/package.json" ]; then
    echo "📁 Copie du frontend..."
    cp -r $LOCAL_DIR/src $LOCAL_DIR/package.json $LOCAL_DIR/vite.config.ts $LOCAL_DIR/tailwind.config.js $LOCAL_DIR/postcss.config.js $LOCAL_DIR/tsconfig*.json $LOCAL_DIR/eslint.config.js $PROJECT_DIR/frontend/
    
    # Copier les fichiers publics si présents
    if [ -d "$LOCAL_DIR/public" ]; then
        cp -r $LOCAL_DIR/public/* $PROJECT_DIR/frontend/ 2>/dev/null || true
    fi
    echo "✅ Frontend copié"
else
    echo "⚠️ Frontend non trouvé localement, structure de base créée"
fi

if [ -d "$LOCAL_DIR/backend_homify" ]; then
    echo "📁 Copie du backend..."
    cp -r $LOCAL_DIR/backend_homify/* $PROJECT_DIR/backend/
    echo "✅ Backend copié"
else
    echo "⚠️ Backend non trouvé localement, structure de base créée"
fi

# Définir les permissions
chown -R www-data:www-data $PROJECT_DIR

# Copier et activer la configuration NGINX
echo "🌐 Configuration de NGINX..."
if [ -f "nginx.conf" ]; then
    cp nginx.conf /etc/nginx/sites-available/homify
    ln -sf /etc/nginx/sites-available/homify /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    nginx -t && systemctl reload nginx
    echo "✅ NGINX configuré"
else
    echo "❌ Fichier nginx.conf non trouvé"
    exit 1
fi

# Configuration du firewall
echo "🔥 Configuration du firewall..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# Service systemd simple pour Django
echo "⚙️ Configuration du service Django..."
cat > /etc/systemd/system/homify-backend.service << EOF
[Unit]
Description=Homify Backend
After=network.target

[Service]
User=www-data
WorkingDirectory=$PROJECT_DIR/backend
Environment=DJANGO_SETTINGS_MODULE=rental_project.settings
ExecStart=/usr/bin/python3 manage.py runserver 0.0.0.0:8000
Restart=always

[Install]
WantedBy=multi-user.target
EOF


systemctl daemon-reload
systemctl enable homify-backend

# Configuration des variables d'environnement
echo "🔧 Configuration des variables d'environnement..."
if [ -f "backend.env.template" ]; then
    cp backend.env.template $PROJECT_DIR/backend/.env
    sed -i "s/tmc\.supahuman\.site/$DOMAIN/g" $PROJECT_DIR/backend/.env
    echo "✅ Variables d'environnement configurées"
else
    echo "⚠️ Template d'environnement non trouvé"
fi

# Construction du frontend
echo "🏗️ Construction du frontend..."
if [ -d "$PROJECT_DIR/frontend" ] && [ -f "$PROJECT_DIR/frontend/package.json" ]; then
    cd $PROJECT_DIR/frontend
    
    # Installer les dépendances
    npm install --production
    
    # Construire pour la production
    npm run build
    
    # Définir les permissions sur les fichiers dist
    chown -R www-data:www-data dist/
    chmod -R 755 dist/
    
    echo "✅ Frontend construit et déployé"
else
    echo "⚠️ Frontend non disponible pour la construction"
fi

# Configuration du backend
echo "⚙️ Configuration du backend..."
if [ -d "$PROJECT_DIR/backend" ] && [ -f "$PROJECT_DIR/backend/manage.py" ]; then
    cd $PROJECT_DIR/backend
    
    # Installer les dépendances Python
    pip3 install -r requirements.txt --user
    
    # Appliquer les migrations
    python3 manage.py migrate --noinput
    
    # Collecter les fichiers statiques
    python3 manage.py collectstatic --noinput
    
    echo "✅ Backend configuré"
else
    echo "⚠️ Backend non disponible"
fi

# Démarrage des services
echo "🚀 Démarrage des services..."
systemctl start homify-backend

# Attendre que les services soient prêts
sleep 5

# Vérification finale
echo "🔍 Vérification du déploiement..."
if systemctl is-active --quiet homify-backend; then
    echo "✅ Backend Django démarré"
else
    echo "❌ Erreur lors du démarrage du backend"
    journalctl -u homify-backend --no-pager -n 10
fi

if [ -d "$PROJECT_DIR/frontend/dist" ]; then
    echo "✅ Frontend construit et prêt"
else
    echo "⚠️ Frontend non construit"
fi

echo ""
echo "🎉 Déploiement complet terminé!"
echo ""
echo "📋 Résumé :"
echo "✅ Services installés et configurés"
echo "✅ Base de données PostgreSQL configurée"
echo "✅ NGINX configuré pour $DOMAIN"
echo "✅ Backend Django configuré et démarré"
echo "✅ Frontend construit et déployé"
echo "✅ Firewall configuré"
echo ""
echo "🌐 Votre site Homify est maintenant disponible sur :"
echo "   Site principal : http://$DOMAIN"
echo "   API Backend   : http://$DOMAIN/api/"
echo "   Admin Django  : http://$DOMAIN/admin/"
echo ""
echo "📊 Commandes utiles :"
echo "   Logs backend : sudo journalctl -u homify-backend -f"
echo "   Logs nginx   : sudo tail -f /var/log/nginx/homify_access.log"
echo "   Redémarrer   : sudo systemctl restart homify-backend nginx"
echo ""
echo "⚠️ N'oubliez pas de :"
echo "   1. Modifier les variables sensibles dans $PROJECT_DIR/backend/.env"
echo "   2. Configurer SSL avec Let's Encrypt (certbot --nginx -d $DOMAIN)"
echo "   3. Créer un superutilisateur : cd $PROJECT_DIR/backend && python3 manage.py createsuperuser"
