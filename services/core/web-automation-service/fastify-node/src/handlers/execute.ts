import { FastifyInstance } from 'fastify';
import { ExecuteTasksRequest } from '@/models/action.js';
import { executeTasks } from '@/engines/action.js';
import { PageState } from '@/models/page.js';

export async function executeTasksHandler(fastify: FastifyInstance) {
    fastify.get('/health', async () => ({
        status: 'ok',
        service: 'web automation service'
    }));

    fastify.post('/execute', async (request, reply) => {
        const parseResult = ExecuteTasksRequest.safeParse(request.body);

        if (!parseResult.success) {
            return reply.status(400).send({
                error: 'invalid request data',
                details: parseResult.error.format()
            });
        }

        reply.status(202).send({ accepted: true });

        try {
            const { tasks } = parseResult.data;

            const pageState: PageState = await executeTasks(tasks);

        } catch (error: unknown) {
            request.log.error({ error }, 'error while executing tasks');
        }
    });
}
