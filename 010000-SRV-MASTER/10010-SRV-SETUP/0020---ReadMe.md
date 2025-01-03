# Architecture Distribuée égalitaire avec Haute Disponibilité - Documentation

## Table des Matières

- [Introduction](#introduction)
- [Architecture du Système](#architecture-du-système)
- [Avantages de cette Architecture](#avantages-de-cette-architecture)
- [Prérequis](#prérequis)
- [Procédure d'Installation](#procédure-dinstallation)
  - [1. Configuration d'Ansible](#1-configuration-dansible)
  - [2. Déploiement de WireGuard via Ansible](#2-déploiement-de-wireguard-via-ansible)
  - [3. Mise en Place de Docker Swarm avec Élection de Leader](#3-mise-en-place-de-docker-swarm-avec-élection-de-leader)
  - [4. Mise en Place de MinIO pour la Haute Disponibilité des Volumes Docker](#4-mise-en-place-de-minio-pour-la-haute-disponibilité-des-volumes-docker)
  - [5. Intégration de Prometheus et Grafana pour le Monitoring](#5-intégration-de-prometheus-et-grafana-pour-le-monitoring)
    - [5.1 Déploiement de Prometheus](#51-déploiement-de-prometheus)
    - [5.2 Déploiement de Grafana](#52-déploiement-de-grafana)
    - [5.3 Configuration du Monitoring Automatisé](#53-configuration-du-monitoring-automatisé)
  - [6. Déploiement des Services avec Docker Stack](#6-déploiement-des-services-avec-docker-stack)
- [Conclusion](#conclusion)
- [Annexes](#annexes)
  - [A. Exemple de Fichier d'Inventaire Ansible](#a-exemple-de-fichier-dinventaire-ansible)
  - [B. Exemple de Playbooks Ansible](#b-exemple-de-playbooks-ansible)
  - [C. Ressources Utiles](#c-ressources-utiles)

---

## Introduction

Cette documentation détaille la mise en place d'un système distribué optimisé pour Docker, intégrant un monitoring complet via **Prometheus** et **Grafana**. Le système est conçu pour être prêt à l'emploi lors du lancement, sans configuration supplémentaire pour visualiser les données de monitoring.

Les composants clés incluent :

- **WireGuard** : pour établir un réseau privé virtuel sécurisé entre les serveurs.
- **Docker Swarm** : pour l'orchestration des conteneurs avec un mécanisme d'élection de leader.
- **MinIO** : pour assurer la haute disponibilité des volumes Docker entre les serveurs.
- **Prometheus et Grafana** : pour le monitoring et la visualisation des métriques du système et des applications.
- **Ansible** : pour automatiser le déploiement et la configuration de l'ensemble du système.

## Architecture du Système

- **Serveurs** : Plusieurs serveurs identiques, chacun pouvant jouer le rôle de leader dans le cluster Docker Swarm.
- **WireGuard** : Crée un réseau privé sécurisé entre les serveurs.
- **Docker Swarm** : Gère l'orchestration des conteneurs avec un leader élu dynamiquement.
- **MinIO** : Fournit un stockage distribué pour la haute disponibilité des volumes Docker.
- **Prometheus** : Collecte les métriques des serveurs et des services Docker.
- **Grafana** : Fournit des tableaux de bord pour visualiser les métriques collectées par Prometheus.
- **Ansible** : Automate le déploiement de tous les composants ci-dessus.

### Intégration de Prometheus et Grafana

- **Prometheus** est déployé en tant que service Docker sur le cluster Swarm.
- **Grafana** est également déployé en tant que service Docker, préconfiguré pour utiliser Prometheus comme source de données et avec des tableaux de bord prêts à l'emploi.
- **Node Exporter** et **cAdvisor** sont utilisés pour collecter les métriques système et des conteneurs Docker, respectivement.
- **Les services sont instrumentés** pour exposer des métriques que Prometheus peut collecter.

## Avantages de cette Architecture

- **Prêt à l'Emploi** : Le monitoring est opérationnel dès le lancement, sans configuration supplémentaire.
- **Optimisé pour Docker** : Tous les composants sont déployés en conteneurs Docker pour une meilleure portabilité et gestion.
- **Haute Disponibilité et Résilience** : Grâce à Docker Swarm, MinIO et l'élection de leader, le système est tolérant aux pannes.
- **Automatisation Complète** : Ansible gère le déploiement, la configuration et la mise à jour de tous les composants.

## Prérequis

- **Serveurs** : Au moins trois serveurs avec accès SSH.
- **Systèmes d'Exploitation** : Linux (Ubuntu 20.04 ou supérieur recommandé).
- **Ansible** : Installé sur une machine de contrôle (peut être l'un des serveurs ou une machine séparée).
- **Clés SSH** : Accès SSH sans mot de passe aux serveurs pour Ansible.

---

## Procédure d'Installation

### 1. Configuration d'Ansible

#### 1.1 Installation d'Ansible sur la Machine de Contrôle

```bash
sudo apt update
sudo apt install ansible -y
```

#### 1.2 Configuration de l'Inventaire Ansible

Créez un fichier `hosts.ini` :

```ini
[servers]
server1 ansible_host=IP_SERVEUR_1 ansible_user=utilisateur
server2 ansible_host=IP_SERVEUR_2 ansible_user=utilisateur
server3 ansible_host=IP_SERVEUR_3 ansible_user=utilisateur

[all:vars]
ansible_python_interpreter=/usr/bin/python3
```

Assurez-vous que la connexion SSH est configurée avec des clés publiques.

### 2. Déploiement de WireGuard via Ansible

#### 2.1 Création du Playbook WireGuard

Créez un fichier `wireguard.yml` pour installer et configurer WireGuard sur tous les serveurs.

Le playbook :

- Installe WireGuard.
- Génère les paires de clés.
- Configure le fichier `wg0.conf`.
- Démarre et active le service WireGuard.

### 3. Mise en Place de Docker Swarm avec Élection de Leader

#### 3.1 Installation de Docker via Ansible

Créez un playbook `docker.yml` pour installer Docker CE sur tous les serveurs.

#### 3.2 Initialisation du Swarm

1. **Initialiser le Swarm sur le premier serveur** :

   ```bash
   docker swarm init --advertise-addr 10.0.0.1
   ```

2. **Joindre les autres serveurs au Swarm** :

   Utilisez le token généré pour les nœuds managers et joignez-les via Ansible.

### 4. Mise en Place de MinIO pour la Haute Disponibilité des Volumes Docker

#### 4.1 Déploiement de MinIO via Docker Stack

Créez un fichier `minio-stack.yml` avec la configuration de MinIO en mode distribué.

#### 4.2 Déploiement via Ansible

Créez un playbook `minio.yml` pour déployer le stack MinIO sur le Swarm.

### 5. Intégration de Prometheus et Grafana pour le Monitoring

#### 5.1 Déploiement de Prometheus

1. **Créer un fichier `prometheus.yml`** pour la configuration de Prometheus.

   Exemple de configuration pour scraper les métriques des nœuds et des services Docker :

   ```yaml
   global:
     scrape_interval: 15s

   scrape_configs:
     - job_name: 'prometheus'
       static_configs:
         - targets: ['localhost:9090']

     - job_name: 'node_exporter'
       static_configs:
         - targets: ['node1:9100', 'node2:9100', 'node3:9100']

     - job_name: 'cadvisor'
       static_configs:
         - targets: ['node1:8080', 'node2:8080', 'node3:8080']
   ```

2. **Créer un fichier `prometheus-stack.yml`** pour déployer Prometheus et cAdvisor.

   ```yaml
   version: '3.8'

   services:
     prometheus:
       image: prom/prometheus
       volumes:
         - ./prometheus.yml:/etc/prometheus/prometheus.yml
       ports:
         - "9090:9090"
       deploy:
         placement:
           constraints:
             - node.role == manager

     node-exporter:
       image: prom/node-exporter
       ports:
         - "9100:9100"
       deploy:
         mode: global

     cadvisor:
       image: google/cadvisor:latest
       ports:
         - "8080:8080"
       deploy:
         mode: global
       volumes:
         - /var/run:/var/run:rw
         - /sys:/sys:ro
         - /var/lib/docker/:/var/lib/docker:ro
   ```

#### 5.2 Déploiement de Grafana

1. **Créer un fichier `grafana-stack.yml`** pour déployer Grafana.

   ```yaml
   version: '3.8'

   services:
     grafana:
       image: grafana/grafana
       ports:
         - "3000:3000"
       volumes:
         - grafana-storage:/var/lib/grafana
       environment:
         - GF_SECURITY_ADMIN_PASSWORD=admin
       deploy:
         placement:
           constraints:
             - node.role == manager

   volumes:
     grafana-storage:
   ```

2. **Préconfiguration de Grafana** :

   - Utilisez des **provisioning files** pour configurer automatiquement la source de données Prometheus et importer des tableaux de bord.

   Exemple de fichier `datasource.yml` :

   ```yaml
   apiVersion: 1

   datasources:
     - name: Prometheus
       type: prometheus
       access: proxy
       url: http://prometheus:9090
       isDefault: true
   ```

   Exemple de fichier `dashboard.yml` :

   ```yaml
   apiVersion: 1

   providers:
     - name: 'default'
       orgId: 1
       folder: ''
       type: file
       options:
         path: /var/lib/grafana/dashboards
   ```

   Placez les fichiers de tableaux de bord JSON dans le dossier `dashboards`.

#### 5.3 Configuration du Monitoring Automatisé

- **Ansible Playbook** : Créez un playbook `monitoring.yml` pour déployer les stacks Prometheus et Grafana.
- **Automatisation** : Assurez-vous que les fichiers de configuration sont copiés sur les serveurs et que les services sont démarrés.
- **Prêt à l'Emploi** : Grâce aux provisionings, Grafana aura la source de données Prometheus configurée et les tableaux de bord disponibles dès le lancement.

### 6. Déploiement des Services avec Docker Stack

#### 6.1 Préparation des Fichiers Compose

- Créez des fichiers `docker-compose.yml` pour vos services applicatifs.
- Assurez-vous que les services sont instrumentés pour exposer des métriques Prometheus.

#### 6.2 Déploiement via Ansible

- Créez un playbook `deploy_services.yml` pour déployer les services sur le Swarm.
- Utilisez des labels pour indiquer à Prometheus de scraper les métriques des services.

---

## Conclusion

En intégrant **Prometheus** et **Grafana** dans le système dès le départ, nous fournissons un monitoring complet et prêt à l'emploi pour les serveurs et les services. L'utilisation de conteneurs Docker pour tous les composants simplifie le déploiement et la gestion. Ansible automatise l'ensemble du processus, garantissant une configuration cohérente et reproductible sur tous les serveurs.

Cette architecture offre une solution robuste, évolutive et facilement maintenable pour gérer un environnement distribué avec un monitoring efficace.

---

## Annexes

### A. Exemple de Fichier d'Inventaire Ansible

```ini
[servers]
node1 ansible_host=192.168.1.1 ansible_user=root
node2 ansible_host=192.168.1.2 ansible_user=root
node3 ansible_host=192.168.1.3 ansible_user=root

[all:vars]
ansible_python_interpreter=/usr/bin/python3
```

### B. Exemple de Playbooks Ansible

#### wireguard.yml

```yaml
- name: Installer et configurer WireGuard
  hosts: servers
  become: yes
  vars:
    wireguard_network_address: 10.0.0.0/24
    wireguard_port: 51820
  tasks:
    - name: Installer WireGuard
      apt:
        name: wireguard
        state: present
        update_cache: yes

    # Autres tâches pour générer les clés et configurer wg0.conf
```

#### docker.yml

```yaml
- name: Installer Docker
  hosts: servers
  become: yes
  tasks:
    - name: Installer les paquets prérequis
      apt:
        name: ['apt-transport-https', 'ca-certificates', 'curl', 'gnupg-agent', 'software-properties-common']
        state: present
        update_cache: yes

    - name: Ajouter la clé GPG de Docker
      apt_key:
        url: https://download.docker.com/linux/ubuntu/gpg
        state: present

    - name: Ajouter le dépôt Docker
      apt_repository:
        repo: deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable
        state: present

    - name: Installer Docker CE
      apt:
        name: ['docker-ce', 'docker-ce-cli', 'containerd.io']
        state: present
        update_cache: yes

    - name: Ajouter l'utilisateur au groupe docker
      user:
        name: "{{ ansible_user }}"
        groups: docker
        append: yes
```

#### monitoring.yml

```yaml
- name: Déployer Prometheus et Grafana
  hosts: servers
  become: yes
  tasks:
    - name: Créer le répertoire pour Prometheus
      file:
        path: /opt/prometheus
        state: directory
        owner: root
        group: root
        mode: '0755'

    - name: Copier le fichier prometheus.yml
      copy:
        src: prometheus.yml
        dest: /opt/prometheus/prometheus.yml
        owner: root
        group: root
        mode: '0644'

    - name: Déployer le stack Prometheus
      shell: |
        docker stack deploy -c prometheus-stack.yml monitoring
      args:
        chdir: /opt/prometheus

    - name: Déployer le stack Grafana
      shell: |
        docker stack deploy -c grafana-stack.yml monitoring
      args:
        chdir: /opt/grafana
```

### C. Ressources Utiles

- **Ansible Documentation** : https://docs.ansible.com/ansible/latest/index.html
- **Prometheus** : https://prometheus.io
- **Grafana** : https://grafana.com
- **Docker Swarm** : https://docs.docker.com/engine/swarm/
- **MinIO** : https://min.io
- **Docker Compose** : https://docs.docker.com/compose/

---

**Notes** :

- **Sécurité** : Assurez-vous de sécuriser les accès à Grafana (changer le mot de passe par défaut) et de restreindre les accès aux services de monitoring.
- **Personnalisation des Tableaux de Bord** : Vous pouvez importer des tableaux de bord préconçus depuis Grafana Labs ou créer les vôtres.
- **Scalabilité** : En mode Swarm, les services comme Prometheus et Grafana peuvent être répliqués pour la haute disponibilité.
- **Maintenance** : Pensez à mettre en place des sauvegardes pour les configurations de Grafana et les données critiques.
