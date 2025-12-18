#!/bin/bash

# Script de déploiement du Frontend React Homify
# Domaine: homify-front.supahuman.site
# Usage: sudo ./deploy-frontend.sh

set -e  # Arrêter en cas d'erreur

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction d'affichage avec couleur
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Vérifier les droits root
if [ "$EUID" -ne 0 ]; then 
    print_error "Ce script doit être exécuté en tant que root (sudo)"
    exit 1
fi

print_status "=== Début du déploiement du Frontend Homify ==="

# Variables
DOMAIN="homify-front.supahuman.site"
BACKEND_DOMAIN="homify-back.supahuman.site"
APP_DIR="/var/www/homify-front"
BUILD_DIR="/home/migos/Bureau/INFO L3/TP/Homify-final/dist"
NGINX_CONFIG="/etc/nginx/sites-available/homify-front"
NGINX_ENABLED="/etc/nginx/sites-enabled/homify-front"
BACKUP_DIR="/var/backups/homify-front"
PROJECT_NAME="homify-frontend"

# 1. Mise à jour du système
print_status "Mise à jour du système..."
apt update && apt upgrade -y

# 2. Installation des dépendances de base
print_status "Installation des dépendances de base..."
apt install -y curl wget git unzip nginx certbot python3-certbot-nginx

# 3. Installation de Node.js et npm
print_status "Installation de Node.js..."
if ! command -v node &> /dev/null; then
    # Installation de Node.js 18.x (LTS)
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt install -y nodejs
    
    # Installation de Yarn comme alternative à npm
    npm install -g yarn
    npm install -g pm2
    
    print_success "Node.js et npm installés"
else
    print_success "Node.js déjà installé: $(node --version)"
fi

# Vérification des versions
print_status "Versions installées:"
print_status "Node.js: $(node --version)"
print_status "npm: $(npm --version)"
print_status "Yarn: $(yarn --version)"
print_status "PM2: $(pm2 --version)"

# 4. Création de l'utilisateur système
print_status "Création de l'utilisateur système..."
if ! id "$PROJECT_NAME" &>/dev/null; then
    useradd -r -s /bin/bash -d $APP_DIR -m $PROJECT_NAME
    print_success "Utilisateur $PROJECT_NAME créé"
else
    print_warning "Utilisateur $PROJECT_NAME existe déjà"
fi

# 5. Création des répertoires
print_status "Création des répertoires..."
mkdir -p $APP_DIR
mkdir -p $APP_DIR/build
mkdir -p $APP_DIR/logs
mkdir -p $BACKUP_DIR
mkdir -p $BUILD_DIR
chown -R $PROJECT_NAME:$PROJECT_NAME $APP_DIR
chown -R $PROJECT_NAME:$PROJECT_NAME $BACKUP_DIR

# 6. Copie des fichiers du projet
print_status "Copie des fichiers du projet frontend..."
if [ -d "/home/$SUDO_USER/Bureau/INFO L3/TP/Homify-final" ]; then
    # Copier les fichiers source
    cp -r /home/$SUDO_USER/Bureau/INFO L3/TP/Homify-final/src $APP_DIR/
    cp -r /home/$SUDO_USER/Bureau/INFO L3/TP/Homify-final/public $APP_DIR/ 2>/dev/null || true
    cp /home/$SUDO_USER/Bureau/INFO L3/TP/Homify-final/package.json $APP_DIR/
    cp /home/$SUDO_USER/Bureau/INFO L3/TP/Homify-final/package-lock.json $APP_DIR/ 2>/dev/null || true
    cp /home/$SUDO_USER/Bureau/INFO L3/TP/Homify-final/vite.config.ts $APP_DIR/ 2>/dev/null || true
    cp /home/$SUDO_USER/Bureau/INFO L3/TP/Homify-final/tailwind.config.js $APP_DIR/ 2>/dev/null || true
    cp /home/$SUDO_USER/Bureau/INFO L3/TP/Homify-final/postcss.config.js $APP_DIR/ 2>/dev/null || true
    cp /home/$SUDO_USER/Bureau/INFO L3/TP/Homify-final/tsconfig.json $APP_DIR/ 2>/dev/null || true
    
    chown -R $PROJECT_NAME:$PROJECT_NAME $APP_DIR
    print_success "Fichiers du frontend copiés"
else
    print_error "Répertoire du frontend non trouvé"
    exit 1
fi

