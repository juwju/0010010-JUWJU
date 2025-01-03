#!/bin/bash

install_docker() {
    echo -e "${BLUE}1. Vérification de l'installation de Docker...${NC}"

    # Vérifie si Docker est installé
    if ! command -v docker >/dev/null 2>&1; then
        echo -e "Docker n'est pas installé. Installation en cours..."
        
        # Met à jour les paquets et installe les dépendances nécessaires
        sudo apt update
        sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

        # Ajoute la clé GPG officielle de Docker
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

        # Ajoute le dépôt officiel de Docker
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

        # Installe Docker
        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io

        # Active et démarre le service Docker
        sudo systemctl enable docker
        sudo systemctl start docker

        echo -e "Docker a été installé avec succès : ${GREEN}OK${NC}"
    else
        echo -e "Docker est déjà installé : ${GREEN}OK${NC}"
    fi

    # Vérifie la version installée de Docker
    docker --version
}

install_docker_compose() {
    echo -e "${BLUE}2. Vérification de l'installation de Docker Compose...${NC}"

    # Vérifie si Docker Compose est installé
    if ! command -v docker-compose >/dev/null 2>&1; then
        echo -e "Docker Compose n'est pas installé. Installation en cours..."

        # Télécharge et installe la dernière version de Docker Compose
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
            -o /usr/local/bin/docker-compose

        # Rend le binaire exécutable
        sudo chmod +x /usr/local/bin/docker-compose

        echo -e "Docker Compose a été installé avec succès : ${GREEN}OK${NC}"
    else
        echo -e "Docker Compose est déjà installé : ${GREEN}OK${NC}"
    fi

    # Vérifie la version installée de Docker Compose
    docker-compose --version
}

configure_docker_swarm() {
    echo -e "${BLUE}3. Configuration de Docker Swarm...${NC}"

    # Vérifie si le mode Swarm est activé
    if ! docker info | grep -q "Swarm: active"; then
        echo -e "Docker Swarm n'est pas activé. Initialisation en cours..."
        
        # Initialise le mode Swarm sur le nœud actuel (manager)
        sudo docker swarm init

        if [ $? -eq 0 ]; then
            echo -e "Docker Swarm a été initialisé avec succès : ${GREEN}OK${NC}"
        else
            echo -e "Échec de l'initialisation de Docker Swarm : ${RED}NO${NC}"
            exit 1
        fi
    else
        echo -e "Docker Swarm est déjà activé : ${GREEN}OK${NC}"
    fi
}

apply_docker_best_practices() {
    echo -e "${BLUE}4. Application des meilleures configurations pour Docker...${NC}"

    # Crée ou modifie le fichier daemon.json pour configurer Docker
    DOCKER_CONFIG_FILE="/etc/docker/daemon.json"
    
    cat <<EOF | sudo tee $DOCKER_CONFIG_FILE > /dev/null
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "data-root": "/var/lib/docker",
  "storage-driver": "overlay2"
}
EOF

    # Redémarre le service Docker pour appliquer les changements
    sudo systemctl daemon-reload
    sudo systemctl restart docker

    echo -e "Configurations appliquées avec succès : ${GREEN}OK${NC}"
}

add_user_to_docker_group() {
    echo -e "${BLUE}5. Ajout de l'utilisateur courant au groupe docker...${NC}"

    # Ajoute l'utilisateur courant au groupe docker pour éviter d'utiliser 'sudo'
    sudo usermod -aG docker $USER

    echo -e "${YELLOW}Veuillez vous déconnecter et vous reconnecter pour que les modifications prennent effet.${NC}"
}

# Variables pour les couleurs (facultatif)
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # Pas de couleur


# Main function
SetupContainerApp() {
# Appel des fonctions dans l'ordre approprié
install_docker
install_docker_compose
configure_docker_swarm
apply_docker_best_practices
add_user_to_docker_group

echo -e "${GREEN}Installation et configuration terminées avec succès !${NC}"

}

