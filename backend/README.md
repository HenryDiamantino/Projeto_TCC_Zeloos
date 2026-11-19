# Backend da Pulseira Localizadora

## Visão geral
Este backend foi desenvolvido em Node.js + Express para apoiar o sistema de pulseira localizadora infantil com autenticação JWT, CRUD de crianças, pulseiras, locais seguros, alertas e configurações.

## Estrutura
- src/app.js
- src/config/db.js
- src/config/env.js
- src/controllers/
- src/middlewares/authMiddleware.js
- src/repositories/
- src/routes/
- src/utils/geo.js
- src/validators/
- database/schema.sql
- database/seed.sql

## Instalação
1. Abra o terminal na pasta backend.
2. Copie o arquivo .env.example para .env.
3. Ajuste os valores de acesso ao MySQL.
4. Execute:

```bash
npm install
```

## Configuração do MySQL
1. Instale o MySQL localmente.
2. Crie um usuário e banco conforme o arquivo .env.
3. Execute o script SQL:

```bash
mysql -u seu_usuario -p < database/schema.sql
```

Opcionalmente, carregue dados de demonstração:

```bash
mysql -u seu_usuario -p < database/seed.sql
```

Se o banco foi criado antes da foto de perfil existir, adicione a coluna `foto_perfil` com:

```bash
mysql -u seu_usuario -p < database/migrations/001_foto_perfil_usuario.sql
```

O driver `mysql2` não oferece suporte ao plugin de autenticação `auth_gssapi_client`. Se a API retornar `AUTH_SWITCH_PLUGIN_ERROR`, configure uma conta exclusiva para o aplicativo com um plugin compatível, como `caching_sha2_password` no MySQL 8, e atualize `DB_USER` e `DB_PASSWORD` no `.env`:

```sql
CREATE USER 'pulseira_app'@'localhost' IDENTIFIED WITH caching_sha2_password BY 'troque-por-uma-senha-forte';
GRANT SELECT, INSERT, UPDATE, DELETE ON pulseira_localizadora.* TO 'pulseira_app'@'localhost';
```

Execute o `schema.sql` com uma conta administrativa antes de iniciar a API. Se o MySQL estiver em outro computador, restrinja o host da conta ao endereço de origem do backend em vez de usar `localhost`.

## Iniciar a API
```bash
npm run dev
```

No PowerShell do Windows, use o executável `.cmd` para evitar o bloqueio do
script `npm.ps1` pela política de execução:

```powershell
npm.cmd run dev
```

O endpoint `GET /api/health` verifica também a conexão com o banco; responde `503` quando o banco não está acessível.

## Endpoints principais
- POST /api/auth/register
- POST /api/auth/login
- GET /api/auth/me
- PUT /api/auth/me/foto
- DELETE /api/auth/me/foto
- GET /api/criancas
- POST /api/criancas
- GET /api/criancas/:id
- PUT /api/criancas/:id
- DELETE /api/criancas/:id
- GET /api/pulseiras
- POST /api/pulseiras
- GET /api/pulseiras/:id/localizacao-atual
- GET /api/pulseiras/:id/historico
- POST /api/pulseiras/receber-localizacao
- GET /api/alertas
- PATCH /api/alertas/:id/visualizar
- PATCH /api/alertas/:id/resolver

## Foto de perfil
A foto do responsável fica na coluna `usuarios.foto_perfil` como Data URL base64 e é devolvida em `GET /api/auth/me`. Para enviar, use `PUT /api/auth/me/foto` com uma imagem PNG, JPEG ou WEBP de até 512 KB:

```json
{
  "foto_perfil": "data:image/png;base64,iVBORw0KGgo..."
}
```

A API confere o tipo real do arquivo pelos primeiros bytes, e não só pelo prefixo. `DELETE /api/auth/me/foto` remove a foto e o app volta a mostrar a inicial do nome.

## Localização da pulseira
O app atualiza a tela do mapa a cada 15 segundos e mostra a última localização recebida pela API. O dispositivo deve enviar posições reais para `POST /api/pulseiras/receber-localizacao`, usando o identificador cadastrado:

```json
{
  "identificador": "BRACELET-001",
  "latitude": -23.55052,
  "longitude": -46.63331,
  "bateria_percentual": 82
}
```

Sem um dispositivo enviando coordenadas, o mapa informa que ainda não recebeu localização; ele não simula movimento.
O mapa usa tiles do OpenStreetMap durante o desenvolvimento. Para uso em produção, configure um provedor de tiles que atenda aos termos e limites de uso do serviço escolhido.

## Banco na nuvem com SSL (Aiven)
Bancos como o da Aiven exigem conexão SSL. Baixe o **CA certificate** do serviço e informe o certificado à API de uma destas formas:

- Localmente: salve como `ca.pem` na pasta `backend` e defina `DB_SSL_CA_FILE=ca.pem` no `.env`.
- Na Vercel: cole o conteúdo inteiro do `ca.pem` na variável `DB_SSL_CA`.

Sem nenhuma das duas, a conexão é feita sem SSL, como no MySQL/MariaDB local. O `*.pem` está no `.gitignore`.

## Deploy na Vercel
O arquivo `api/index.js` expõe o app Express como função serverless, e o `vercel.json` encaminha todas as rotas para ela.

1. Na Vercel, importe o repositório e defina **Root Directory** como `backend`.
2. Em **Settings > Environment Variables**, configure `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`, `DB_SSL_CA`, `JWT_SECRET` (um segredo novo e forte) e `CORS_ORIGIN` (o endereço do app web, por exemplo `https://zeloos.vercel.app`).
3. Faça o deploy e teste `https://<seu-backend>.vercel.app/api/health`.

Na Vercel, `NODE_ENV` é `production`, então o CORS só aceita as origens listadas em `CORS_ORIGIN`.

## Documentação da API (Swagger)
Com a API rodando, acesse:

- Interface interativa: http://localhost:3005/api-docs
- Especificação OpenAPI (JSON): http://localhost:3005/api-docs.json

A especificação fica em `src/docs/swagger.js`. Para testar rotas protegidas pela interface, chame `POST /api/auth/login`, copie o `token` da resposta, clique em **Authorize** e cole apenas o token. Ao criar ou alterar uma rota, documente-a também em `src/docs/swagger.js` — o teste `tests/swagger.test.js` falha se alguma rota da API não estiver documentada.

## Autenticação
O token deve ser enviado no header:

```http
Authorization: Bearer <token>
```

## Modo de demonstração
O endpoint de recepção de geolocalização foi organizado para aceitar dados simulados com o campo `origem` e pode ser usado em ambiente de prova sem hardware real.

## Testes
```bash
npm test
```

No PowerShell, use `npm.cmd test`. Os testes não precisam do MySQL: o banco e os repositórios são substituídos por mocks do Jest.

- `tests/unit/`: testes unitários de utilitários (`geo`), middleware de autenticação, validadores, controllers e repositório de pulseiras.
- `tests/auth.test.js` e `tests/pulseira.test.js`: testes das rotas HTTP com `supertest`.
- `tests/swagger.test.js`: garante que o Swagger está disponível e que todas as rotas estão documentadas.

Para gerar o relatório de cobertura:

```bash
npx jest --coverage
```

## Importante
O backend não deve expor segredos em produção, e não deve misturar dados reais com dados simulados sem marcação explícita.
