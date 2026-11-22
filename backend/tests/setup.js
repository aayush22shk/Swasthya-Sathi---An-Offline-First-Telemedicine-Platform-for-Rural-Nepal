/**
 * tests/setup.js
 * Jest environment setup: loads environment variables for all unit & integration tests.
 */
'use strict';

const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });

// Guarantee essential variables even if .env is missing or in CI
process.env.JWT_SECRET = process.env.JWT_SECRET || 'swasthyasathi_super_secret_key_change_in_production';
process.env.JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '24h';
process.env.PORT = process.env.PORT || '5000';
process.env.NODE_ENV = 'test';
