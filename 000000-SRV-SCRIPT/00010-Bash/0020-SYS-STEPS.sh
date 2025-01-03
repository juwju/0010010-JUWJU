#!/bin/bash
sys_temp_file="$HOME/.system_sh_step" # Emplacement du fichier temporaire


format_message() {
    local message=$1
    local status=$2
    local max_length=55 # Longueur maximale pour l'alignement
    printf "${BLUE}%-${max_length}s [${status}]${NC}\n" "$message"
}

pause() {
    local CurrentStep=$1
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
    local default_step=1 # Étape par défaut si le fichier n'existe pas

    # Vérifier si le fichier temporaire existe
    if [ -f "$sys_temp_file" ]; then
        # Lire l'étape actuelle depuis le fichier
        local current_step=$(cat "$sys_temp_file")
        echo "$current_step"
    else
        # Retourner l'étape par défaut si le fichier n'existe pas
        echo "$default_step"
    fi
}
saveStep() {
    local step=$1

    # Enregistrer l'étape actuelle dans le fichier temporaire
    echo "$step" > "$sys_temp_file"
    #echo -e "${GREEN}Step $step saved to $sys_temp_file.${NC}"
}
clearStep() {

    # Vérifier si le fichier temporaire existe
    if [ -f "$sys_temp_file" ]; then
        # Lire l'étape actuelle depuis le fichier
        rm $sys_temp_file
    fi
}

    StepsSystemList() {
        local table_name="INSTALL STEPS"
        local headers="Target, Step, Description,States"
        local rows=""
        board4 "$table_name" "$headers" "$rows"
        BoardData addline "System,Permission,Setup groups and user,0"
        BoardData addline "System,Permission,Setup directories,0"
        BoardData addline "System,Download,Download required files,0"
        BoardData addline "System,Inspect,Resume system information,0"
        BoardData addline "System,Rebase,Clean system,0"
        BoardData addline "System,Update,Update system,0"
        BoardData addline "System,Reboot,Reboot system,0"

    }

RestoreBaseSystem() {
    echo -e "${BLUE}============================================================"
    echo -e "${GREEN} UBUNTU - CLEANING AND REBASE"
    echo -e "${BLUE}============================================================"

    # Vérifier et résoudre les problèmes de verrouillage apt
    echo -e "${YELLOW}Checking for apt locks...${NC}"
    if sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1; then
        echo -e "${RED}Another process is using apt. Terminating it...${NC}"
        sudo kill -9 $(sudo fuser /var/lib/apt/lists/lock | awk '{print $1}') || {
            echo -e "${RED}Failed to terminate the process using apt.${NC}"
            return 1
        }
    fi

    # Supprimer les fichiers de verrouillage si nécessaire
    echo -e "${YELLOW}Removing apt lock files...${NC}"
    sudo rm -f /var/lib/apt/lists/lock /var/cache/apt/archives/lock /var/lib/dpkg/lock-frontend || {
        echo -e "${RED}Failed to remove lock files.${NC}"
        return 1
    }
    format_message "Update Juwju repository" "${RED}NO${BLUE}"

    # Réinitialiser dpkg si nécessaire
    echo -e "${YELLOW}Configuring dpkg...${NC}"
    sudo dpkg --configure -a || {
        echo -e "${RED}Failed to configure dpkg.${NC}"
        return 1
    }

    # Réinstaller les paquets de base nécessaires pour un serveur minimal
    echo -e "${YELLOW}Reinstalling base system packages...${NC}"
    sudo apt install --reinstall ubuntu-minimal ubuntu-standard openssh-server net-tools curl wget -y || {
        echo -e "${RED}Failed to reinstall base system packages.${NC}"
        return 1
    }

    # Supprimer explicitement les environnements de bureau comme GNOME, KDE, etc.
    echo -e "${YELLOW}Removing desktop environments and graphical components...${NC}"
    
    # Suppression des environnements GNOME, KDE, LXDE, XFCE, etc.
    sudo apt purge --autoremove ubuntu-desktop gnome-shell gnome-desktop3-data gdm3 kde-standard kde-plasma-desktop lxde xfce4 lightdm xorg xserver-xorg* -y || {
        echo -e "${RED}Failed to remove desktop environments.${NC}"
        return 1
    }

    # Nettoyer les paquets inutiles après suppression
    echo -e "${YELLOW}Cleaning up unnecessary packages...${NC}"
    sudo apt autoremove --purge -y || {
        echo -e "${RED}Failed to autoremove unnecessary packages.${NC}"
        return 1
    }

    sudo apt clean || {
        echo -e "${RED}Failed to clean package cache.${NC}"
        return 1
    }

    # Vérifier si SSH est actif pour maintenir la connexion distante
    echo -e "${YELLOW}Ensuring SSH service is running...${NC}"
    sudo systemctl enable ssh || {
        echo -e "${RED}Failed to enable SSH service.${NC}"
        return 1
    }
    
    sudo systemctl start ssh || {
        echo -e "${RED}Failed to start SSH service.${NC}"
        return 1
    }

    echo -e "${GREEN}Base system restoration complete. Desktop environments removed.${NC}"
}

