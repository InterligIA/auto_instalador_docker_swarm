#!/bin/bash
echo -e "\e[32m\e[0m"
echo -e "\e[32m\e[0m"
echo -e "\e[32m  _____ _   _ _______ ______ _____  _      _____ _____   _____          \e[0m"
echo -e "\e[32m |_   _| \ | |__   __|  ____|  __ \| |    |_   _/ ____| |_   _|   /\    \e[0m"
echo -e "\e[32m   | | |  \| |  | |  | |__  | |__) | |      | || |  __    | |    /  \   \e[0m"
echo -e "\e[32m   | | |     |  | |  |  __| |  _  /| |      | || | |_ |   | |   / /\ \  \e[0m"
echo -e "\e[32m  _| |_| |\  |  | |  | |____| | \ \| |____ _| || |__| |  _| |_ / ____ \ \e[0m"
echo -e "\e[32m |_____|_| \_|  |_|  |______|_|  \_\______|_____\_____| |_____/_/    \_\ \e[0m"
echo -e "\e[32m\e[0m"
echo -e "\e[32m\e[0m"

# Função para mostrar um banner colorido
function show_banner() {
  echo -e "\e[32m==============================================================================\e[0m"
  echo -e "\e[32m=                                                                            =\e[0m"
  echo -e "\e[32m=                 \e[33mPreencha as informações solicitadas abaixo\e[32m                 =\e[0m"
  echo -e "\e[32m=                                                                            =\e[0m"
  echo -e "\e[32m==============================================================================\e[0m"
}

# Função para mostrar uma mensagem de etapa
function show_step() {
  echo -e "\e[32mPasso \e[33m$1/3\e[0m"
}

# Mostrar banner inicial
clear
show_banner
echo ""

# Solicitar informações do usuário
show_step 1
read -p "📧 Endereço de e-mail: " email
echo ""
show_step 2
read -p "🌐 Dominio do Portainer (ex: portainer.seudominio.com): " portainer
echo ""
show_step 3
read -p "🖥️ IP do Manager (ex: 192.168.0.100): " manager_ip
echo ""

# Verificação de dados
clear
echo ""
echo "📧 Seu E-mail: $email"
echo "🌐 Dominio do Portainer: $portainer"
echo "🖥️ IP do Manager: $manager_ip"
echo ""
read -p "As informações estão certas? (y/n): " confirma1
if [ "$confirma1" == "y" ]; then
  clear
  #########################################################
  # INSTALANDO DEPENDENCIAS
  #########################################################
  sudo apt-get update
  sudo apt install -y sudo gnupg2 wget ca-certificates apt-transport-https curl gnupg nano htop
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  echo \
    "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
    "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" |
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt-get update

  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  sudo systemctl enable docker.service
  sudo systemctl enable containerd.service

  sudo docker swarm init --advertise-addr=$manager_ip
  mkdir -p ~/Portainer && cd ~/Portainer
  echo -e "\e[32mAtualizado/Instalado com Sucesso\e[0m"
  sleep 3

  #########################################################
  # CRIANDO REDE DOCKER SWARM
  #########################################################
  sudo docker network create --driver=overlay rede_publica

  #########################################################
  # CRIANDO STACK TRAEFIK
  #########################################################
  cat > traefik-stack.yml <<EOL
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
      - "--certificatesresolvers.lets.acme.email=$email"
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
EOL

  #########################################################
  # CRIANDO STACK PORTAINER
  #########################################################
  cat > portainer-stack.yml <<EOL
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
        - "traefik.http.routers.portainer.rule=Host(\`$portainer\`)"
        - "traefik.http.routers.portainer.entrypoints=websecure"
        - "traefik.http.routers.portainer.priority=1"
        - "traefik.http.routers.portainer.tls.certresolver=lets"
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
EOL

  #########################################################
  # INICIANDO STACKS
  #########################################################
  echo -e "\e[32mDeploying stacks...\e[0m"
  sudo docker stack deploy -c traefik-stack.yml traefik
  sudo docker stack deploy -c portainer-stack.yml portainer
  
echo -e "\e[32m\e[0m"
echo -e "\e[32m\e[0m"
echo -e "\e[32m  _____ _   _ _______ ______ _____  _      _____ _____   _____          \e[0m"
echo -e "\e[32m |_   _| \ | |__   __|  ____|  __ \| |    |_   _/ ____| |_   _|   /\    \e[0m"
echo -e "\e[32m   | | |  \| |  | |  | |__  | |__) | |      | || |  __    | |    /  \   \e[0m"
echo -e "\e[32m   | | |     |  | |  |  __| |  _  /| |      | || | |_ |   | |   / /\ \  \e[0m"
echo -e "\e[32m  _| |_| |\  |  | |  | |____| | \ \| |____ _| || |__| |  _| |_ / ____ \ \e[0m"
echo -e "\e[32m |_____|_| \_|  |_|  |______|_|  \_\______|_____\_____| |_____/_/    \_\ \e[0m"
echo -e "\e[32m\e[0m"
echo -e "\e[32m\e[0m"
else
  echo "Encerrando a instalação, por favor, inicie a instalação novamente."
  exit 0
fi
