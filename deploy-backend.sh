#!/bin/bash

# Script de déploiement du Backend Django Homify
# Domaine: homify-back.supahuman.site
# Usage: sudo ./deploy-backend.sh

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

print_status "=== Début du déploiement du Backend Homify ==="

# Variables
DOMAIN="homify-back.supahuman.site"
APP_DIR="/var/www/homify-back"
NGINX_CONFIG="/etc/nginx/sites-available/homify-back"
NGINX_ENABLED="/etc/nginx/sites-enabled/homify-back"
BACKUP_DIR="/var/backups/homify-back"
PROJECT_NAME="homify-backend"

# 1. Mise à jour du système
print_status "Mise à jour du système..."
apt update && apt upgrade -y

# 2. Installation des dépendances de base
print_status "Installation des dépendances de base..."
apt install -y curl wget git unzip nginx certbot python3-certbot-nginx

# 3. Installation de Docker et Docker Compose
print_status "Installation de Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    usermod -aG docker $SUDO_USER
    systemctl enable docker
    systemctl start docker
    rm get-docker.sh
else
    print_success "Docker déjà installé"
fi

# Installation de Docker Compose
print_status "Installation de Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_VERSION="2.23.0"
    curl -L "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
else
    print_success "Docker Compose déjà installé"
fi

# 4. Installation de Python et pip
print_status "Installation de Python et pip..."
apt install -y python3 python3-pip python3-venv

# 5. Création de l'utilisateur système
print_status "Création de l'utilisateur système..."
if ! id "$PROJECT_NAME" &>/dev/null; then
    useradd -r -s /bin/bash -d $APP_DIR -m $PROJECT_NAME
    usermod -aG docker $PROJECT_NAME
    print_success "Utilisateur $PROJECT_NAME créé"
else
    print_warning "Utilisateur $PROJECT_NAME existe déjà"
fi

# 6. Création des répertoires
print_status "Création des répertoires..."
mkdir -p $APP_DIR
mkdir -p $APP_DIR/logs
mkdir -p $BACKUP_DIR
chown -R $PROJECT_NAME:$PROJECT_NAME $APP_DIR
chown -R $PROJECT_NAME:$PROJECT_NAME $BACKUP_DIR

# 7. Configuration PostgreSQL (si pas Docker)
print_status "Configuration PostgreSQL..."
if ! command -v docker &> /dev/null; then
    apt install -y postgresql postgresql-contrib
    systemctl enable postgresql
    systemctl start postgresql
    
    # Créer la base de données et l'utilisateur
    sudo -u postgres psql << EOF
CREATE DATABASE homify_db;
CREATE USER homify_user WITH PASSWORD '$(openssl rand -base64 32)';
GRANT ALL PRIVILEGES ON DATABASE homify_db TO homify_user;
ALTER USER homify_user CREATEDB;
\q
EOF
    print_success "Base de données PostgreSQL configurée"
fi

# 8. Configuration Redis (si pas Docker)
print_status "Configuration Redis..."
if ! command -v docker &> /dev/null; then
    apt install -y redis-server
    systemctl enable redis-server
    systemctl start redis-server
fi

# 9. Configuration du firewall
print_status "Configuration du firewall..."
if command -v ufw &> /dev/null; then
    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw --force enable
    print_success "Firewall configuré"
fi

