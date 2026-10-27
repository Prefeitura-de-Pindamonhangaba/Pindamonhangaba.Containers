# Keycloak com PostgreSQL

Stack de uma instancia, com Keycloak 26.8.1 e PostgreSQL 17. Requer Docker Engine/Docker Desktop em modo Linux e Docker Compose v2. Reserve inicialmente cerca de 2 GB de RAM para a stack e acompanhe o consumo conforme a carga.

## Iniciar

Coloque compose.yml e .env.example na mesma pasta. No terminal dessa pasta:

```powershell
Copy-Item .env.example .env
```

No Linux/macOS, use `cp .env.example .env`.

Edite `.env` e preencha POSTGRES_PASSWORD e KC_BOOTSTRAP_ADMIN_PASSWORD com senhas diferentes e aleatorias. Exemplo para gerar uma senha de 64 caracteres no PowerShell (execute novamente para a outra senha):

```powershell
$bytes = New-Object byte[] 32
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$rng.GetBytes($bytes)
$rng.Dispose()
[BitConverter]::ToString($bytes).Replace('-', '').ToLowerInvariant()
```

No Linux/macOS com OpenSSL: `openssl rand -hex 32`.

Proteja o arquivo `.env` com permissoes de leitura apenas para operadores autorizados. No Linux/macOS: `chmod 600 .env`. Nao o versione nem compartilhe a saida de `docker compose config`, que pode conter senhas. Operadores com acesso ao Docker conseguem inspecionar as variaveis dos containers.

```sh
docker compose config --quiet
docker compose up -d
docker compose ps
docker compose logs -f keycloak
```

A primeira inicializacao pode demorar alguns minutos: `start` prepara a distribuicao automaticamente. Aguarde os dois servicos ficarem `healthy`. Abra http://localhost:8080/admin e use as credenciais do `.env`. Para aguardar a prontidao no terminal, use `docker compose up -d --wait --wait-timeout 300`.

O administrador de bootstrap e temporario. Crie um administrador permanente no realm master com as permissoes administrativas necessarias, configure MFA, valide o acesso e exclua o temporario. As variaveis de bootstrap so criam a conta na inicializacao de um banco novo; alterar sua senha no `.env` nao redefine uma conta existente. Depois disso, substitua a senha de bootstrap por um novo valor aleatorio e recrie o container para retirar o segredo inicial de seu ambiente.

## O que esta configurado

- PostgreSQL persistente em volume, sem porta publicada e em rede interna.
- Keycloak no modo `start`, hostname explicito e acesso publicado somente em 127.0.0.1.
- Verificacao do banco antes de iniciar Keycloak; prontidao pela porta interna 9000, que nao e publicada. Metricas habilitadas para incluir o estado do pool do banco.
- Reinicio apos encerramento inesperado. O estado `unhealthy` por si so nao reinicia um container.
- Cache local para uma unica instancia. Nao escale este arquivo para varias replicas sem configurar cluster.

O usuario POSTGRES_USER e o administrador do banco criado pela imagem PostgreSQL. Para este deploy simplificado ele e exclusivo do Keycloak; nao compartilhe esse banco com outras aplicacoes. Ambientes com separacao de privilegios devem provisionar um usuario de aplicacao separado, com permissoes para migrar o schema do Keycloak.

## Publicar com HTTPS

O padrao HTTP e restrito ao computador local. Para acesso remoto, use um dominio e um proxy reverso com certificado TLS valido no mesmo host (por exemplo Nginx ou Caddy). O proxy e o certificado precisam ser provisionados separadamente.

1. Configure DNS e HTTPS no proxy para seu dominio.
2. No `.env`, defina `KC_HOSTNAME=https://login.seudominio.com` e `KC_PROXY_HEADERS=xforwarded`.
3. Encaminhe o proxy para `http://127.0.0.1:8080`. Ele deve sobrescrever X-Forwarded-For, X-Forwarded-Proto e X-Forwarded-Host com os valores corretos. Nao aceite esses cabecalhos diretamente do cliente.
4. Execute `docker compose up -d` e teste login e redirecionamentos pela URL HTTPS.

Mantenha a publicacao em 127.0.0.1 e a porta 9000 fechada. Se o proxy estiver em outro container, 127.0.0.1 apontara para o proprio proxy: conecte-o a rede frontend e use `http://keycloak:8080`, restringindo quais containers podem participar dessa rede. Nao exponha 8080 diretamente na Internet. Restrinja o acesso administrativo no proxy/firewall, configure MFA e ajuste os realms para exigir SSL em acessos externos. Esta stack nao oferece alta disponibilidade.

## Operacao e dados

```sh
docker compose stop
docker compose start
docker compose down
```

`down` preserva o volume. **`docker compose down -v` apaga os dados**, incluindo usuarios, realms e clientes. Mantenha o nome do projeto para reutilizar o mesmo volume.

Alterar POSTGRES_PASSWORD no `.env` nao muda a senha de um banco ja inicializado. Para rotacao, altere tambem a senha do papel PostgreSQL e recrie o Keycloak com a nova configuracao.

Backup sem redirecionar dados binarios pelo PowerShell:

```sh
docker compose exec -T postgres pg_dump -U keycloak -d keycloak -Fc -f /tmp/keycloak.dump
docker compose cp postgres:/tmp/keycloak.dump ./keycloak.dump
docker compose exec -T postgres rm /tmp/keycloak.dump
```

Armazene backups protegidos fora do host. Teste a restauracao em ambiente isolado. Para restaurar em um banco vazio desta stack, mantendo Keycloak parado:

```sh
docker compose stop keycloak
docker compose cp ./keycloak.dump postgres:/tmp/keycloak.dump
docker compose exec -T postgres pg_restore -U keycloak -d keycloak --no-owner --exit-on-error /tmp/keycloak.dump
docker compose exec -T postgres rm /tmp/keycloak.dump
docker compose start keycloak
```

O PostgreSQL precisa estar em execucao; nao restaure sobre um banco com tabelas existentes usando esse procedimento.

Antes de atualizar, faca backup e leia o guia de migracao. A tag do Keycloak fixa a versao; `postgres:17-bookworm` acompanha correcoes da serie 17. Para builds imutaveis, fixe ambas as imagens por digest apos valida-las. Nao altere a versao principal do PostgreSQL sobre o mesmo volume sem migracao. Atualizar a imagem nao executa rollback de schema.

## Referencias oficiais

- https://www.keycloak.org/documentation
- https://www.keycloak.org/server/containers
- https://www.keycloak.org/server/db
- https://www.keycloak.org/server/hostname
- https://www.keycloak.org/server/reverseproxy
- https://www.keycloak.org/observability/health
- https://www.keycloak.org/server/upgrading
