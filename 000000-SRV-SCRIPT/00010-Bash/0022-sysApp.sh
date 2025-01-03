
# Fonction pour installer et configurer Deno pour tous les utilisateurs du groupe juwju
configure_deno() {
    echo -e "${BLUE}3. Vérification de l'installation de Deno...${NC}"

    # Vérifie si Deno est déjà installé
    if command -v deno >/dev/null 2>&1; then
        echo -e "Deno est déjà installé. Vérification de la version..."
        
        # Récupère la version actuelle de Deno
        CURRENT_VERSION=$(deno --version | grep deno | awk '{print $2}')
        echo -e "Version actuelle de Deno : ${GREEN}${CURRENT_VERSION}${NC}"

        # Met à jour Deno si nécessaire
        echo -e "Mise à jour de Deno vers la dernière version..."
        deno upgrade
        if [ $? -eq 0 ]; then
            echo -e "Deno est maintenant à jour : ${GREEN}OK${NC}"
        else
            echo -e "Échec de la mise à jour de Deno : ${RED}NO${NC}"
            exit 1
        fi
    else
        # Installe Deno s'il n'est pas trouvé
        echo -e "Deno n'est pas installé. Installation en cours..."
        curl -fsSL https://deno.land/install.sh | sh
        if [ $? -eq 0 ]; then
            echo -e "Installation de Deno : ${GREEN}OK${NC}"
        else
            echo -e "Installation de Deno : ${RED}NO${NC}"
            exit 1
        fi
    fi

    # Vérifie la version finale installée ou mise à jour
    FINAL_VERSION=$(deno --version | grep deno | awk '{print $2}')
    echo -e "Version finale de Deno installée : ${GREEN}${FINAL_VERSION}${NC}"
}


# Fonction pour installer et configurer Zsh pour tous les utilisateurs du groupe juwju
configure_zsh() {
    echo -e "${BLUE}4. Vérification et configuration de Zsh...${NC}"

    # Vérifie si Zsh est déjà installé
    if command -v zsh >/dev/null 2>&1; then
        echo -e "Zsh est déjà installé : ${GREEN}OK${NC}"
        
        # Affiche la version actuelle de Zsh
        CURRENT_VERSION=$(zsh --version | awk '{print $2}')
        echo -e "Version actuelle de Zsh : ${GREEN}${CURRENT_VERSION}${NC}"
    else
        # Installe Zsh s'il n'est pas trouvé
        echo -e "Zsh n'est pas installé. Installation en cours..."
        sudo apt update && sudo apt install -y zsh
        if [ $? -eq 0 ]; then
            echo -e "Installation de Zsh : ${GREEN}OK${NC}"
            
            # Affiche la version installée après installation
            INSTALLED_VERSION=$(zsh --version | awk '{print $2}')
            echo -e "Version de Zsh installée : ${GREEN}${INSTALLED_VERSION}${NC}"
        else
            echo -e "Échec de l'installation de Zsh : ${RED}NO${NC}"
            exit 1
        fi
    fi

    # Configuration supplémentaire (optionnel)
    echo -e "${BLUE}Configuration supplémentaire pour Zsh...${NC}"
    # Exemple : définir Zsh comme shell par défaut pour l'utilisateur courant
    if [ "$SHELL" != "$(command -v zsh)" ]; then
        echo -e "Définition de Zsh comme shell par défaut..."
        chsh -s "$(command -v zsh)"
        if [ $? -eq 0 ]; then
            echo -e "Zsh est maintenant le shell par défaut : ${GREEN}OK${NC}"
        else
            echo -e "Échec de la configuration de Zsh comme shell par défaut : ${RED}NO${NC}"
        fi
    else
        echo -e "Zsh est déjà configuré comme shell par défaut : ${GREEN}OK${NC}"
    fi
}