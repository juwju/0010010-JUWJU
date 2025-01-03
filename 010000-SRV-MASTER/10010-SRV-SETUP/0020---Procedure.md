Je vais créer une structure Ansible pour automatiser le déploiement de cette architecture.

## Structure du Projet Ansible

```plaintext
project/
├── inventory.yml
├── group_vars/
│   └── all.yml
├── roles/
│   ├── common/
│   ├── wireguard/
│   ├── docker/
│   ├── swarm/
│   └── monitoring/
└── site.yml
```

## Préparation du système

```
sudo apt update
sudo apt install software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install ansible -y
```

## Playbook Principal (site.yml)

```yaml
- name: Deploy High Availability Cluster
  hosts: all
  become: true
  roles:
    - common
    - wireguard
    - docker
    - swarm
    - monitoring
```

## Configuration Système (roles/common/tasks/main.yml)

```yaml
- name: Configure system parameters
  sysctl:
    name: "{{ item.key }}"
    value: "{{ item.value }}"
    state: present
    reload: yes
  with_items:
    - { key: "net.ipv4.conf.default.rp_filter", value: "0" }
    - { key: "net.ipv4.conf.all.rp_filter", value: "0" }
    - { key: "net.ipv4.tcp_syncookies", value: "1" }
    - { key: "net.ipv4.ip_forward", value: "1" }
    - { key: "net.ipv6.conf.all.forwarding", value: "1" }
    - { key: "net.ipv6.conf.default.forwarding", value: "1" }
```

## Configuration Docker Swarm (roles/docker/templates/docker-compose.yml.j2)

```yaml
version: '3.8'
services:
  wireguard:
    image: 'linuxserver/wireguard'
    deploy:
      mode: global
    ports:
      - "51820:51820/udp"
    environment:
      - PUID=1000
      - PGID=1000
    volumes:
      - /lib/modules:/lib/modules:ro
      - wireguard_config:/config
    cap_add:
      - NET_ADMIN
      - SYS_MODULE

  minio:
    image: minio/minio
    command: server --console-address ":9001" http://minio{1...4}/data{1...4}
    deploy:
      mode: replicated
      replicas: 4
    ports:
      - "9000:9000"
      - "9001:9001"
    environment:
      - MINIO_ROOT_USER={{ minio_root_user }}
      - MINIO_ROOT_PASSWORD={{ minio_root_password }}
```

## Configuration Keepalived (roles/monitoring/templates/keepalived.conf.j2)

```yaml
- name: Configure Keepalived
  template:
    src: keepalived.conf.j2
    dest: /etc/keepalived/keepalived.conf
  vars:
    vrrp_script: |
      vrrp_script check_docker {
          script "/usr/bin/docker info"
          interval 2
          weight 2
      }
      
      vrrp_instance VI_1 {
          state {{ 'MASTER' if inventory_hostname == groups['swarm_managers'][0] else 'BACKUP' }}
          interface {{ ansible_default_ipv4.interface }}
          virtual_router_id 51
          priority {{ 100 + groups['swarm_managers'].index(inventory_hostname) * 10 }}
          virtual_ipaddress {
              {{ virtual_ip }}/24
          }
      }
```

## Variables Globales (group_vars/all.yml)

```yaml
---
# Réseau
virtual_ip: "172.23.0.100"
wireguard_port: 51820

# MinIO
minio_root_user: "admin"
minio_root_password: "{{ vault_minio_root_password }}"

# Docker Swarm
swarm_interface: "eth0"
docker_version: "20.10.21"

# Monitoring
prometheus_retention_days: 15
grafana_admin_password: "{{ vault_grafana_admin_password }}"
```

## Déploiement

```yaml
- name: Initialize Swarm Cluster
  hosts: swarm_managers[0]
  tasks:
    - name: Initialize Docker Swarm
      docker_swarm:
        state: present
        advertise_addr: "{{ ansible_default_ipv4.address }}"

- name: Join Swarm Cluster
  hosts: swarm_managers[1:]
  tasks:
    - name: Join Swarm Cluster
      docker_swarm:
        state: join
        advertise_addr: "{{ ansible_default_ipv4.address }}"
        join_token: "{{ hostvars[groups['swarm_managers'][0]].swarm_manager_token }}"
        remote_addrs: [ "{{ hostvars[groups['swarm_managers'][0]].ansible_default_ipv4.address }}" ]
```

Cette configuration Ansible automatise entièrement le déploiement de l'infrastructure, en incluant la configuration système, le réseau WireGuard, Docker Swarm, MinIO et le système de failover avec Keepalived.