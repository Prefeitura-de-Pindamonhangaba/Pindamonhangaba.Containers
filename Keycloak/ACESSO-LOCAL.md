# Acesso inicial na rede da Prefeitura

Configurado em 28/10/2026.

- Administracao: https://10.0.0.16:8081/admin/master/console/
- Conta de teste: https://10.0.0.16:8081/realms/pindamonhangaba/account/
- Realm de aplicacoes: `pindamonhangaba`.
- Administrador permanente: `admin.prefeitura`, no realm `master`, com troca obrigatoria de senha no primeiro acesso.
- Usuario comum: `usuario.teste`, no realm `pindamonhangaba`, com papel `usuario`, sem acesso administrativo.
- As senhas iniciais estao em `.local/acesso-inicial.json`, com permissao 600. Nao versionar ou compartilhar esse arquivo.

O acesso passou de HTTP para **HTTPS**, mantendo a porta 8081. O certificado local tem o IP 10.0.0.16 no SAN e validade de um ano. Para evitar avisos nos navegadores, distribua apenas `tls/server.crt` para os computadores autorizados e importe-o no repositorio de autoridades confiaveis. Nunca distribua `tls/server.key`.

No Windows, depois de copiar o certificado publico para o computador, importe-o para o usuario atual com:

```powershell
certutil -user -addstore Root .\server.crt
```

Feche e reabra o navegador e use a URL com `https://`. Para distribuir para todos os computadores, a equipe de rede pode instalar o certificado por GPO. Substitua o certificado por um emitido pela autoridade interna quando disponivel e renove-o antes do vencimento.

O Docker publica somente `10.0.0.16:8081`, encaminhando para HTTPS/8443 do Keycloak. O HTTP/8080 continua apenas dentro do container. A verificacao de saude usa HTTP/9000 interno.

O servico `keycloak-rede-interna.service` aplica uma regra em `DOCKER-USER` que bloqueia o acesso encaminhado a essa publicacao quando a origem esta fora de `10.0.0.0/23`, conforme a mascara da interface do servidor. A regra e reaplicada quando o Docker inicia. Redes que chegam por NAT dependem tambem das restricoes no roteador; a regra considera a origem recebida pelo servidor.

O cadastro publico e a recuperacao por e-mail estao desativados. Os e-mails das duas contas sao placeholders sob `example.invalid`; substitua-os pelos enderecos reais antes de configurar SMTP. O realm usa portugues do Brasil, senhas de no minimo 12 caracteres e protecao contra tentativas repetidas. O DadosPinda usa o cliente `PindaDados` no realm `pindamonhangaba`; as contas foram vinculadas explicitamente e os papeis de acesso sao mantidos na aplicacao.

Uma integracao LDAP no realm `master` estava habilitada com `usersDn=systeste`, um DN invalido que impedia a criacao de usuarios. Ela foi desabilitada, preservando os dados; a representacao anterior esta em `.local/ldap-master-anterior.json`. Para integrar o AD, configurar o DN correto, endereco do servidor e conta de consulta, preferencialmente no realm `pindamonhangaba`.

O administrador de bootstrap `admin` foi desativado depois de validar o administrador permanente. As credenciais de bootstrap do `.env` nao sao as credenciais do novo administrador.

Validacao realizada: saude dos dois containers, certificado/SAN, login OIDC com PKCE do usuario de teste, troca de codigo por tokens, identidade, rejeicao do acesso administrativo e logout. As credenciais do administrador foram validadas e o fluxo apresentou a troca obrigatoria de senha. A validacao HTTP/OIDC foi executada no servidor; o acesso a partir do computador do operador depende da rota de rede e da confianca no certificado.

O tema de login generico `pindamonhangaba` esta ativo no realm de aplicacoes. Mantem brasao, cores e estrutura institucionais, sem referencias ao DadosPinda na tela. As fontes e instrucoes de ativacao estao em `themes/pindamonhangaba/`.
