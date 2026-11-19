# AGENTS.md

## Backend (`backend/`)
- Instalar: `npm install`
- Testes: `npm test` (Jest + Supertest, o MySQL é substituído por mocks).
  - Sem `.env`, `CORS_ORIGIN` vira `*` e o teste "CORS should not allow unconfigured external origins" falha. Copie `.env.example` para `.env` ou rode com `CORS_ORIGIN=http://localhost:3001`.
- Toda rota nova precisa estar em `src/docs/swagger.js` (`tests/swagger.test.js` falha se faltar).
- Mudança no banco: atualize `database/schema.sql` e crie um script em `database/migrations/` para bancos já existentes.

## App Flutter (`flutter_app/`)
- Testes: `flutter test`
- Análise estática: `flutter analyze` (deve ficar sem avisos).
- O código existente não segue 100% o `dart format`; formate só as linhas que você alterar.
