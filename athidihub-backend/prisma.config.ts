import { defineConfig } from 'prisma/config';
import 'dotenv/config'; // Make sure process.env is populated from .env

export default defineConfig({
  schema: './prisma/schema.prisma',
  datasource: {
    url: process.env.DIRECT_URL || process.env.DATABASE_URL,
  },
});
