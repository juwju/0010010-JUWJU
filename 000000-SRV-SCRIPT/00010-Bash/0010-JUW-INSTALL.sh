#!/bin/bash

#source ./Container.sh

# Colors for messages
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
GRAY='\033[0;90m' # Gris
NC='\033[0m' # No color

declare -A noteHeader noteRows noteTitle boardHeader boardRows boardTitle MasterSteps wcol

###################################################################################
# 1. TERMINAL VIEWS FUNCTIONS
###################################################################################
    format_message() {
        local message=$1
        local status=$2
        local max_length=55 # Longueur maximale pour l'alignement
        printf "${BLUE}%-${max_length}s [${GREEN}${status}${BLUE}]${NC}\n" "$message"
    }
    show_juwju_logo() {
        clear
        echo -e "${GREEN}        88                                   88              "
        echo "        88                                   \"\"              "
        echo "        88                                                    "
        echo "        88  88       88  8b      db      d8  88  88       88 "
        echo "        88  88       88  \`8b    d88b    d8'  88  88       88 "
        echo "        88  88       88   \`8b  d8'\`8b  d8'   88  88       88 "
        echo "88,   ,d88  \"8a,   ,a88    \`8bd8'  \`8bd8'    88  \"8a,   ,a88 "
        echo " \"Y8888P\"    \`\"YbbdP'Y8      YP      YP      88   \`\"YbbdP'Y8 "
        echo "                                            ,88              "
        echo -e "                                          888P\"              ${BLUE}"
    }
# +
###################################################################################
# 2. NOTES FUNCTIONS
###################################################################################    
    NotesData() {
        local noteName="$1"
        local operation="$2"
        shift 2
        case "$operation" in
            addDot)
                local new_lines=("$@")
                for new_line in "${new_lines[@]}"; do
                    # Ajoute chaque ligne comme un bloc individuel dans une chaîne
                    noteRows["$noteName"]+="${new_line}\n"
                done
                ;;
            removeline)
                local index="$1"
                local rows=(${noteRows["$noteName"]//\n/ })
                unset rows[$((index - 1))]
                noteRows["$noteName"]="$(IFS=$'\n'; echo "${rows[*]}")"
                ;;
            *)
                echo "Invalid operation: $operation"
                ;;
        esac
    }
    showNotes() {
        local noteName="$1"
        local clearActive="$2"
        if [ -z "$clearActive" ]; then 
            clear
        fi
        echo -e "${BLUE}============================================================"
        echo -e "${GREEN} ${noteTitle["$noteName"]^^}"  # Titre de la note en majuscules
        echo -e "${BLUE}============================================================"
        echo ""

        # Affiche chaque ligne correctement formatée
        if [ -n "${noteRows["$noteName"]}" ]; then
            echo -e "${noteRows["$noteName"]}" | sed 's/^//'
        fi
    }
    loadNotes() {
        noteTitle["welcome"]="WELCOME TO THE JUWJU PROJECT"
        NotesData "welcome" addDot \
        "A controlled-access, open-source web suite:" \
        " - CRM, project management, accounting, and more." \
        " - Secure, modular, and scalable architecture." \
        " - Licensed under the Juwju proprietary model." \
        "" \
        "Empowering efficient internal collaboration!"

        noteTitle["policies"]="JUWJU STRATEGY AND POLICIES"
        NotesData "policies" addDot \
        "${GREEN}1.${BLUE} Juwju is an international non-profit organization." \
        "${GREEN}2.${BLUE} All revenue will be used to:" \
        "   - Pay employees." \
        "   - Fund open-source collaborators." \
        "   - Upgrade Juwju's capacities." \
        "${GREEN}3.${BLUE} Selected collaborators will receive invitations to access" \
        "   the DAO level and contribute to the Juwju development plan."


        noteTitle["warning"]="IMPORTANT WARNING"
        NotesData "warning" addDot \
        "${GREEN}1.${BLUE} Juwju is designed to be installed on a freshly" \
        "   and fully controlled by Juwju" \
        "" \
        "${GREEN}2.${YELLOW} Do NOT install ${BLUE}on shared workstations or" \
        "   multi-purpose test servers." \
        "" \
        "${GREEN}3.${BLUE} Install Juwju on a minimum of 2 local servers, active on" \
        "   distinct address sites for each or with Juwju online solution" \
        "   ${YELLOW}Do NOT move ${BLUE}your organisation's IT structure without persistent" \
        "   score under ${YELLOW}85%${BLUE}" \
        "" \
        "${GREEN}4.${BLUE} The current version may work on virtual installations, but " \
        "   it was built and tested on local servers only."

    }
