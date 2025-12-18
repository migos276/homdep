#!/bin/bash

# Script de déploiement automatisé pour Homify
# Domaine: tmc.supahuman.site
# Auteur: Assistant IA

set -e  # Arrêter en cas d'erreur

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables de configuration
DOMAIN="tmc.supahuman.site"
PROJECT_DIR="/var/www/homify"
NGINX_CONFIG_DIR="/etc/nginx/sites-available"
NGINX_ENABLED_DIR="/etc/nginx/sites-enabled"
USER="www-data"
FRONTEND_PORT=3000
BACKEND_PORT=8000

# Fonctions utilitaires
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Vérifier si on est root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Ce script doit être exécuté en tant que root (utilisez sudo)"
        exit 1
    fi
}

# Mettre à jour le système
update_system() {
    log_info "Mise à jour du système..."
    apt update && apt upgrade -y
    log_success "Système mis à jour"
}

# Installer les dépendances
install_dependencies() {
    log_info "Installation des dépendances..."
    
    # Installer curl, wget, git, etc.
    apt install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release
    
    # Installer Docker
    if ! command -v docker &> /dev/null; then
        log_info "Installation de Docker..."
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt update
        apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        systemctl start docker
        systemctl enable docker
        log_success "Docker installé"
    else
        log_success "Docker déjà installé"
    fi
    
    # Installer Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log_info "Installation de Docker Compose..."
        curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        log_success "Docker Compose installé"
    else
        log_success "Docker Compose déjà installé"
    fi
    
    # Installer Node.js et npm
    if ! command -v node &> /dev/null; then
        log_info "Installation de Node.js..."
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
        apt install -y nodejs
        log_success "Node.js installé"
    else
        log_success "Node.js déjà installé"
    fi
    
    # Installer NGINX
    if ! command -v nginx &> /dev/null; then
        log_info "Installation de NGINX..."
        apt install -y nginx
        systemctl start nginx
        systemctl enable nginx
        log_success "NGINX installé"
    else
        log_success "NGINX déjà installé"
    fi
    

    # Installer PostgreSQL
    if ! command -v psql &> /dev/null; then
        log_info "Installation de PostgreSQL..."
        apt install -y postgresql postgresql-contrib
        systemctl start postgresql
        systemctl enable postgresql
        log_success "PostgreSQL installé"
    else
        log_success "PostgreSQL déjà installé"
    fi
    
    # Installer Redis
    if ! command -v redis-server &> /dev/null; then
        log_info "Installation de Redis..."
        apt install -y redis-server
        systemctl start redis-server
        systemctl enable redis-server
        log_success "Redis installé"
    else
        log_success "Redis déjà installé"
    fi
}

# Créer les répertoires du projet
create_directories() {
    log_info "Création des répertoires..."
    
    mkdir -p $PROJECT_DIR/{frontend,backend,logs,ssl,backups}
    mkdir -p $PROJECT_DIR/backend/media/properties
    mkdir -p $PROJECT_DIR/backend/staticfiles
    
    # Définir les permissions
    chown -R $USER:$USER $PROJECT_DIR
    chmod -R 755 $PROJECT_DIR
    
    log_success "Répertoires créés"
}

# Configurer la base de données
setup_database() {
    log_info "Configuration de la base de données..."
    
    # Créer l'utilisateur et la base de données
    sudo -u postgres psql << EOF
CREATE USER homify_user WITH PASSWORD 'homify_secure_password_123';
CREATE DATABASE homify_db OWNER homify_user;
GRANT ALL PRIVILEGES ON DATABASE homify_db TO homify_user;
ALTER USER homify_user CREATEDB;
\q
EOF
    
    log_success "Base de données configurée"
}

# Cloner le projet
clone_project() {
    log_info "Récupération du projet..."
    
    cd $PROJECT_DIR
    
    # Si vous avez un repository Git, décommentez et modifiez l'URL
    # git clone https://github.com/username/homify.git .
    
    # Pour l'instant, nous créons une structure basique
    log_warning "Vous devez manuellement copier vos fichiers dans $PROJECT_DIR"
    log_warning "Assurez-vous que la structure frontend/backend est présente"
}

# Configurer l'environnement backend
setup_backend_env() {
    log_info "Configuration de l'environnement backend..."
    
    cat > $PROJECT_DIR/backend/.env << EOF
# Configuration Django Production
DEBUG=False
SECRET_KEY=your-super-secret-key-change-this-in-production
ALLOWED_HOSTS=$DOMAIN,www.$DOMAIN,localhost,127.0.0.1
DATABASE_URL=postgresql://homify_user:homify_secure_password_123@localhost:5432/homify_db
REDIS_URL=redis://localhost:6379/0

# Email Configuration
EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=your-email@gmail.com
EMAIL_HOST_PASSWORD=your-app-password

# Static and Media Files
STATIC_URL=/static/
MEDIA_URL=/media/

# Security
SECURE_SSL_REDIRECT=True
SESSION_COOKIE_SECURE=True
CSRF_COOKIE_SECURE=True
SECURE_HSTS_SECONDS=31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS=True
EOF
    
    chmod 600 $PROJECT_DIR/backend/.env
    chown $USER:$USER $PROJECT_DIR/backend/.env
    
    log_success "Environnement backend configuré"
}

