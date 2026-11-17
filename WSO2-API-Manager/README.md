# WSO2 API Manager self-managed

Configuração inicial do API Manager 4.7.0 All-in-One, com Publisher e Developer Portal locais. O PostgreSQL fica em 10.0.0.4 e usa TLS com verificação do certificado.

1. Provisione os bancos wso2am_apim e wso2am_shared com usuários próprios. Aplique dbscripts/apimgt/postgresql.sql e dbscripts/postgresql.sql, respectivamente, extraídos da distribuição 4.7.0.
2. Coloque o driver JDBC PostgreSQL como postgresql.jar e a CA pública do banco como postgres-ca.crt nesta pasta.
3. Copie .env.example para .env e preencha as três senhas. Ajuste o hostname e o endereço de bind conforme o ambiente.
4. Execute docker compose up -d.

No servidor previsto, o Publisher fica em https://10.0.0.15:9443/publisher e o Developer Portal em https://10.0.0.15:9443/devportal. O tráfego das APIs usa a porta 8243.

Antes de uso em produção, configure os certificados institucionais do API Manager e valide o login no Publisher, a publicação de uma API e a chamada pela porta do gateway.

[Pré-requisitos do API Manager](https://apim.docs.wso2.com/en/4.7.0/install-and-setup/install/installation-prerequisites/)