# +
###################################################################################
# 3. BOARD FUNCTIONS
###################################################################################    
    showBoard() {
        local boardName="$1"
        # Utiliser ';' comme séparateur de lignes
        IFS=';' read -ra rows <<< "${boardRows["$boardName"]}"
        local headers=(${boardHeader["$boardName"]//,/ })

        # Définir les largeurs des colonnes
        wcol[1]=2   # Index
        wcol[2]=12  # Target
        wcol[3]=20  # Step
        wcol[4]=40  # Description
        wcol[5]=7  # States

        clear
        echo -e "${BLUE}============================================================"
        echo -e "${GREEN} ${boardTitle["$boardName"]^^}"  # Nom du tableau en majuscules
        echo -e "${BLUE}============================================================"

        # Afficher les en-têtes seulement si headers n'est pas vide
        if [ -n "${boardHeader["$boardName"]}" ]; then
            printf "${GREEN}%-${wcol[1]}s${BLUE} | " "#"
            for i in "${!headers[@]}"; do
                printf "${GREEN}%-${wcol[$((i + 2))]}s${BLUE} | " "${headers[$i]}"
            done
            echo -e "\n${BLUE}============================================================"
        fi

        # Afficher les lignes seulement si rows n'est pas vide
        if [ -n "${boardRows["$boardName"]}" ]; then
            local index=1
            for row in "${rows[@]}"; do
                IFS=',' read -r -a cols <<< "$row"  # Utiliser ',' comme séparateur

                printf "${GREEN}%-${wcol[1]}s${BLUE} | " "$index"
                for i in "${!cols[@]}"; do
                    if [ $i -eq 4 ]; then  # Gestion des états (States)
                        case "${cols[$i]}" in
                            0) cols[$i]="[..]";;
                            1) cols[$i]="[+.]";;
                            2) cols[$i]="[OK]";;
                            3) cols[$i]="[NO]";;
                        esac
                    fi
                    printf "%-${wcol[$((i + 2))]}s${BLUE} | " "${cols[$i]}"
                done

                echo ""
                ((index++))
            done
        fi
    }


    UpdateRow() {
        local boardName="$1"
        local rowIndex=$2
        local newState="$3"
        # Utiliser ';' comme séparateur de lignes
        IFS=';' read -ra rows <<< "${boardRows["$boardName"]}"
        IFS=',' read -r -a cols <<< "${rows[$((rowIndex - 1))]}"  # Utiliser ',' comme séparateur

        cols[4]="$newState"  # Met à jour la colonne 5 (index 4)
        # Reconstruire la ligne avec ','
        rows[$((rowIndex - 1))]="$(IFS=,; echo "${cols[*]}")"
        # Reconstruire boardRows avec ';' comme séparateur de lignes
        boardRows["$boardName"]="$(IFS=\;; echo "${rows[*]}")"
    }


    loadBoard() {
        boardTitle["MainInstall"]="JUWJU INSTALL PROCESS"
        boardHeader["MainInstall"]="Target,Step,Description,States"
        boardRows["MainInstall"]="System,Basic_setup,Setup_environnement,0;"
        boardRows["MainInstall"]+="System,Optimization,Inspect/clean/update/requirements,0;"
        boardRows["MainInstall"]+="Hardware,Optimization,Inspect/update/requirements,0;"
        boardRows["MainInstall"]+="Software,Optimization,Install/configure/start,0;"
        boardRows["MainInstall"]+="Network,Optimization,Setup/secure/connect,0;"
        boardRows["MainInstall"]+="Juwju,Launch,Access_visual_next_step,0;"
    }



