import Fastify from 'fastify';
import { executeTasksHandler } from '@/handlers/execute.js';

const fastify = Fastify({
  logger: true
});

fastify.register(executeTasksHandler, { prefix: '/service/automation/web/tasks' });

const start = async () => {
  try {
    const WEB_AUTOMATION_SERVICE_PORT = process.env.WEB_AUTOMATION_SERVICE_PORT
        ? Number(process.env.WEB_AUTOMATION_SERVICE_PORT)
        : 4070

    await fastify.listen({ port: WEB_AUTOMATION_SERVICE_PORT, host: '0.0.0.0' });

    console.log(`[ACTIVE] WEB_AUTOMATION_SERVICE:${WEB_AUTOMATION_SERVICE_PORT}`);

  } catch (error: unknown) {
    fastify.log.error(error);

    process.exit(1);
  }
};

start();
