# WSO2 API Platform Gateway

Gateway self-hosted **v1.2.0**, gerenciado pelo plano de controle do WSO2 API Platform Cloud.

## Deploy

1. No console da WSO2, cadastre um **Self-Hosted Gateway** do tipo **API Gateway**, versão **v1.2**, e copie o token do Quick Start. Cadastre a URL pela qual os clientes acessarão o gateway.
2. Nesta pasta, copie `.env.example` para `.env`. Preencha `WSO2_CONTROLPLANE_TOKEN` e `WSO2_ADMIN_PASSWORD_HASH`. O usuário da API administrativa é `admin`. Para gerar o hash bcrypt de uma senha com prompt interativo, use `htpasswd -nB admin` e copie apenas o texto após `admin:`, entre aspas simples no `.env`.
3. Suba a stack.

   ```sh
   docker compose up -d
   ```

Na primeira execução, o serviço `gateway-init` gera um certificado autoassinado para localhost e uma chave AES de 256 bits. Preserve os volumes `listener_certs` e `encryption_keys` ao recriar os containers. A chave AES é necessária para ler dados criptografados, inclusive quando o banco é externo.

Por padrão, a API administrativa fica em `127.0.0.1:9094` e o tráfego das APIs em `127.0.0.1:8081` (HTTP) e `127.0.0.1:8443` (HTTPS). Para publicação em produção, use a URL HTTPS do proxy reverso no console da WSO2, com um certificado válido no proxy. Se o proxy estiver fora do host, ajuste `WSO2_BIND_ADDRESS` para a interface que ele alcança.

```sh
docker compose ps -a
curl http://127.0.0.1:9094/api/admin/v1/health
docker compose logs gateway-controller gateway-runtime
```

O `gateway-init` deve terminar com código 0, e o gateway deve aparecer como **Active** no console. O controller precisa de saída HTTPS para o plano de controle. [Guia oficial do gateway self-hosted](https://wso2.com/api-platform/docs/cloud/api-platform-gateway/getting-started/).

## PostgreSQL externo

A configuração padrão usa SQLite no volume `controller_data`. Para produção com PostgreSQL:

1. Provisione o banco e o usuário de aplicação. Aplique o schema `resources/gateway-controller/db-scripts/gateway-controller-db.postgres.sql` do pacote **v1.2.0** e conceda ao usuário os privilégios descritos no guia. [Release v1.2.0](https://github.com/wso2/api-platform/releases/tag/gateway/v1.2.0) · [Guia de preparação do banco](https://wso2.com/api-platform/docs/api-gateway/next/setup/database-setup/).
2. No `.env`, defina `WSO2_STORAGE_TYPE=postgres` e preencha host, porta, nome do banco, usuário e senha. Use um hostname acessível pelo container. Com `WSO2_POSTGRES_SSLMODE=verify-full`, o certificado do servidor precisa ser confiável para o container e corresponder ao hostname.
3. Rode `docker compose up -d`. O Compose usa o PostgreSQL já provisionado. A troca de backend não migra o conteúdo do SQLite.