# Construire le frontend
build_frontend() {
    log_info "Construction du frontend..."
    
    cd $PROJECT_DIR/frontend
    
    # Installer les dépendances
    npm install
    
    # Construire pour la production
    npm run build
    
    # Définir les permissions
    chown -R $USER:$USER $PROJECT_DIR/frontend/dist
    
    log_success "Frontend construit"
}

# Configurer et démarrer le backend
setup_backend() {
    log_info "Configuration du backend..."
    
    cd $PROJECT_DIR/backend
    
    # Installer les dépendances Python
    pip3 install -r requirements.txt
    
    # Effectuer les migrations
    python3 manage.py migrate
    
    # Collecter les fichiers statiques
    python3 manage.py collectstatic --noinput
    
    # Créer un superutilisateur (optionnel)
    # python3 manage.py createsuperuser
    
    log_success "Backend configuré"
}

# Configurer NGINX
setup_nginx() {
    log_info "Configuration de NGINX..."
    
    # Copier la configuration NGINX
    if [ -f "nginx.conf" ]; then
        cp nginx.conf $NGINX_CONFIG_DIR/homify
    else
        log_error "Fichier nginx.conf non trouvé. Copiez-le d'abord."
        exit 1
    fi
    
    # Activer le site
    ln -sf $NGINX_CONFIG_DIR/homify $NGINX_ENABLED_DIR/
    
    # Supprimer la configuration par défaut
    rm -f $NGINX_ENABLED_DIR/default
    
    # Tester la configuration
    nginx -t
    
    if [ $? -eq 0 ]; then
        systemctl reload nginx
        log_success "NGINX configuré et rechargé"
    else
        log_error "Erreur dans la configuration NGINX"
        exit 1
    fi
}

# Configurer le firewall
setup_firewall() {
    log_info "Configuration du firewall..."
    
    # Installer et configurer UFW
    if ! command -v ufw &> /dev/null; then
        apt install -y ufw
    fi
    
    # Configuration du firewall
    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw allow 80/tcp
    ufw allow 443/tcp

    ufw allow from 127.0.0.1 to any port 8000  # Backend local
    ufw --force enable
    
    log_success "Firewall configuré"
}

# Créer les services systemd
create_systemd_services() {
    log_info "Création des services systemd..."
    
    # Service pour le backend Django
    cat > /etc/systemd/system/homify-backend.service << EOF
[Unit]
Description=Homify Backend Django
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=$PROJECT_DIR/backend
Environment=DJANGO_SETTINGS_MODULE=rental_project.settings
ExecStart=/usr/bin/python3 manage.py runserver 0.0.0.0:8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    # Service pour le frontend (si nécessaire)
    cat > /etc/systemd/system/homify-frontend.service << EOF
[Unit]
Description=Homify Frontend
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=$PROJECT_DIR/frontend
ExecStart=/usr/bin/npm run preview -- --host 0.0.0.0 --port 3000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    # Recharger systemd et démarrer les services
    systemctl daemon-reload
    systemctl enable homify-backend.service
    systemctl start homify-backend.service
    # systemctl enable homify-frontend.service
    # systemctl start homify-frontend.service
    
    log_success "Services systemd créés et démarrés"
}

# Configurer les logs
setup_logging() {
    log_info "Configuration des logs..."
    
    # Configuration logrotate pour les logs NGINX
    cat > /etc/logrotate.d/homify << EOF
$PROJECT_DIR/logs/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 www-data www-data
    postrotate
        systemctl reload nginx
    endscript
}
EOF
    
    log_success "Logs configurés"
}

# Configuration SSL avec Let's Encrypt (optionnel)
setup_ssl() {
    log_info "Configuration SSL..."
    
    read -p "Voulez-vous configurer SSL avec Let's Encrypt? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Installer Certbot
        apt install -y certbot python3-certbot-nginx
        
        # Obtenir le certificat
        certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN
        
        # Configuration du renouvellement automatique
        (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
        
        log_success "SSL configuré avec Let's Encrypt"
    else
        log_warning "SSL non configuré. Vous pouvez l'ajouter plus tard avec certbot."
    fi
}

# Script principal
main() {
    log_info "Début du déploiement de Homify sur $DOMAIN"
    
    check_root
    update_system
    install_dependencies
    create_directories
    setup_database
    clone_project
    setup_backend_env
    build_frontend
    setup_backend
    setup_nginx
    setup_firewall
    create_systemd_services
    setup_logging
    
    read -p "Voulez-vous configurer SSL maintenant? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        setup_ssl
    fi
    
    log_success "Déploiement terminé!"
    log_info "Votre site Homify est maintenant disponible sur http://$DOMAIN"
    log_info "Backend API: http://$DOMAIN/api/"
    log_info "Admin Django: http://$DOMAIN/admin/"
    
    # Afficher les commandes utiles
    echo
    echo "=== Commandes utiles ==="
    echo "Voir les logs du backend: journalctl -u homify-backend -f"
    echo "Redémarrer le backend: systemctl restart homify-backend"
    echo "Voir les logs NGINX: tail -f /var/log/nginx/homify_access.log"
    echo "Redémarrer NGINX: systemctl restart nginx"
    echo "========================"
}

# Exécuter le script principal
main "$@"
