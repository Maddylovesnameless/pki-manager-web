import { migrate } from 'drizzle-orm/better-sqlite3/migrator';
import { db, sqliteDb } from './client.js';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const migrationsFolder = join(__dirname, 'migrations');

console.log('Running migrations...');
console.log('Migrations folder:', migrationsFolder);

try {
  migrate(db, { migrationsFolder });
  console.log('Migrations completed successfully!');
} catch (error) {
  console.error('Migration failed:', error);
  process.exit(1);
} finally {
  sqliteDb.close();
}