# 7. Installation des dépendances Node.js
print_status "Installation des dépendances Node.js..."
cd $APP_DIR
sudo -u $PROJECT_NAME npm install

# 8. Configuration des variables d'environnement pour le build
print_status "Configuration des variables d'environnement..."
cat > $APP_DIR/.env.production << EOF
VITE_API_URL=https://$BACKEND_DOMAIN/api
VITE_APP_NAME=Homify
VITE_APP_VERSION=1.0.0
VITE_APP_ENV=production
EOF

chown $PROJECT_NAME:$PROJECT_NAME $APP_DIR/.env.production

# 9. Build du projet React
print_status "Build du projet React..."
cd $APP_DIR
sudo -u $PROJECT_NAME npm run build

# Vérifier que le build s'est bien passé
if [ ! -d "$APP_DIR/dist" ]; then
    print_error "Le build a échoué - répertoire dist non trouvé"
    exit 1
fi

print_success "Build terminé avec succès"

# 10. Configuration Nginx
print_status "Configuration Nginx..."
cp /home/$SUDO_USER/Bureau/INFO L3/TP/Homify-final/nginx-homify-front.conf $NGINX_CONFIG

# Remplacer les références aux domaines dans la config
sed -i "s/homify-front.supahuman.site/$DOMAIN/g" $NGINX_CONFIG
sed -i "s/homify-back.supahuman.site/$BACKEND_DOMAIN/g" $NGINX_CONFIG

# Activation du site
ln -sf $NGINX_CONFIG $NGINX_ENABLED
rm -f /etc/nginx/sites-enabled/default

# Test de la configuration Nginx
nginx -t

# 11. Configuration des répertoires web
print_status "Configuration des répertoires web..."
ln -sf $APP_DIR/dist $APP_DIR/build/current
chown -R $PROJECT_NAME:www-data $APP_DIR/build
chmod -R 755 $APP_DIR/build

# 12. Configuration du firewall
print_status "Configuration du firewall..."
if command -v ufw &> /dev/null; then
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw --force enable
    print_success "Firewall configuré"
fi

# 13. Démarrage de Nginx
print_status "Démarrage de Nginx..."
systemctl restart nginx
systemctl enable nginx

# 14. Configuration SSL avec Let's Encrypt
print_status "Configuration SSL..."
if [ ! -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email admin@supahuman.site
    # Renouvellement automatique
    (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
else
    print_success "Certificat SSL déjà existant"
fi

# 15. Configuration PM2 pour la gestion des processus (optionnel)
print_status "Configuration PM2..."
cat > $APP_DIR/ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: 'homify-frontend',
    script: 'serve',
    args: '-s dist -l 3000',
    cwd: '$APP_DIR',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    }
  }]
};
EOF

chown $PROJECT_NAME:$PROJECT_NAME $APP_DIR/ecosystem.config.js

# 16. Configuration des logs
print_status "Configuration des logs..."
cat > /etc/logrotate.d/homify-front << EOF
$APP_DIR/logs/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 $PROJECT_NAME $PROJECT_NAME
    postrotate
        systemctl reload nginx
    endscript
}
EOF

# 17. Script de déploiement automatique
print_status "Création du script de déploiement..."
cat > $APP_DIR/deploy.sh << EOF
#!/bin/bash
set -e

echo "=== Déploiement Homify Frontend ==="

# Mise à jour du code
cd /home/$SUDO_USER/Bureau/INFO L3/TP/Homify-final
git pull origin main 2>/dev/null || echo "Pas de repository Git, utilisation des fichiers locaux"

# Copie des nouveaux fichiers
cp -r src /var/www/homify-front/
cp package*.json /var/www/homify-front/
cp vite.config.ts /var/www/homify-front/ 2>/dev/null || true

# Installation des nouvelles dépendances
cd /var/www/homify-front
sudo -u homify-frontend npm install

# Build
sudo -u homify-frontend npm run build

# Mise à jour des liens
rm -f /var/www/homify-front/build/current
ln -sf /var/www/homify-front/dist /var/www/homify-front/build/current

# Redémarrage de Nginx
systemctl reload nginx

echo "Déploiement terminé!"
EOF

chmod +x $APP_DIR/deploy.sh
chown $PROJECT_NAME:$PROJECT_NAME $APP_DIR/deploy.sh

# 18. Script de sauvegarde
print_status "Création du script de sauvegarde..."
cat > $APP_DIR/backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/var/backups/homify-front"
DATE=$(date +%Y%m%d_%H%M%S)

