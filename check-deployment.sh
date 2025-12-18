#!/bin/bash

# Script de vérification post-déploiement pour Homify
# Utilisez ce script pour vérifier que tout fonctionne correctement

DOMAIN="tmc.supahuman.site"
PROJECT_DIR="/var/www/homify"

echo "🔍 Vérification du déploiement Homify sur $DOMAIN"
echo "=================================================="

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_service() {
    local service=$1
    local description=$2
    
    echo -n "Vérification $description... "
    if systemctl is-active --quiet $service; then
        echo -e "${GREEN}✅ OK${NC}"
        return 0
    else
        echo -e "${RED}❌ ÉCHEC${NC}"
        return 1
    fi
}

check_port() {
    local port=$1
    local description=$2
    
    echo -n "Vérification port $port ($description)... "
    if netstat -tlnp | grep ":$port " > /dev/null; then
        echo -e "${GREEN}✅ OUVERT${NC}"
        return 0
    else
        echo -e "${RED}❌ FERMÉ${NC}"
        return 1
    fi
}

check_file() {
    local file=$1
    local description=$2
    
    echo -n "Vérification $description... "
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅ PRÉSENT${NC}"
        return 0
    else
        echo -e "${RED}❌ MANQUANT${NC}"
        return 1
    fi
}

check_web_access() {
    local url=$1
    local description=$2
    
    echo -n "Test accès $description... "
    if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -E "200|301|302" > /dev/null; then
        echo -e "${GREEN}✅ OK${NC}"
        return 0
    else
        echo -e "${RED}❌ ÉCHEC${NC}"
        return 1
    fi
}

echo "1. SERVICES SYSTÈME"
echo "==================="
check_service "nginx" "NGINX"
check_service "postgresql" "PostgreSQL"
check_service "redis-server" "Redis"

echo ""
echo "2. PORTS RÉSEAU"
echo "==============="
check_port 80 "HTTP"
check_port 443 "HTTPS"
check_port 8000 "Backend Django"
check_port 5432 "PostgreSQL"
check_port 6379 "Redis"

echo ""
echo "3. FICHIERS CRITIQUES"
echo "====================="
check_file "/etc/nginx/sites-enabled/homify" "Configuration NGINX"
check_file "$PROJECT_DIR/backend/.env" "Variables d'environnement"
check_file "$PROJECT_DIR/backend/manage.py" "Django manage.py"
check_file "$PROJECT_DIR/frontend/package.json" "Frontend package.json"

echo ""
echo "4. PERMISSIONS"
echo "=============="
echo -n "Répertoire projet... "
if [ -r "$PROJECT_DIR" ] && [ -w "$PROJECT_DIR" ]; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${YELLOW}⚠️ PERMISSIONS LIMITÉES${NC}"
fi

echo -n "Fichiers NGINX... "
if [ -r "/etc/nginx/sites-enabled/homify" ]; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${RED}❌ ERREUR${NC}"
fi

echo ""
echo "5. TESTS WEB"
echo "============"
check_web_access "http://$DOMAIN" "Site principal"
check_web_access "http://$DOMAIN/api/" "API Backend"
check_web_access "http://$DOMAIN/admin/" "Admin Django"

echo ""
echo "6. LOGS RÉCENTS"
echo "==============="
echo "Logs NGINX (10 dernières lignes):"
if [ -f "/var/log/nginx/homify_access.log" ]; then
    tail -n 3 /var/log/nginx/homify_access.log 2>/dev/null || echo "Pas d'accès récents"
else
    echo -e "${YELLOW}Fichier de log non trouvé${NC}"
fi

echo ""
echo "Logs Backend Django (10 dernières lignes):"
if [ -f "$PROJECT_DIR/logs/django.log" ]; then
    tail -n 3 "$PROJECT_DIR/logs/django.log" 2>/dev/null || echo "Pas de logs récents"
else
    echo -e "${YELLOW}Fichier de log non trouvé${NC}"
fi

echo ""
echo "7. INFORMATIONS SYSTÈME"
echo "========================"
echo "Espace disque:"
df -h / | tail -1

echo "Mémoire:"
free -h | grep "Mem:"

echo "Charge système:"
uptime

echo ""
echo "8. COMMANDES UTILES"
echo "==================="
echo "# Redémarrer les services:"
echo "systemctl restart homify-backend nginx"
echo ""
echo "# Voir les logs en temps réel:"
echo "journalctl -u homify-backend -f"
echo "tail -f /var/log/nginx/homify_access.log"
echo ""
echo "# Vérifier la configuration:"
echo "nginx -t"
echo "cd $PROJECT_DIR/backend && python3 manage.py check --deploy"
echo ""
echo "# Tester la base de données:"
echo "cd $PROJECT_DIR/backend && python3 manage.py dbshell"
echo ""

echo "=================================================="
echo "✅ Vérification terminée!"
echo "Si vous voyez des erreurs ❌, consultez le guide de dépannage."
echo "Votre site Homify devrait être accessible sur http://$DOMAIN"
