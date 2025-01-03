#!/bin/bash


# Variables pour les couleurs (facultatif)
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # Pas de couleur



SetupNVidia() {
    local gpu_board="$1"
    local driver_required_version="535.54.03" # Exemple de version minimale requise (modifiez si nécessaire)

    # Charger le tableau associatif passé en argument
    eval "$(echo "$gpu_board")"

    # Vérifier si un GPU NVIDIA est présent
    nvidia_found=false
    for model in "${!gpu_board[@]}"; do
        IFS='|' read manufacturer vram status <<< "${gpu_board[$model]}"
        if [[ "$manufacturer" == "NVIDIA" ]]; then
            nvidia_found=true
            break
        fi
    done

    if ! $nvidia_found; then
        echo -e "${RED}No NVIDIA GPUs detected. Skipping configuration.${NC}"
        return 1
    fi

    echo -e "${BLUE}Checking NVIDIA drivers and system configuration...${NC}"

    # Ajouter le dépôt officiel NVIDIA si nécessaire
    if ! grep -q "nvidia" /etc/apt/sources.list.d/* 2>/dev/null; then
        echo -e "${YELLOW}Adding NVIDIA repository...${NC}"
        sudo apt update
        sudo apt install -y software-properties-common
        sudo add-apt-repository -y ppa:graphics-drivers/ppa
        sudo apt update
    fi

    # Détecter la version recommandée du pilote NVIDIA
    RecommendedDriver=$(ubuntu-drivers devices | grep "recommended" | awk '{print $3}')
    if [ -z "$RecommendedDriver" ]; then
        echo -e "${RED}No recommended NVIDIA driver found. Exiting.${NC}"
        return 1
    fi

    # Installer le pilote recommandé s'il n'est pas déjà installé
    if ! dpkg -l | grep -q "$RecommendedDriver"; then
        echo -e "${YELLOW}Installing recommended NVIDIA driver: $RecommendedDriver...${NC}"
        sudo apt install -y "$RecommendedDriver" || {
            echo -e "${RED}Failed to install NVIDIA driver.${NC}"
            return 1
        }
    else
        echo -e "${GREEN}NVIDIA driver $RecommendedDriver is already installed.${NC}"
    fi

    # Vérifier si nvidia-smi fonctionne correctement
    if ! command -v nvidia-smi >/dev/null 2>&1; then
        echo -e "${RED}nvidia-smi not found or failed to execute. Check your NVIDIA driver installation.${NC}"
        return 1
    fi

    # Vérifier la version du pilote installé avec nvidia-smi
    driver_installed_version=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -n 1)
    if [ -z "$driver_installed_version" ]; then
        echo -e "${RED}Failed to detect NVIDIA driver version.${NC}"
        return 1
    fi

    if dpkg --compare-versions "$driver_installed_version" "lt" "$driver_required_version"; then
        echo -e "${RED}Driver is outdated (v$driver_installed_version). Required: v$driver_required_version.${NC}"
        return 1
    else
        echo -e "${GREEN}Driver is up-to-date (v$driver_installed_version).${NC}"
    fi

    # Récupérer la VRAM via nvidia-smi et mettre à jour le tableau associatif pour chaque GPU NVIDIA
    for model in "${!gpu_board[@]}"; do
        IFS='|' read manufacturer current_vram current_status <<< "${gpu_board[$model]}"
        if [[ "$manufacturer" == "NVIDIA" ]]; then
            vram=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -n 1)MiB
            gpu_board["$model"]="$manufacturer|$vram|Driver Installed (v$driver_installed_version)"
        fi
    done

    # Vérifier si CUDA est installé (nvcc)
    if ! command -v nvcc >/dev/null 2>&1; then
        echo -e "${BLUE}CUDA toolkit not found. Installing CUDA...${NC}"

        CUDA_REPO="https://developer.download.nvidia.com/compute/cuda/repos/ubuntu$(lsb_release -rs | cut -d'.' -f1)/x86_64/cuda-ubuntu$(lsb_release -rs | cut -d'.' -f1).pin"
        wget "$CUDA_REPO" || {
            echo -e "${RED}Failed to download CUDA repository information.${NC}"
            return 1
        }
        sudo mv cuda-ubuntu*.pin /etc/apt/preferences.d/cuda-repository-pin-600
        sudo apt-key adv --fetch-keys "https://developer.download.nvidia.com/compute/cuda/repos/ubuntu$(lsb_release -rs | cut -d'.' -f1)/x86_64/7fa2af80.pub"
        sudo add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu$(lsb_release -rs | cut -d'.' -f1)/x86_64/ /"
        sudo apt update && sudo apt install -y cuda || {
            echo -e "${RED}Failed to install CUDA toolkit.${NC}"
            return 1
        }
    else
        echo -e "${GREEN}CUDA toolkit is already installed.${NC}"
    fi

    # Installer NCCL si nécessaire pour multi-GPU support (libnccl)
    if ! dpkg -l | grep -q "libnccl"; then
        echo -e "${YELLOW}Installing NVIDIA NCCL library...${NC}"
        sudo apt install -y libnccl2 libnccl-dev || {
            echo -e "${RED}Failed to install NCCL.${NC}"
            return 1
        }
    else
        echo -e "${GREEN}NCCL library is already installed.${NC}"
    fi

    # Réexporter le tableau mis à jour pour utilisation ultérieure dans le script principal.
    export GPU_BOARD=$(declare -p gpu_board)
}


SmiInstalled() {
    if command -v nvidia-smi >/dev/null 2>&1; then
        return 0 # Vrai : nvidia-smi est installé
    else
        return 1 # Faux : nvidia-smi n'est pas installé
    fi
}


# Fonction pour mettre à jour les informations NVIDIA dans le tableau associatif
UpdateBoardNvidia() {
    local gpu_board="$1"
    local vram="$2"
    local status="$3"

    # Charger le tableau passé en argument
    eval "$(echo "$gpu_board")"

    for model in "${!gpu_board[@]}"; do
        IFS='|' read manufacturer current_vram current_status <<< "${gpu_board[$model]}"

        # Mettre à jour uniquement les GPU NVIDIA
        if [[ "$manufacturer" == "NVIDIA" ]]; then
            gpu_board["$model"]="$manufacturer|$vram|$status"
        fi
    done

    # Réexporter le tableau mis à jour
    PrintGPUBoard GPU_BOARD=$(declare -p gpu_board)
    export GPU_BOARD=$(declare -p gpu_board)

}

PrintGPUBoard() {
    clear
    echo -e "${BLUE}============================================================"
    echo -e "${GREEN} GPU DETECTION AND CONFIGURATION"
    echo -e "${BLUE}============================================================"
    echo ""
    echo ""
    echo -e "${GREEN}Manufacturer${BLUE} | ${GREEN}Model${BLUE}             | ${GREEN}VRAM${BLUE}         | ${GREEN}STATUS${BLUE}"
    echo -e "${BLUE}============================================================"

    declare -A gpu_board

    # Vérifier si un tableau est passé en argument, sinon initialiser les informations GPU
    if [ -z "$1" ]; then
        # Vérifier si nvidia-smi est installé
        if command -v nvidia-smi >/dev/null 2>&1; then
            echo -e "${YELLOW}Using nvidia-smi to retrieve GPU information...${NC}"

            # Récupérer les informations des GPU NVIDIA via nvidia-smi
            while IFS= read -r line; do
                model=$(echo "$line" | awk -F',' '{print $1}' | xargs)
                vram=$(echo "$line" | awk -F',' '{print $2}' | xargs)MiB
                status="Driver Installed"

                gpu_board["$model"]="NVIDIA|$vram|$status"
            done < <(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader,nounits)
        else
            echo -e "${YELLOW}Using lspci to retrieve GPU information...${NC}"

            # Récupérer les informations sur les GPU via lspci
            gpu_list=$(lspci | grep -E 'VGA|3D|Display')

            if [ -z "$gpu_list" ]; then
                echo "No GPUs detected on this system."
                return 1
            fi

            # Parcourir chaque ligne de la liste des GPU détectés par lspci
            while IFS= read -r line; do
                if echo "$line" | grep -q "NVIDIA"; then
                    manufacturer="NVIDIA"
                elif echo "$line" | grep -q "AMD"; then
                    manufacturer="AMD"
                else    
                    manufacturer="UNKNOWN"
                fi

                model=$(echo "$line" | awk -F': ' '{print $2}' | sed -E 's/.*Corporation //; s/\[//; s/\].*//; s/\(rev .*\)//' | xargs)
                model=$(echo "$model" | sed -E 's/^[A-Z0-9]+ //')

                vram="Analyzing..."
                status="Analyzing..."

                gpu_board["$model"]="$manufacturer|$vram|$status"
            done <<< "$gpu_list"
        fi

        # Exporter le tableau associatif pour une utilisation ultérieure dans d'autres fonctions
        export GPU_BOARD=$(declare -p gpu_board)
    else
        eval "$(echo "$1")"
    fi

    # Afficher les informations formatées du tableau associatif
    for model in "${!gpu_board[@]}"; do
        IFS='|' read manufacturer vram status <<< "${gpu_board[$model]}"
        printf "${BLUE}%-12s | %-17s | ${YELLOW}%-10s ${BLUE}| ${YELLOW}%-10s${NC}\n" "$manufacturer" "$model" "$vram" "$status"
    done

    sleep 1
}

