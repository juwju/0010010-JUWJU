#!/bin/bash

CreateSRVEnv() {
    # Définir le chemin du fichier d'environnement
    ENV_FILE="/var/app/000000-srv-Server.env"

    # Créer ou écraser le fichier d'environnement
    if ! touch "$ENV_FILE"; then
        echo "Erreur : Impossible de créer ou modifier le fichier $ENV_FILE."
        return 1
    fi

    # Écrire les variables d'environnement dans le fichier
    cat <<EOF > "$ENV_FILE"
################################################################################
# FICHIER : $ENV_FILE
################################################################################

# MASTER SERVER ################################################################
MASTER_DOMAIN=juwju.com
MASTER_IP=203.161.46.164
PROXY_DASHBOARD=https://masterproxy.juwju.com
MASTER_EMAIL=webmaster@juwju.com

# WireGuard Configuration
MASTER_PORT_WIREGUARD=51820

# Liste des serveurs enfants
SERVER_CHILD=server1,server2,server3

# ACTUAL SERVER ################################################################
ACTUAL_SERVER_ID=3

# Applications requises pour le serveur (séparées par des virgules)
APP_REQUIRED=docker.io,deno,nodejs,npm,python3,pip,git,docker-compose,wireguard-tools,prometheus,grafana,ansible,curl,lynis,chkrootkit,clamav,vuls,openvas,zaproxy,wapiti,fail2ban

################################################################################
EOF

    # Vérifier si l'écriture dans le fichier a réussi
    if [ $? -eq 0 ]; then
        echo "Le fichier d'environnement a été créé avec succès : $ENV_FILE"
    else
        echo "Erreur : Échec de l'écriture dans le fichier $ENV_FILE."
        return 1
    fi

    return 0
}


CreateAppEnv() {
    # Définir le chemin du fichier d'environnement
    ENV_FILE="/var/app/0010000-JUWJU/000000-App.env"

    # Créer ou écraser le fichier d'environnement
    if ! touch "$ENV_FILE"; then
        echo "Erreur : Impossible de créer ou modifier le fichier $ENV_FILE."
        return 1
    fi

    # Écrire les variables d'environnement dans le fichier
    cat <<EOF > "$ENV_FILE"
# FICHIER : 000000-App.env

# APP ########################################################################
APP_NAME=juwju
APP_ID=1
HTTPS=true

APP_DOMAIN_EXT=com
APP_HTTPS=$APP_NAME.$APP_DOMAIN_EXT
ADMIN_EMAIL=admin@$APP_NAME.$APP_DOMAIN_EXT
INFO_EMAIL=info@$APP_NAME.$APP_DOMAIN_EXT
WEBMASTER_EMAIL=webmaster@$APP_NAME.$APP_DOMAIN_EXT
WEBMASTER_NAME=webmaster
WEBMASTER_PASSWORD=QWopzxnm1290

################################################################################
# Notes
################################################################################
# 
# 
# 
EOF

    # Vérifier si l'écriture dans le fichier a réussi
    if [ $? -eq 0 ]; then
        echo "Le fichier d'environnement a été créé avec succès : $ENV_FILE"
    else
        echo "Erreur : Échec de l'écriture dans le fichier $ENV_FILE."
        return 1
    fi

    return 0
}
    
StartJuwju() {
    cd /var/app/juwju/0010000-JUWJU/
    deno task uplog 10010
}
