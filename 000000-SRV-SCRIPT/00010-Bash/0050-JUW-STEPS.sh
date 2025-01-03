
# Fonction pour afficher les outils avec leur statut de sélection
display_tools() {
    clear
    echo -e "${BLUE}============================================================"
    echo -e "${GREEN} TOOLS SELECTION"
    echo -e "${BLUE}============================================================"

    # Affiche la liste des outils avec leur statut
    for i in "${!tools[@]}"; do
        if [[ $i -eq $current_index ]]; then
            prefix="> " # Indique l'élément actuellement sélectionné
        else
            prefix="  "
        fi

        if [[ "${selected_tools[i]}" == "y" ]]; then
            status="${GREEN}[x]${NC}" # Outil sélectionné
        else
            status="${RED}[ ]${NC}" # Outil non sélectionné
        fi

        echo -e "$prefix${BLUE}${tools[i]} $status"
    done

    echo ""
    echo -e "${NC}Utilisez les flèches haut/bas pour naviguer, et 'y' ou 'n' pour sélectionner/désélectionner."
    echo -e "${NC}Appuyez sur 'Enter' pour valider votre sélection."
}

# Fonction principale pour sélectionner les outils
SelectTools() {
    echo ""

    # Liste des outils disponibles pour l'installation
    tools=(
        "Juwju base (crypted connection, proxy, Dev tools)"
        "Office admin suite"
        "Accounting & Finance"
        "CRM"
        "Web site manager"
        "Juwju presence"
        "Networks intelligence"
        "Crypted Core business intelligence"
    )

    # Tableau pour stocker les sélections utilisateur (par défaut : non sélectionné)
    selected_tools=()

    for tool in "${tools[@]}"; do
        selected_tools+=("n") # Initialise chaque outil comme non sélectionné (n)
    done

    # Navigation interactive avec les flèches et sélection utilisateur
    current_index=0

    while true; do
        display_tools
        
        # Détecter les entrées utilisateur (flèches ou autres touches)
        read -rsn1 input

        case "$input" in
            $'\x1B') # Détection des touches fléchées (séquence d'échappement)
                read -rsn2 key_input
                case "$key_input" in
                    "[A") # Flèche haut
                        ((current_index--))
                        if ((current_index < 0)); then current_index=$((${#tools[@]} - 1)); fi ;;
                    "[B") # Flèche bas
                        ((current_index++))
                        if ((current_index >= ${#tools[@]})); then current_index=0; fi ;;
                esac ;;
            y) # Sélectionner l'outil actuel (y = oui)
                selected_tools[current_index]="y" ;;
            n) # Désélectionner l'outil actuel (n = non)
                selected_tools[current_index]="n" ;;
            "") # Entrée valide la sélection et quitte la boucle interactive
                break ;;
            *) ;; # Ignorer toute autre entrée non reconnue
        esac
    done

    clear

    # Affiche le résumé des outils sélectionnés après validation par l'utilisateur.
    echo -e "${BLUE}============================================================"
    echo -e "${GREEN} SELECTION SUMMARY"
    echo -e "${BLUE}============================================================"

    for i in "${!tools[@]}"; do
        if [[ "${selected_tools[i]}" == "y" ]]; then
            echo -e "${GREEN}${tools[i]} : SELECTED${NC}"
        else
            echo -e "${GRAY}${tools[i]} : NOT SELECTED${NC}"
        fi
    done

}