# 10. Copie des fichiers du projet
print_status "Copie des fichiers du projet..."
if [ -d "/home/$SUDO_USER/Bureau/INFO L3/TP/Homify-final/backend_homify" ]; then
    cp -r /home/$SUDO_USER/Bureau/INFO L3/TP/Homify-final/backend_homify/* $APP_DIR/
    chown -R $PROJECT_NAME:$PROJECT_NAME $APP_DIR
    print_success "Fichiers du backend copiés"
else
    print_error "Répertoire du backend non trouvé"
    exit 1
fi

# 11. Configuration des variables d'environnement
print_status "Configuration des variables d'environnement..."
cat > $APP_DIR/.env << EOF
# Production Configuration
DEBUG=False
SECRET_KEY=$(openssl rand -base64 50)
ALLOWED_HOSTS=$DOMAIN,localhost,127.0.0.1

# Database
DB_NAME=homify_db
DB_USER=homify_user
DB_PASSWORD=$(openssl rand -base64 32)
DB_HOST=db
DB_PORT=5432

# Redis
REDIS_URL=redis://redis:6379/0

# Email Configuration
EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
EMAIL_HOST=localhost
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=
EMAIL_HOST_PASSWORD=

# Static Files
STATIC_URL=/static/
STATIC_ROOT=/app/staticfiles

# Media Files
MEDIA_URL=/media/
MEDIA_ROOT=/app/media

# CORS Configuration
CORS_ALLOWED_ORIGINS=https://homify-front.supahuman.site
CSRF_TRUSTED_ORIGINS=https://homify-front.supahuman.site
EOF

chown $PROJECT_NAME:$PROJECT_NAME $APP_DIR/.env
chmod 600 $APP_DIR/.env

# 12. Configuration docker-compose pour la production
print_status "Configuration Docker Compose production..."
cat > $APP_DIR/docker-compose.prod.yml << EOF
version: '3.8'

services:
  db:
    image: postgres:15-alpine
    volumes:
      - postgres_data_prod:/var/lib/postgresql/data
    environment:
      - POSTGRES_DB=homify_db
      - POSTGRES_USER=homify_user
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    restart: unless-stopped
    networks:
      - homify_network

  redis:
    image: redis:7-alpine
    restart: unless-stopped
    networks:
      - homify_network

  web:
    build: .
    command: >
      sh -c "python manage.py migrate &&
             python manage.py collectstatic --noinput &&
             gunicorn --bind 0.0.0.0:8000 --workers 4 --threads 2 rental_project.wsgi:application"
    volumes:
      - .:/app
      - media_volume_prod:/app/media
    ports:
      - "8000:8000"
    environment:
      - DEBUG=False
      - SECRET_KEY=${SECRET_KEY}
      - DATABASE_URL=postgresql://homify_user:${DB_PASSWORD}@db:5432/homify_db
      - REDIS_URL=redis://redis:6379/0
      - ALLOWED_HOSTS=$DOMAIN,localhost,127.0.0.1
    depends_on:
      - db
      - redis
    restart: unless-stopped
    networks:
      - homify_network

volumes:
  postgres_data_prod:
  media_volume_prod:

networks:
  homify_network:
    driver: bridge
EOF

# 13. Modification du Dockerfile pour la production
print_status "Modification du Dockerfile..."
cat > $APP_DIR/Dockerfile.prod << EOF
FROM python:3.11-slim

# Variables d'environnement
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Installation des dépendances système
RUN apt-get update && apt-get install -y \\
    gcc \\
    g++ \\
    libpq-dev \\
    && rm -rf /var/lib/apt/lists/*

# Création de l'utilisateur
RUN useradd --create-home --shell /bin/bash app

# Répertoire de travail
WORKDIR /app

# Installation de pip et Gunicorn
RUN pip install --upgrade pip
RUN pip install gunicorn==21.2.0

# Copie des requirements
COPY requirements.txt .

# Installation des dépendances Python
RUN pip install --no-cache-dir -r requirements.txt

# Copie du code
COPY . .

# Collecte des fichiers statiques
RUN python manage.py collectstatic --noinput

# Changement de propriétaire
RUN chown -R app:app /app

# Passage à l'utilisateur app
USER app

# Port par défaut
EXPOSE 8000

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "4", "--threads", "2", "rental_project.wsgi:application"]
EOF

# 14. Installation des dépendances Python
print_status "Installation des dépendances Python..."
cd $APP_DIR
sudo -u $PROJECT_NAME python3 -m pip install -r requirements.txt

# 15. Configuration Nginx
print_status "Configuration Nginx..."
cp /home/$SUDO_USER/Bureau/INFO L3/TP/Homify-final/nginx-homify-back.conf $NGINX_CONFIG

# Activation du site
ln -sf $NGINX_CONFIG $NGINX_ENABLED
rm -f /etc/nginx/sites-enabled/default

# Test de la configuration Nginx
nginx -t

# 16. Démarrage des services
print_status "Démarrage des services..."

# Démarrage de Django
cd $APP_DIR
sudo -u $PROJECT_NAME docker-compose -f docker-compose.prod.yml up -d --build

# Attendre que Django soit prêt
print_status "Attente du démarrage de Django..."
for i in {1..30}; do
    if curl -f http://localhost:8000/api/ > /dev/null 2>&1; then
        print_success "Django est prêt"
        break
    fi
    if [ $i -eq 30 ]; then
        print_error "Django n'a pas démarré dans les temps"
        exit 1
    fi
    echo "Tentative $i/30..."
    sleep 5
done

# Redémarrage de Nginx
systemctl restart nginx
systemctl enable nginx

# 17. Configuration SSL avec Let's Encrypt
print_status "Configuration SSL..."
if [ ! -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email admin@supahuman.site
    # Renouvellement automatique
    (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
else
    print_success "Certificat SSL déjà existant"
fi

# 18. Création du superutilisateur
print_status "Création du superutilisateur..."
cd $APP_DIR
sudo -u $PROJECT_NAME docker-compose -f docker-compose.prod.yml exec web python manage.py createsuperuser --noinput || {
    print_warning "Le superutilisateur existe déjà ou l'interaction est nécessaire"
}

# 19. Configuration des logs
print_status "Configuration des logs..."
cat > /etc/logrotate.d/homify-back << EOF
$APP_DIR/logs/*.log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 $PROJECT_NAME $PROJECT_NAME
    postrotate
        docker-compose -f $APP_DIR/docker-compose.prod.yml restart web
    endscript
}
EOF

# 20. Script de sauvegarde
print_status "Création du script de sauvegarde..."
cat > $APP_DIR/backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/var/backups/homify-back"
DATE=$(date +%Y%m%d_%H%M%S)

# Sauvegarde de la base de données
docker-compose exec -T db pg_dump -U homify_user homify_db > "$BACKUP_DIR/db_backup_$DATE.sql"

# Sauvegarde des fichiers media
tar -czf "$BACKUP_DIR/media_backup_$DATE.tar.gz" /var/www/homify-back/media/

# Nettoyage des anciennes sauvegardes (plus de 30 jours)
find $BACKUP_DIR -name "*.sql" -mtime +30 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +30 -delete

echo "Sauvegarde créée: $DATE"
EOF

chmod +x $APP_DIR/backup.sh
chown $PROJECT_NAME:$PROJECT_NAME $APP_DIR/backup.sh

# 21. Tâche de sauvegarde automatique
(crontab -l 2>/dev/null; echo "0 2 * * * $APP_DIR/backup.sh >> $APP_DIR/logs/backup.log 2>&1") | crontab -

# 22. Tests finaux
print_status "Tests finaux..."

# Test Nginx
if systemctl is-active --quiet nginx; then
    print_success "✓ Nginx fonctionne"
else
    print_error "✗ Nginx ne fonctionne pas"
fi

# Test Docker
if systemctl is-active --quiet docker; then
    print_success "✓ Docker fonctionne"
else
    print_error "✗ Docker ne fonctionne pas"
fi

# Test Django
if curl -f https://$DOMAIN/api/ > /dev/null 2>&1; then
    print_success "✓ API Django accessible"
else
    print_warning "⚠ API Django non accessible (vérifiez la configuration)"
fi

# 23. Affichage des informations finales
print_success "=== Déploiement Backend terminé avec succès! ==="
echo ""
echo "📊 Informations de déploiement:"
echo "   • Domaine: https://$DOMAIN"
echo "   • API: https://$DOMAIN/api/"
echo "   • Documentation: https://$DOMAIN/api/docs/"
echo "   • Admin: https://$DOMAIN/admin/"
echo "   • Répertoire: $APP_DIR"
echo "   • Logs: $APP_DIR/logs/"
echo ""
echo "🔧 Commandes utiles:"
echo "   • Voir les logs: sudo docker-compose -f $APP_DIR/docker-compose.prod.yml logs -f"
echo "   • Redémarrer: sudo docker-compose -f $APP_DIR/docker-compose.prod.yml restart"
echo "   • Sauvegarder: sudo $APP_DIR/backup.sh"
echo "   • Status: sudo systemctl status nginx"
echo ""
echo "⚠️  Important:"
echo "   • Changez les mots de passe dans $APP_DIR/.env"
echo "   • Configurez un vrai serveur email dans les variables d'environnement"
echo "   • Vérifiez les certificats SSL: certbot certificates"
echo ""
print_success "Le backend est maintenant en ligne! 🚀"
