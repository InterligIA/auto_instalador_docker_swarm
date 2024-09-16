#!/bin/bash

# Função para coletar informações do usuário
get_user_input() {
    read -p "Digite o IP do manager: " ip_manager
    read -p "Digite o domínio do Portainer: " dominio_portainer
    read -p "Digite um email válido: " email_valido
}

# Função para instalar o Docker e iniciar o Swarm
install_docker_and_swarm() {
    apt-get update
    apt install -y sudo gnupg2 wget ca-certificates apt-transport-https curl gnupg nano htop
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    sudo systemctl enable docker.service
    sudo systemctl enable containerd.service

    docker swarm init --advertise-addr=$ip_manager
}

# Função para configurar a rede do Docker Swarm
configure_network() {
    docker network create --driver=overlay rede_publica
}

# Função para criar o stack do Traefik
create_traefik_stack() {
    cat << EOF > traefik-stack.yml
version: "3.7"

services:
  traefik:
    image: traefik:v2.11.3
    hostname: "{{.Service.Name}}.{{.Task.Slot}}"
    command:
      - "--api.dashboard=true"
      - "--providers.docker.swarmMode=true"
      - "--providers.docker.endpoint=unix:///var/run/docker.sock"
      - "--providers.docker.exposedbydefault=false"
      - "--providers.docker.network=rede_publica"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.web.http.redirections.entryPoint.to=websecure"
      - "--entrypoints.web.http.redirections.entryPoint.scheme=https"
      - "--entrypoints.web.http.redirections.entrypoint.permanent=true"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.lets.acme.httpchallenge=true"
      - "--certificatesresolvers.lets.acme.httpchallenge.entrypoint=web"
      - "--certificatesresolvers.lets.acme.email=$email_valido"
      - "--certificatesresolvers.lets.acme.storage=/etc/traefik/letsencrypt/acme.json"
      - "--log.level=DEBUG"
      - "--log.format=common"
      - "--log.filePath=/var/log/traefik/traefik.log"
      - "--accesslog=true"
      - "--accesslog.filepath=/var/log/traefik/access-log"
    deploy:
      placement:
        constraints:
          - node.role == manager
      labels:
        - "traefik.enable=true"
        - "traefik.http.middlewares.redirect-https.redirectscheme.scheme=https"
        - "traefik.http.middlewares.redirect-https.redirectscheme.permanent=true"
        - "traefik.http.routers.http-catchall.rule=hostregexp(\`{host:.+}\`)"
        - "traefik.http.routers.http-catchall.entrypoints=web"
        - "traefik.http.routers.http-catchall.middlewares=redirect-https@docker"
        - "traefik.http.routers.http-catchall.priority=1"
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
      - "vol_certificates:/etc/traefik/letsencrypt"
    networks:
      - rede_publica
    ports:
      - target: 80
        published: 80
        mode: host
      - target: 443
        published: 443
        mode: host

volumes:
  vol_shared:
    external: true
    name: volume_swarm_shared
  vol_certificates:
    external: true
    name: volume_swarm_certificates

networks:
  rede_publica:
    external: true
    name: rede_publica
EOF

    docker stack deploy -c traefik-stack.yml traefik
}

# Função para criar o stack do Portainer
create_portainer_stack() {
    cat << EOF > portainer-stack.yml
version: "3.7"

services:
  agent:
    image: portainer/agent:sts
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /var/lib/docker/volumes:/var/lib/docker/volumes
    networks:
      - rede_publica
    deploy:
      mode: global
      placement:
        constraints: [node.platform.os == linux]

  portainer:
    image: portainer/portainer-ce:sts
    command: -H tcp://tasks.agent:9001 --tlsskipverify
    volumes:
      - portainer_data:/data
    networks:
      - rede_publica
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints: [node.role == manager]
      labels:
        - "traefik.enable=true"
        - "traefik.docker.network=rede_publica"
        - "traefik.http.routers.portainer.rule=Host(\`$dominio_portainer\`)"
        - "traefik.http.routers.portainer.entrypoints=websecure"
        - "traefik.http.routers.portainer.priority=1"
        - "traefik.http.routers.portainer.tls.certresolver=let"
        - "traefik.http.routers.portainer.service=portainer"
        - "traefik.http.services.portainer.loadbalancer.server.port=9000"

networks:
  rede_publica:
    external: true
    attachable: true
    name: rede_publica

volumes:
  portainer_data:
    external: true
    name: portainer_data
EOF

    docker stack deploy -c portainer-stack.yml portainer
}

# Função principal
main() {
    get_user_input
    install_docker_and_swarm
    configure_network
    create_traefik_stack
    create_portainer_stack
    echo "Instalação concluída!"
}

# Executar a função principal
main
