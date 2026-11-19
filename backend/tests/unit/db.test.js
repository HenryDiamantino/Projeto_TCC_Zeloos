const fs = require('fs');
const os = require('os');
const path = require('path');

function criarPool(env) {
  let createPool;
  jest.isolateModules(() => {
    jest.doMock('mysql2/promise', () => ({ createPool: jest.fn(() => ({})) }));
    jest.doMock('../../src/config/env', () => ({ DB_HOST: 'db.exemplo.com', ...env }));
    require('../../src/config/db');
    ({ createPool } = require('mysql2/promise'));
  });
  return createPool.mock.calls[0][0];
}

describe('config/db', () => {
  test('não usa SSL quando nenhum certificado é configurado', () => {
    expect(criarPool({}).ssl).toBeUndefined();
  });

  test('usa o certificado informado em DB_SSL_CA', () => {
    expect(criarPool({ DB_SSL_CA: 'CERTIFICADO' }).ssl).toEqual({ ca: 'CERTIFICADO' });
  });

  test('lê o certificado do arquivo em DB_SSL_CA_FILE', () => {
    const arquivo = path.join(fs.mkdtempSync(path.join(os.tmpdir(), 'zeloos-')), 'ca.pem');
    fs.writeFileSync(arquivo, 'CERTIFICADO DO ARQUIVO');

    expect(criarPool({ DB_SSL_CA_FILE: arquivo }).ssl).toEqual({ ca: 'CERTIFICADO DO ARQUIVO' });
  });
});
