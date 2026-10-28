# Keycloak com PostgreSQL e HTTPS

Stack de uma instancia, com Keycloak 26.8.1, PostgreSQL 17, HTTPS nativo e tema institucional generico. Requer Docker Engine em Linux e Docker Compose. O banco usa volume persistente e nao publica porta no host.

## Preparar

```sh
cp .env.example .env
chmod 600 .env
```

Preencha `POSTGRES_PASSWORD` e `KC_BOOTSTRAP_ADMIN_PASSWORD` com senhas diferentes e aleatorias. O administrador de bootstrap so e criado na inicializacao de um banco novo; alterar o `.env` nao redefine senhas existentes.

Configure `KC_HOSTNAME` com a URL HTTPS exata usada no navegador, incluindo a porta. `KC_BIND_ADDRESS` define o IP de publicacao e usa `127.0.0.1` por padrao. Para acesso pela rede municipal desta instalacao:

```env
KC_HOSTNAME=https://10.0.0.16:8081
KC_BIND_ADDRESS=10.0.0.16
KC_HTTP_PORT=8081
```

`KC_HTTP_PORT` e o nome historico da porta externa; agora publica HTTPS/8443. HTTP/8080 e a verificacao de saude HTTP/9000 permanecem internos.

## Certificado TLS

Coloque o certificado em `tls/server.crt` e a chave privada correspondente em `tls/server.key`. Use um certificado com SAN correspondente ao IP ou dominio configurado. Os arquivos sao ignorados pelo Git e montados somente para leitura. Em Linux, permita leitura pelo UID 1000 do Keycloak:

```sh
chown -R 1000:0 tls
chmod 750 tls
chmod 640 tls/server.key
chmod 644 tls/server.crt
```

Prefira certificado emitido pela autoridade interna da organizacao. Para homologacao local em localhost, um certificado autoassinado pode ser criado com:

```sh
mkdir -p tls
openssl req -x509 -newkey rsa:3072 -sha256 -nodes -days 365 \
  -keyout tls/server.key -out tls/server.crt \
  -subj '/CN=localhost' \
  -addext 'subjectAltName=DNS:localhost,IP:127.0.0.1'
```

Ao utilizar IP de rede, adapte o SAN e o CN para esse IP. Distribua apenas o certificado publico aos computadores autorizados e configure a confianca no navegador. Nunca compartilhe a chave privada. O arquivo [ACESSO-LOCAL.md](ACESSO-LOCAL.md) documenta a instalacao da Prefeitura.

## Iniciar

```sh
docker compose config --quiet
docker compose up -d --wait --wait-timeout 300
docker compose ps
```

Abra a URL configurada seguida de `/admin/`. A primeira inicializacao prepara a distribuicao e pode demorar alguns minutos. Nao compartilhe a saida de `docker compose config` sem `--quiet`, pois pode conter senhas.

Depois do primeiro acesso, crie e valide um administrador permanente antes de desativar o bootstrap. Configure MFA e privilegios conforme a politica da organizacao. Senhas e estado administrativo nao sao versionados.

## Tema institucional

O diretorio `themes` e montado em `/opt/keycloak/themes`. Para ativar, selecione o realm da aplicacao e abra **Realm settings > Themes > Login theme > pindamonhangaba**. O tema usa identidade generica da Prefeitura, sem referencias a um sistema especifico. Consulte [o guia do tema](themes/pindamonhangaba/README.md).

O tema do realm `master` e mantido separadamente. O cache permanece habilitado; ao editar templates ou propriedades, reinicie o Keycloak para recarregar o tema.

## Rede desta instalacao

Os modelos em `deploy/rede-interna/` preservam o servico systemd e a regra de firewall aplicados neste servidor. Eles sao especificos para `10.0.0.16:8081` e a rede `10.0.0.0/23`; revise-os antes de utilizar em outra rede. O script permite tambem a comunicacao da rede Docker do DadosPinda com o Keycloak. A instalacao manual, como root, usa:

```sh
install -m 755 deploy/rede-interna/keycloak-rede-interna /usr/local/sbin/
install -m 644 deploy/rede-interna/keycloak-rede-interna.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now keycloak-rede-interna.service
```

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
