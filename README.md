# Auto-Instalador Docker Swarm

Este repositório contém um script de auto-instalação para configurar um ambiente Docker Swarm com Traefik e Portainer. O script automatiza o processo de instalação do Docker, inicialização do Swarm e implantação do Traefik como proxy reverso e do Portainer para gerenciamento de contêineres.

## Características

- Instalação automatizada do Docker e suas dependências
- Inicialização do Docker Swarm
- Implantação do Traefik v2.11.3 com HTTPS automático
- Implantação do Portainer CE para fácil gerenciamento de contêineres
- Prompt interativo para personalização

## Pré-requisitos

- Uma distribuição Linux baseada em Debian (ex: Debian, Ubuntu)
- Acesso root ou sudo
- Conectividade com a internet

## Uso

1. Instale o Git (se ainda não estiver instalado):
   ```
   sudo apt-get update
   sudo apt-get install git -y
   ```

2. Clone o repositório:
   ```
   git clone https://github.com/InterligIA/auto_instalador_docker_swarm.git
   ```

3. Navegue até o diretório clonado:
   ```
   cd auto_instalador_docker_swarm
   ```

4. Torne o script executável:
   ```
   chmod +x auto_instalador_interligia.sh
   ```

5. Execute o script:
   ```
   sudo ./auto_instalador_interligia.sh
   ```

6. Siga os prompts interativos para fornecer:
   - Seu endereço de e-mail (para certificados Let's Encrypt)
   - O domínio para o Portainer (ex: portainer.seudominio.com)
   - O endereço IP do nó gerenciador do Swarm

## O que o Script Faz

1. Instala o Docker e suas dependências
2. Inicializa um Docker Swarm
3. Cria uma rede overlay pública para serviços do Swarm
4. Implanta o Traefik como proxy reverso com HTTPS automático
5. Implanta o Portainer para gerenciamento de contêineres

## Configuração

O script criará dois arquivos de stack:

- `traefik-stack.yml`: Contém a configuração do Traefik
- `portainer-stack.yml`: Contém a configuração do Portainer

Estes arquivos são criados no mesmo diretório do script e podem ser modificados para personalização adicional, se necessário.

## Considerações de Segurança

- O script irá expor as portas 80 e 443 no seu host. Certifique-se de que seu firewall esteja configurado adequadamente.
- O Traefik está configurado para redirecionar automaticamente HTTP para HTTPS.
- Certifique-se de manter seu sistema e a instalação do Docker atualizados.

## Solução de Problemas

Se você encontrar algum problema durante a instalação:

1. Verifique os logs do Traefik:
   ```
   docker service logs traefik_traefik
   ```

2. Verifique os logs do Portainer:
   ```
   docker service logs portainer_portainer
   ```

3. Certifique-se de que seu domínio está corretamente apontado para o endereço IP do seu servidor.

## Contribuindo

Contribuições para melhorar o auto-instalador são bem-vindas. Sinta-se à vontade para enviar pull requests ou criar issues para bugs e solicitações de recursos.

## Licença

Este projeto é de código aberto e está disponível sob a [Licença MIT](LICENSE).

## Aviso Legal

Este script é fornecido como está, sem quaisquer garantias. Sempre revise os scripts antes de executá-los com privilégios elevados e certifique-se de entender as mudanças que eles farão em seu sistema.
