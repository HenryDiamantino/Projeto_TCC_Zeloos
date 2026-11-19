const fs = require('fs');
const mysql = require('mysql2/promise');
const {
  DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME, DB_SSL_CA, DB_SSL_CA_FILE,
} = require('./env');

const sslCa = DB_SSL_CA || (DB_SSL_CA_FILE && fs.readFileSync(DB_SSL_CA_FILE, 'utf8'));

const pool = mysql.createPool({
  host: DB_HOST,
  port: DB_PORT,
  user: DB_USER,
  password: DB_PASSWORD,
  database: DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  timezone: 'Z',
  ...(sslCa && { ssl: { ca: sslCa } }),
});

module.exports = pool;