# +
###################################################################################
# 4. STEPS FUNCTIONS
###################################################################################
    pause() {
        local CurrentStep=$1
        local temp_file="$HOME/.system_setup_step" # Emplacement du fichier temporaire
        echo " "
        echo -e "${NC}Press [SPACE] to continue, [c] to clear and restart install, or [x] to exit...${NC}"

        # Configure le terminal en mode raw pour capturer les entrées clavier sans attendre "Entrée"
        stty -echo -icanon time 0 min 0 

        while true; do
            # Capture une seule touche sans attendre l'appui sur "Entrée"
            key=$(dd bs=1 count=1 2>/dev/null)

            case "$key" in
                " ") 
                    clear # Efface l'écran si [SPACE] est pressé
                    break ;; # Sort de la boucle pour continuer le script
                "x" | "X") 
                    echo -e "${RED}Exiting script...${NC}"
                    echo $CurrentStep > "$HOME/.system_setup_step" 
                    stty sane # Restaure les paramètres normaux du terminal
                    exit 0 ;; # Quitte le script avec succès
                "c" | "C") 
                    echo -e "${RED}Clearing and restarting install...${NC}"
                    echo 1 > "$HOME/.system_setup_step" # Réinitialise l'étape à 1 dans le fichier temporaire
                    stty sane # Restaure les paramètres normaux du terminal
                    exec /bin/bash "$(realpath "$0")" "$@" # Relance le script avec un chemin absolu
                    ;;
                *) 
                    # Ignorer toutes les autres touches
                    ;;
            esac
        done

        # Restaure les paramètres normaux du terminal avant de quitter la fonction
        stty sane
    }
    loadStep() {
        local temp_file="$HOME/.system_setup_step" # Emplacement persistant
        local default_step=1 # Étape par défaut si le fichier n'existe pas

        # Vérifier si le fichier temporaire existe
        if [ -f "$temp_file" ]; then
            # Lire l'étape actuelle depuis le fichier
            local current_step=$(cat "$temp_file")
            echo "$current_step"
        else
            # Retourner l'étape par défaut si le fichier n'existe pas
            echo "$default_step"
        fi
    }
    saveStep() {
        local step=$1
        local temp_file="$HOME/.system_setup_step" # Emplacement persistant

        # Enregistrer l'étape actuelle dans le fichier temporaire
        echo "$step" > "$temp_file"
        #echo -e "${GREEN}Step $step saved to $temp_file.${NC}"
    }
    clearStep() {
        local temp_file="$HOME/.system_setup_step" # Emplacement persistant

        # Vérifier si le fichier temporaire existe
        if [ -f "$temp_file" ]; then
            # Lire l'étape actuelle depuis le fichier
            rm $temp_file
        fi
    }
    RestartorNot() {

        local current_step=$1  # Current step passed as a parameter
        
        show_juwju_logo
        echo -e "${BLUE}============================================================"
        echo -e "${GREEN} RESUME INSTALLATION"  # Titre de la note en majuscules
        echo -e "${BLUE}============================================================"
        echo ""
        # Display options for the user
        echo -e "${NC}What would you like to do?"
        echo "1) Continue installation from step $current_step"
        echo "2) Restart installation from the beginning"
        echo "3) Stop the process"

        # Read user input
        while true; do
            read -rp "Enter your choice (1/2/3): " user_choice
            case $user_choice in
            1)
                echo -e "${GREEN}Continuing installation from step $current_step...${NC}"
                return 0  # Continue normally
                ;;
            2)
                echo -e "${YELLOW}Restarting installation from the beginning...${NC}"
                return 1  # Indicate that the process should restart
                ;;
            3)
                echo -e "${RED}Process stopped by the user.${NC}"
                exit 0  # Exit the script
                ;;
            *)
                echo -e "${RED}Invalid choice. Please enter 1, 2, or 3.${NC}"
                ;;
            esac
        done
    }
# +
###################################################################################
# 5. QUESTIONS FUNCTIONS
###################################################################################
    QT_Invitation() {
        if [ -n "$INVITATION_RESPONSE" ]; then
            invitation_response="$INVITATION_RESPONSE"
            echo -e "${NC}Do you have a Juwju invitation? (Y/N): $invitation_response${NC}"
        else
            echo -e "${NC}Do you have a Juwju invitation? (Y/N):${NC}"
            read -r -n 1 invitation_response
            echo # Force newline for clean output
        fi

        case "$invitation_response" in
            [Yy])
                echo -e "${NC}Please enter your invitation code:${NC}"
                read -p "> " invitation_code
                echo ""
                echo -e "${CYAN}Invitation code received: ${GREEN}$invitation_code${NC}"
                ;;
            [Nn])
                echo ""
                echo -e "${CYAN}No invitation received. Proceeding with basic setup...${NC}"
                ;;
            *)
                echo ""
                echo -e "${RED}Invalid input. Proceeding with basic setup...${NC}"
                ;;
        esac
        sleep 1
        echo ""
        echo ""
    }
