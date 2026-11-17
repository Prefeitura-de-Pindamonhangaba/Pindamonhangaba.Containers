# Coolify

Execute o Compose em um host Linux com Docker Engine, Docker Compose v2 e
OpenSSH. A stack usa a imagem oficial do Coolify, Redis local e PostgreSQL
externo. [Guia oficial de instalação](https://coolify.io/docs/start-with-self-hosted)

## Preparação inicial

1. No PostgreSQL, crie o banco `coolify` com um usuário dedicado como
   proprietário. Permita conexões do host Docker no firewall e no
   `pg_hba.conf`. O Coolify executa as migrações na inicialização.
2. Em `Coolify/`, execute `cp .env.example .env` e `chmod 600 .env`.
   Preencha `DB_PASSWORD` com a senha do PostgreSQL. Ajuste `DB_HOST`
   (padrão `10.0.0.4`), `DB_PORT`, `DB_DATABASE` e `DB_USERNAME` se necessário.
   Use aspas simples no `.env` para valores com caracteres de interpolação,
   como `$`.
3. Gere `APP_KEY` com `printf 'base64:'; openssl rand -base64 32`.
   Gere um valor independente para cada um dos outros campos vazios
   (`APP_ID`, `REDIS_PASSWORD` e os três campos `PUSHER_APP_*`) com
   `openssl rand -hex 32`. Preserve esses valores ao recriar os containers.
4. Prepare os diretórios persistentes no host. Se alterar `COOLIFY_DATA_DIR`,
   use o mesmo caminho aqui.

   ```bash
   sudo mkdir -p /data/coolify/{ssh/keys,ssh/mux,applications,databases,services,backups,images}
   sudo chown -R 9999:root /data/coolify/{ssh,applications,databases,services,backups,images}
   sudo chmod -R 700 /data/coolify/{ssh,images}
   ```

## Deploy

Na pasta `Coolify/`, execute:

```bash
docker compose up -d
```

Use `docker compose ps` para acompanhar o healthcheck e
`docker compose logs -f coolify` para inspecionar a inicialização.

Por padrão, as portas 8000, 6001 e 6002 ficam vinculadas ao loopback do
host. Para acessar de outra máquina durante a configuração inicial,
encaminhe as três portas por SSH:

```bash
ssh -N -L 8000:127.0.0.1:8000 -L 6001:127.0.0.1:6001 -L 6002:127.0.0.1:6002 usuario@host-docker
```

Abra `http://localhost:8000` e crie a conta de administrador.
`COOLIFY_BIND_IP` permite ajustar a interface de escuta. As portas 6001 e
6002 atendem aos WebSockets de tempo real e do terminal.

Para gerenciar o próprio host Docker, cadastre `host.docker.internal`
como servidor no painel e autorize a chave pública do Coolify no
`authorized_keys` do usuário SSH desse host. Para gerenciar outro servidor,
cadastre o endereço e autorize a chave nesse servidor.

Gerencie as atualizações pelo Compose. Desative a atualização automática
no painel e, após revisar a versão de destino e fazer backup do PostgreSQL,
do diretório de dados e do `.env`, ajuste `COOLIFY_VERSION` e execute
`docker compose up -d` novamente.
