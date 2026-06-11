const express = require('express');
const { Pool } = require('pg');
const path = require('path');

const {
  DB_HOST,
  DB_PORT = '5432',
  DB_NAME,
  DB_USER,
  DB_PASSWORD,
  NODE_ENV = 'development',
  PORT = 3000,
} = process.env;

const pool = new Pool({
  host: DB_HOST,
  port: parseInt(DB_PORT),
  database: DB_NAME,
  user: DB_USER,
  password: DB_PASSWORD,
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});

const app = express();
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'templates'));

async function initDatabase() {
  try {
    const client = await pool.connect();
    await client.query(`
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        email VARCHAR(100) UNIQUE NOT NULL,
        created_at TIMESTAMP DEFAULT NOW()
      )
    `);
    console.log('✅ Tabela users pronta');
    client.release();
  } catch (err) {
    console.error('❌ Erro ao init banco:', err.message);
  }
}

app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ status: 'healthy', db: 'connected' });
  } catch (err) {
    res.status(503).json({ status: 'unhealthy', db: 'disconnected' });
  }
});

app.get('/', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM users ORDER BY created_at DESC');
    res.render('index', {
      users: result.rows,
      dbConnected: true,
      dbHost: DB_HOST,
      dbName: DB_NAME,
    });
  } catch (err) {
    res.render('index', {
      users: [],
      dbConnected: false,
      dbHost: DB_HOST,
      dbName: DB_NAME,
    });
  }
});

app.get('/api/users', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM users ORDER BY created_at DESC');
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/users', async (req, res) => {
  const { name, email } = req.body;
  if (!name || !email) {
    return res.status(400).json({ error: 'name e email obrigatorios' });
  }
  try {
    const result = await pool.query(
      'INSERT INTO users (name, email) VALUES ($1, $2) RETURNING *',
      [name, email]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    if (err.code === '23505') return res.status(409).json({ error: 'Email ja cadastrado' });
    res.status(500).json({ error: err.message });
  }
});

app.delete('/api/users/:id', async (req, res) => {
  try {
    const result = await pool.query('DELETE FROM users WHERE id = $1 RETURNING *', [req.params.id]);
    if (result.rows.length === 0) return res.status(404).json({ error: 'Usuario nao encontrado' });
    res.json({ message: 'Deletado' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/users/:id/delete', async (req, res) => {
  try {
    await pool.query('DELETE FROM users WHERE id = $1', [req.params.id]);
    res.redirect('/');
  } catch (err) {
    res.redirect('/');
  }
});

app.post('/users', async (req, res) => {
  try {
    await pool.query('INSERT INTO users (name, email) VALUES ($1, $2)', [req.body.name, req.body.email]);
    res.redirect('/');
  } catch (err) {
    res.redirect('/');
  }
});

async function start() {
  await initDatabase();
  app.listen(PORT, () => {
    console.log(`🚀 App RDS rodando na porta ${PORT}`);
    console.log(`📦 DB: ${DB_NAME}@${DB_HOST}`);
  });
}

start().catch(console.error);
