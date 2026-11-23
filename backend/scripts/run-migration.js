require('dotenv').config({ path: require('path').resolve(__dirname, '../.env') });
const fs = require('fs');
const path = require('path');
const pool = require('../db');

async function run() {
  const file = process.argv[2];
  if (!file) {
    console.error('Please specify migration file path');
    process.exit(1);
  }
  const fullPath = path.resolve(process.cwd(), file);
  console.log('Running migration:', fullPath);
  const sql = fs.readFileSync(fullPath, 'utf8');
  await pool.query(sql);
  console.log('Migration succeeded!');
  await pool.end();
}

run().catch(err => {
  console.error('Migration failed:', err);
  process.exit(1);
});
