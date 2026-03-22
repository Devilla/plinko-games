import db from '@repo/db';
import { createServer } from './server';

const port = process.env.PORT || 5001;
const app = createServer();

const server = app.listen(port);

const gracefulShutdown = async () => {
  server.close(async () => {
    await db.$disconnect();
    process.exit();
  });
};

process.on('SIGTERM', gracefulShutdown);
process.on('SIGINT', gracefulShutdown);
