# Producao com PostgreSQL externo

Use `compose.yml` original junto de `compose.production.yml`. A sobreposicao desativa o PostgreSQL local no perfil padrao, remove essa dependencia do Keycloak e utiliza o banco existente. Nao substitua o banco nem inicie uma base vazia ao atualizar um ambiente ja migrado.

```sh
cp .env.production.example .env
chmod 600 .env
# Preencha as senhas e instale os certificados antes de iniciar.
docker compose -p keycloak-production -f compose.yml -f compose.production.yml config --quiet
docker compose -p keycloak-production -f compose.yml -f compose.production.yml up -d --wait --wait-timeout 600 keycloak
```

Prepare `tls/server.crt` e `tls/server.key` conforme o README original. O certificado deve incluir `10.0.0.193` no SAN. Em `certificates/postgres-root.crt`, instale apenas a CA publica do PostgreSQL. Nunca copie a chave privada do banco. A conexao JDBC usa `sslmode=verify-full`.

O nome do projeto permanece `keycloak-production` para substituir a instancia existente sem criar um segundo Keycloak conectado ao mesmo banco. A porta externa 8082 encaminha para HTTPS/8443. A administracao abre em `https://10.0.0.193:8082/admin/`, conforme `KC_HOSTNAME`. Nao ha `KC_HOSTNAME_ADMIN` separado nesta configuracao.

Para preservar o SSO publico do DSI Panel, configure a URL de frontend do realm `pindamonhangaba` como `https://sso.pindamonhangaba.sp.gov.br`. O realm `master` usa a URL canonica por IP e nao precisa de URL de frontend especial. O issuer institucional continua `https://sso.pindamonhangaba.sp.gov.br/realms/pindamonhangaba`; o banco e os identificadores dos usuarios permanecem os mesmos. O dominio publico ainda precisa de DNS e HTTPS no proxy para o login das aplicacoes.

O Nginx Proxy Manager existente encaminha por HTTPS para `10.0.0.193:8082`. Configure-o para confiar na CA do certificado desse upstream e verificar o nome contido no certificado. `KC_PROXY_TRUSTED_ADDRESSES` deve corresponder ao IP real do proxy, nao a qualquer origem.

A imagem e a configuracao principal seguem o Compose original. A sobreposicao limita recursos e reduz o pool para o servidor municipal de pouca memoria. Use `docker compose config --services` sem habilitar perfis para conferir que apenas `keycloak` sera iniciado; o perfil `local-database` nao e usado nesta producao.

Antes de trocar a configuracao, faca backup do PostgreSQL, guarde o ambiente privado e confirme que so uma instancia sera executada. Nao use `down -v`. Depois, verifique a console no navegador com login completo e confira separadamente o issuer do realm institucional. Certificados internos devem ter confianca manual nos clientes autorizados.