# Fonction principale pour détecter et configurer les GPU
SetupGPU() {
    NVIDIA_Presence=false
    AMD_Presence=false
    MultiNvidiaGPU=false

    # Appeler PrintGPUBoard pour initialiser les GPU et exporter les données
    PrintGPUBoard

    # Charger le tableau associatif exporté par PrintGPUBoard
    eval "$(echo $GPU_BOARD)"

    # Détecter les GPU présents et mettre à jour leur statut initialement
    for model in "${!gpu_board[@]}"; do
        IFS='|' read manufacturer vram status <<< "${gpu_board[$model]}"

        if [[ "$manufacturer" == "NVIDIA" ]]; then
            if $NVIDIA_Presence; then
                MultiNvidiaGPU=true
            fi
            NVIDIA_Presence=true
            gpu_board["$model"]="$manufacturer|$vram|Setup..."
        elif [[ "$manufacturer" == "AMD" ]]; then
            AMD_Presence=true
            gpu_board["$model"]="$manufacturer|$vram|Setup..."
        fi        
    done

    # Réafficher le tableau mis à jour avec les nouveaux statuts
    PrintGPUBoard "$(declare -p gpu_board)"

    # Configurer NVIDIA si présent
    if $NVIDIA_Presence; then
        SetupNvidia "$(declare -p gpu_board)"  # Appeler la fonction pour installer les pilotes NVIDIA

        if $MultiNvidiaGPU; then  # Si plusieurs GPU NVIDIA sont présents
            UpdateBoardNvidia "$(declare -p gpu_board)" "Analyzing..." "Installing NCCL..."
            SetupMultiNvidia  # Appeler la fonction pour installer NCCL (multi-GPU)
        fi
    fi

    # Configurer AMD si présent
    if $AMD_Presence; then
        SetupAMD  # Appeler la fonction pour configurer AMD (à implémenter)
    fi

    echo ""
}

