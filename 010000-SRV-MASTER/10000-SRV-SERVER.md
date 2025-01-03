# SERVER CONFIGURATION

## SERVEUR PRINCIPAL

Le server principal est accessible à l'ip 203.161.46.164
Ce serveur recoit les @.domaine.com et les redistribue au serveur secondaire en fonction du domaine
Ce serveur utilise l'app NGINX accessible dans le répertoire 203.161.46.164/opt/SERVER_MASTER

## SERVEUR SECONDAIRE

Les serveur seondaire recoivent les domaine serveurx.domaaine.com (x = numéro du serveur)
Les serveur secondaire sont sous des adresses IP dynamiques, ce qui oblige une mise à jour régulière des enregistrements DNS de Godaddy
Ce serveur utilise l'app NGINX accessible dans le répertoire /opt/SERVER/NGINX

## CONFIGURATION DU SERVEUR SECONDAIRE

### 1. Ajustement de l'heure

```bash
sudo timedatectl set-timezone America/Montreal
```

### 2. Variable d'environnement

```bash
sudo cp ./Templates/Server.env ./Server.env
```
Ajuster le nom du serveur dans Server.env

### 3. Création des networks docker

```bash
docker network create devreos_com
docker network create devreos_dev
docker network create mentheentretien_com
docker network create mentheentretien_dev
```

### 4. Création des variables d'environnement

```bash
sudo cp ./Templates/Server.env ./Server.env
```

### 5. Ajuster les permissions

```bash
sudo chmod -R 777 /opt/SERVER/LOGS
```

### 6. Lancer les containers

Sélectionnez le ID ou ajouter le domaine que vous souhaitez activer dans Server.env

```bash
yarn setupserver ID
yarn serverup
```