UpdateSystem() {
    echo -e "${BLUE}============================================================"
    echo -e "${GREEN} SYSTEM UPDATE PROCESS"
    echo -e "${BLUE}============================================================"

    # Vérifier la version actuelle du noyau
    current_kernel=$(uname -r)
    echo -e "${YELLOW}Current Kernel Version: ${NC}$current_kernel"

    # Vérifier et résoudre les problèmes de verrouillage apt
    echo -e "${YELLOW}Checking for apt locks...${NC}"
    if sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1; then
        echo -e "${RED}Another process is using apt. Terminating it...${NC}"
        sudo kill -9 $(sudo fuser /var/lib/apt/lists/lock | awk '{print $1}') || {
            echo -e "${RED}Failed to terminate the process using apt.${NC}"
            return 1
        }
    fi

    # Supprimer les fichiers de verrouillage si nécessaire
    echo -e "${YELLOW}Removing apt lock files...${NC}"
    sudo rm -f /var/lib/apt/lists/lock /var/cache/apt/archives/lock /var/lib/dpkg/lock-frontend || {
        echo -e "${RED}Failed to remove lock files.${NC}"
        return 1
    }

    # Réinitialiser dpkg si nécessaire
    echo -e "${YELLOW}Configuring dpkg...${NC}"
    sudo dpkg --configure -a || {
        echo -e "${RED}Failed to configure dpkg.${NC}"
        return 1
    }

    # Mettre à jour la liste des paquets
    echo -e "${YELLOW}Updating package list...${NC}"
    sudo apt update || {
        echo -e "${RED}Failed to update package list.${NC}"
        return 1
    }

    # Mettre à niveau tous les paquets, y compris le noyau
    echo -e "${YELLOW}Upgrading packages (including the kernel)...${NC}"
    sudo apt upgrade -y || {
        echo -e "${RED}Failed to upgrade packages.${NC}"
        return 1
    }

    # Vérifier si un nouveau noyau est disponible et installé
    new_kernel=$(uname -r)
    if [[ "$new_kernel" != "$current_kernel" ]]; then
        echo -e "${GREEN}Kernel updated successfully to version: ${NC}$new_kernel"
        echo -e "${YELLOW}Rebooting the system to apply the new kernel...${NC}"
        sudo reboot
    else
        echo -e "${RED}No new kernel version installed. The system is already up-to-date.${NC}"
        return 0
    fi
}

Reboot() {
    # Informer l'utilisateur
    echo -e "${YELLOW}The system needs to reboot to continue the setup.${NC}"
    echo -e "${YELLOW}Please wait for the server to restart, reconnect, and relaunch this script by simply tap up arrow on terminal line.${NC}"
    pause

    # Lancer le redémarrage
    sudo reboot || {
        echo -e "${RED}Failed to initiate reboot.${NC}"
        return 1
    }
}

main() {
    # Charger l'étape actuelle depuis le fichier temporaire ou initialiser à 1 si le fichier n'existe pas
    local current_step=$(loadStep "$sys_temp_file")

    if [ "$current_step" -gt 1 ]; then
        echo -e "${YELLOW}Resuming from step $current_step...${NC}"
    fi

    while true; do
        case $current_step in
            1)
                RestoreBaseSystem
                saveStep 2 "$sys_temp_file" # Sauvegarder l'étape suivante dans le fichier temporaire
                pause $current_step ;;
            2)
                UpdateSystem
                saveStep 3 "$sys_temp_file"
                pause $current_step ;;
            *)
                echo -e "${GREEN}SYSTEM SETUP COMPLETED SUCCESSFULLY!${NC}"
                rm -f "$sys_temp_file" # Supprimer le fichier temporaire après la fin du processus.
                exit 0 ;;
        esac

        current_step=$((current_step + 1)) # Passer à l'étape suivante automatiquement après chaque boucle.
    done
}

# Appeler la fonction principale pour démarrer le processus.
main

