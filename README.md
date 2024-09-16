# # # Auto-instalador InterligIA com Docker Swarm, Traefik e Portainer

Este script automatiza a instalação e configuração de um ambiente Docker Swarm com Traefik como proxy reverso e Portainer para gerenciamento de contêineres.

## Requisitos

- Sistema operacional: Debian ou baseado em Debian (por exemplo, Ubuntu)
- Privilégios de root ou acesso sudo
- Conexão com a internet

## Componentes instalados

- Git
- Docker Engine
- Docker Swarm
- Traefik v2.11.3
- Portainer CE

## Instruções de uso

1. Instale o Git (se ainda não estiver instalado) e clone o repositório:
   ```
   sudo apt-get update && sudo apt-get install -y git && git clone https://github.com/InterligIA/auto_instalador_docker_swarm.git && cd auto_instalador_docker_swarm
   ```

2. Dê permissão de execução ao script:
   ```
   chmod +x auto_instalador_interligia.sh
   ```

3. Execute o script como root ou com sudo:
   ```
   sudo ./auto_instalador_interligia.sh
   ```

4. Siga as instruções na tela para fornecer as seguintes informações:
   - IP do manager (endereço IP do nó manager do Swarm)
   - Domínio do Portainer (domínio que será usado para acessar o Portainer)
   - Email válido (para registro do Let's Encrypt)

5. Aguarde a conclusão da instalação.

## O que o script faz

1. Coleta informações do usuário
2. Instala o Docker Engine
3. Inicializa o Docker Swarm
4. Configura a rede overlay do Docker Swarm
5. Cria e implanta o stack do Traefik
6. Cria e implanta o stack do Portainer

## Pós-instalação

Após a conclusão da instalação:

1. Acesse o Portainer através do domínio fornecido durante a instalação (https://seu-dominio-portainer).
2. Configure uma senha para o usuário admin do Portainer no primeiro acesso.
3. Use o Portainer para gerenciar seus contêineres, imagens, redes e volumes Docker.

## Observações

- Este script configura o Traefik para usar o Let's Encrypt para SSL/TLS automático.
- Certifique-se de que o domínio fornecido para o Portainer esteja apontando para o IP do seu servidor antes de executar o script.
- O script cria uma rede overlay chamada `rede_publica` que pode ser usada por outros serviços que você deseja expor através do Traefik.

## Solução de problemas

Se encontrar problemas durante a instalação:

1. Verifique se todos os requisitos foram atendidos.
2. Certifique-se de que o servidor tem acesso à internet.
3. Verifique se o domínio fornecido para o Portainer está corretamente configurado nos registros DNS.
4. Revise os logs do Docker e do sistema para identificar possíveis erros.
5. Se o problema persistir, abra uma issue no repositório GitHub do projeto: https://github.com/InterligIA/auto_instalador_docker_swarm/issues

## Atualizações

Para obter a versão mais recente do script:

1. Navegue até o diretório do repositório clonado.
2. Puxe as atualizações mais recentes:
   ```
   git pull origin main
   ```
3. Execute o script atualizado conforme as instruções acima.

## Contribuição

Sinta-se à vontade para contribuir com melhorias para este script através de pull requests no repositório GitHub: https://github.com/InterligIA/auto_instalador_docker_swarm

## Licença

Este script é fornecido "como está", sem garantias. Use por sua conta e risco.
