# Login institucional Pindamonhangaba

Tema generico de autenticacao da Prefeitura, inspirado no conceito visual do DadosPinda, com brasao, tokens de cores, tipografia e proporcoes institucionais. A tela nao possui nome, links ou textos de uma aplicacao especifica. Os assets foram reutilizados do repositorio local `Pindamonhangaba.DadosPinda`.

O tema herda `keycloak.v2`. O `template.ftl` adapta o layout compartilhado da versao 26.8.1, preservando os formularios, mensagens, scripts de sessao, passkeys, visibilidade de senha e etapas adicionais nativas. Ao atualizar o Keycloak, comparar esse template com a nova versao e validar novamente os fluxos de autenticacao.

O Compose monta `./themes` em `/opt/keycloak/themes`, somente para leitura, com contexto SELinux. A ativacao fica no realm `pindamonhangaba`, em **Realm settings > Themes > Login theme > pindamonhangaba**. O realm `master` permanece com o tema administrativo original.

Arquivos principais:

- `login/template.ftl`: cabecalho, painel institucional, layout e rodape.
- `login/resources/css/tokens.css`: copia dos tokens do DadosPinda.
- `login/resources/css/pinda.css`: estilos responsivos do tema.
- `login/resources/img/prefeitura-pindamonhangaba.svg`: brasao institucional.
- `login/messages/`: textos do formulario.
- `login/theme.properties`: heranca, estilos e endereco do sistema.

O tema nao possui link fixo de retorno para uma aplicacao e nao carrega imagens ou fontes de servicos externos.

O cache de temas permanece habilitado. Para disponibilizar alteracoes em templates ou propriedades ja carregados, reiniciar o servico Keycloak e recarregar o navegador. Para reverter, selecionar `keycloak.v2` no campo Login theme; o arquivo `.local/theme-before.json` registra a selecao anterior.

Referencia: https://www.keycloak.org/ui-customization/themes