# +
###################################################################################
# 7. START INSTALL FUNCTIONS
###################################################################################
    SetupPermission() {
        clear
        echo -e "${BLUE}============================================================"
        echo -e "${GREEN} SETUP PERMISSIONS                              "
        echo -e "${BLUE}============================================================"

        # Fonction pour vérifier ou créer un groupe
        check_or_create_group() {
            local group_name=$1
            if ! getent group "$group_name" > /dev/null; then
                sudo groupadd "$group_name"
                if [ $? -eq 0 ]; then
                    format_message "Setup groups $group_name" "${GREEN}OK${BLUE}"
                else
                    format_message "Setup groups $group_name" "${RED}NO${BLUE}"
                    exit 1
                fi
            else
                format_message "Setup groups $group_name" "${GREEN}OK${BLUE}"
            fi
        }

        # Fonction pour vérifier ou créer un utilisateur
        check_or_create_user() {
            local username=$1
            local default_group=$2
            if ! id "$username" &>/dev/null; then
                sudo useradd -m -g "$default_group" "$username"
                if [ $? -eq 0 ]; then
                    echo "$username:changeme" | sudo chpasswd # Définir un mot de passe par défaut
                    format_message "Setup user $username (pwd=temppwd)" "${GREEN}OK${BLUE}"
                else
                    format_message "Setup user $username" "${RED}NO${BLUE}"
                    exit 1
                fi
            else
                format_message "Setup user $username" "${GREEN}OK${BLUE}"
            fi
        }

        # Fonction pour ajouter un utilisateur à un groupe
        add_user_to_group() {
            local user=$1
            local group_name=$2
            if id -nG "$user" | grep -qw "$group_name"; then
                format_message "Setup permission for $user in group $group_name" "${GREEN}OK${BLUE}"
            else
                sudo usermod -aG "$group_name" "$user"
                if [ $? -eq 0 ]; then
                    format_message "Setup permission for $user in group $group_name" "${GREEN}OK${BLUE}"
                else
                    format_message "Setup permission for $user in group $group_name" "${RED}NO${BLUE}"
                    exit 1
                fi
            fi
        }

        # Fonction pour accorder l'accès sudo à un groupe via le fichier sudoers.d
        grant_sudo_access() {
            local group_name=$1
            local sudoers_file="/etc/sudoers.d/$group_name"
            if [ ! -f "$sudoers_file" ]; then
                echo "%$group_name ALL=(ALL) NOPASSWD:ALL" | sudo tee "$sudoers_file" > /dev/null
                if [ $? -eq 0 ]; then
                    format_message "Grant $group_name to admin master" "${GREEN}OK${BLUE}"
                else
                    format_message "Grant $group_name to admin master" "${RED}NO${BLUE}"
                    exit 1
                fi
            else
                format_message "Grant $group_name to admin master" "${GREEN}OK${BLUE}"
            fi

            # Vérifier que les permissions sont correctes pour le fichier sudoers.d créé.
            sudo chmod 440 "$sudoers_file"
        }

        # Vérifier ou créer les groupes 'juwju' et 'jjteam'
        check_or_create_group "juwju"
        check_or_create_group "jjteam"

        # Vérifier ou créer l'utilisateur 'juwju'
        check_or_create_user "juwju" "juwju"

        # Ajouter l'utilisateur actuel aux groupes nécessaires (juwju et jjteam)
        add_user_to_group "juwju" "juwju"
        add_user_to_group "$USER" "jjteam"

        # Accorder l'accès sudo aux groupes 'juwju' et 'jjteam'
        grant_sudo_access "juwju"

    }
    SetupJJDirectory() {
        clear
        echo -e "${BLUE}============================================================"
        echo -e "${GREEN} SETUP JUWJU DIRECTORY                            "
        echo -e "${BLUE}============================================================"
        local base_dir="/var/app"
        local group_name="juwju"

        # Vérifie si le répertoire de base existe, sinon le crée avec les permissions appropriées
        if [ ! -d "$base_dir" ]; then
            sudo mkdir -p "$base_dir"
            sudo chown :$group_name "$base_dir"
            sudo chmod 770 "$base_dir"
            if [ $? -eq 0 ]; then
                format_message "Setup $base_dir" "${GREEN}OK${BLUE}"
            else
                format_message "Setup $base_dir" "${RED}NO${BLUE}"
                exit 1
            fi
        else
            format_message "Setup $base_dir" "${GREEN}OK${BLUE}"
        fi
    }
    CloneBase() {
        local repo_path="/var/app/0010000-JUWJU"
        local repo_url="https://gitlab.com/juwju/0010000-JUWJU.git"

        # Vérifie si le répertoire cible existe
        if [ -d "$repo_path" ]; then
            cd "$repo_path" || { format_message "Access $repo_path directory" "${RED}NO${BLUE}"; exit 1; }

            # Sauvegarder les modifications locales si elles existent
            if ! git diff --quiet || ! git diff --cached --quiet; then
                echo "Stashing local changes..."
                git stash > /dev/null 2>&1
            fi

            # Mettre à jour le dépôt
            git pull > /dev/null 2>&1
            if [ $? -eq 0 ]; then
                format_message "Update Juwju repository" "${GREEN}OK${BLUE}"
            else
                format_message "Update Juwju repository" "${RED}NO${BLUE}"
                exit 1
            fi

            # Restaurer les modifications locales si elles ont été sauvegardées
            if git stash list | grep -q "stash@{0}"; then
                echo "Restoring stashed changes..."
                git stash pop > /dev/null 2>&1
            fi
        else
            # Si le dépôt n'existe pas, cloner le dépôt
            mkdir -p "/var/app/"
            cd "/var/app/" || { format_message "Access /var/app directory" "${RED}NO${BLUE}"; exit 1; }
            git clone "$repo_url" > /dev/null 2>&1
            if [ $? -eq 0 ]; then
                format_message "Clone Juwju repository" "${GREEN}OK${BLUE}"
            else
                format_message "Clone Juwju repository" "${RED}NO${BLUE}"
                exit 1
            fi
        fi
    }
    execSH() {
        local file_path=$1

        # Vérifier si le fichier existe
        if [ -f "$file_path" ]; then
        
            # Exécuter le fichier avec source et gérer les erreurs
            source "$file_path" || {
                format_message "Source $file_path" "${RED}NO${BLUE}"
                echo "An error occurred while sourcing $file_path"
                exit 1
            }

            format_message "Source $file_path" "${GREEN}OK${BLUE}"
        else
            format_message "$file_path does not exist" "${RED}NO${BLUE}"
            exit 1
        fi
    }