# Sauvegarde des fichiers build
tar -czf "$BACKUP_DIR/build_backup_$DATE.tar.gz" /var/www/homify-front/dist/

# Nettoyage des anciennes sauvegardes (plus de 30 jours)
find $BACKUP_DIR -name "*.tar.gz" -mtime +30 -delete

echo "Sauvegarde créée: $DATE"
EOF

chmod +x $APP_DIR/backup.sh
chown $PROJECT_NAME:$PROJECT_NAME $APP_DIR/backup.sh

# 19. Tâche de sauvegarde automatique
(crontab -l 2>/dev/null; echo "0 3 * * * $APP_DIR/backup.sh >> $APP_DIR/logs/backup.log 2>&1") | crontab -

# 20. Optimisations de performance
print_status "Optimisations de performance..."

# Compression Brotli (si disponible)
if command -v brotli &> /dev/null; then
    find $APP_DIR/dist -type f -name "*.js" -o -name "*.css" -o -name "*.html" | xargs brotli --best
    print_success "Compression Brotli appliquée"
fi

# Cache des headers
cat > /etc/nginx/conf.d/cache.conf << EOF
# Cache configuration pour les assets statiques
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
    add_header Vary "Accept-Encoding";
    access_log off;
}
EOF

# 21. Tests finaux
print_status "Tests finaux..."

# Test Nginx
if systemctl is-active --quiet nginx; then
    print_success "✓ Nginx fonctionne"
else
    print_error "✗ Nginx ne fonctionne pas"
fi

# Test du site
if curl -f https://$DOMAIN/ > /dev/null 2>&1; then
    print_success "✓ Site Frontend accessible"
else
    print_warning "⚠ Site Frontend non accessible (vérifiez la configuration)"
fi

# Test de la connexion au backend
if curl -f https://$DOMAIN/api/ > /dev/null 2>&1; then
    print_success "✓ Connexion au backend fonctionne"
else
    print_warning "⚠ Connexion au backend non accessible"
fi

# 22. Affichage des informations finales
print_success "=== Déploiement Frontend terminé avec succès! ==="
echo ""
echo "📊 Informations de déploiement:"
echo "   • Domaine: https://$DOMAIN"
echo "   • Build: $APP_DIR/dist"
echo "   • Logs: $APP_DIR/logs/"
echo "   • Scripts: $APP_DIR/deploy.sh, $APP_DIR/backup.sh"
echo ""
echo "🔧 Commandes utiles:"
echo "   • Déployer: sudo $APP_DIR/deploy.sh"
echo "   • Sauvegarder: sudo $APP_DIR/backup.sh"
echo "   • Voir les logs: sudo tail -f $APP_DIR/logs/nginx.log"
echo "   • Status: sudo systemctl status nginx"
echo ""
echo "⚙️ Configuration:"
echo "   • API Backend: https://$BACKEND_DOMAIN"
echo "   • Variables d'environnement: $APP_DIR/.env.production"
echo ""
echo "⚠️  Important:"
echo "   • Vérifiez la configuration CORS dans le backend"
echo "   • Testez toutes les fonctionnalités du frontend"
echo "   • Configurez le monitoring si nécessaire"
echo ""
print_success "Le frontend est maintenant en ligne! 🚀"

# 23. Génération d'un rapport de déploiement
cat > $APP_DIR/deployment-report.txt << EOF
=== Rapport de Déploiement Homify Frontend ===
Date: $(date)
Domaine: $DOMAIN
Build Directory: $APP_DIR/dist
Nginx Config: $NGINX_CONFIG

Versions:
- Node.js: $(node --version)
- npm: $(npm --version)
- React Build: $(ls -la $APP_DIR/dist | wc -l) fichiers

Tests:
- Nginx: $(systemctl is-active nginx)
- Site Web: $(curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN/)
- API Backend: $(curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN/api/)

Certificats SSL:
$(certbot certificates 2>/dev/null | grep -A 10 "$DOMAIN" || echo "Aucun certificat trouvé")

Logs:
- Access: /var/log/nginx/homify-front-access.log
- Error: /var/log/nginx/homify-front-error.log

Sauvegardes:
- Répertoire: $BACKUP_DIR
- Automatique: 03:00 tous les jours
EOF

print_status "Rapport de déploiement généré: $APP_DIR/deployment-report.txt"