# +
main() {
    loadNotes
    loadBoard
    local temp_file="$HOME/.system_setup_step" # Emplacement persistant pour sauvegarder l'étape actuelle

    # Charger l'étape actuelle depuis le fichier temporaire ou initialiser à 1 si le fichier n'existe pas
    MasterSteps=$(loadStep "$temp_file")

    if [ "$MasterSteps" -gt 1 ]; then
        RestartorNot $MasterSteps
        user_decision=$?  # Capture return value

        if [ "$user_decision" -eq 1 ]; then
        # Restart from the beginning
        MasterSteps=1
        fi
    fi


    while true; do
        case $MasterSteps in
            1)
                show_juwju_logo
                showNotes "welcome" "noclear"
                pause $MasterSteps
                showNotes "policies"
                pause $MasterSteps
                showNotes "warning"
                saveStep 2 "$temp_file" # Sauvegarder l'étape suivante dans le fichier temporaire
                pause $MasterSteps ;;
            2)
                showBoard "MainInstall"
                pause $MasterSteps
                SetupPermission
                saveStep 3 "$temp_file"
                pause $MasterSteps ;;
            3)
                SetupJJDirectory
                CloneBase
                saveStep 4 "$temp_file"
                pause $MasterSteps ;;
            4)
                execSH "/var/app/0010000-JUWJU/000000-SRV-SCRIPT/00010-Bash/0020-SYSTEM.sh"
                saveStep 5 "$temp_file"
                pause $MasterSteps ;;
            5)
                execSH "/var/app/0010000-JUWJU/000000-SRV-SCRIPT/00010-Bash/0020-SYSTEM.sh"
                saveStep 6 "$temp_file"
                pause $MasterSteps ;;
            *)
                echo -e "${GREEN}SYSTEM SETUP COMPLETED SUCCESSFULLY!${NC}"
                rm -f "$temp_file" # Supprimer le fichier temporaire après la fin du processus.
                exit 0 ;;
        esac

        MasterSteps=$((MasterSteps + 1)) # Passer à l'étape suivante automatiquement après chaque boucle.
    done
}

# Appeler la fonction principale pour démarrer le processus.
main











