import { z } from 'zod';

export const GOTO_ACTION = 'goto';
export const CLICK_ACTION = 'click';
export const SELECT_ACTION = 'select';
export const FILL_ACTION = 'fill';
export const VERIFY_ACTION = 'verify';
export const WAIT_UNTIL_VERIFIED_ACTION = 'wait-until-verified';
export const CUSTOM_ACTION = 'custom';

export type Action = {
    session_reference: string;
    queue_reference: string;
    job_reference: string;
    task_reference: string;
    action_reference: string;
    action_description: string;
    action_flow: 'goto';
    action_address: string;
} | {
    session_reference: string;
    queue_reference: string;
    job_reference: string;
    task_reference: string;
    action_reference: string;
    action_description: string;
    action_flow: 'click';
    action_selector: string;
} | {
    session_reference: string;
    queue_reference: string;
    job_reference: string;
    task_reference: string;
    action_reference: string;
    action_description: string;
    action_flow: 'select';
    action_selector: string;
    action_value: string;
} | {
    session_reference: string;
    queue_reference: string;
    job_reference: string;
    task_reference: string;
    action_reference: string;
    action_description: string;
    action_flow: 'fill';
    action_selector: string;
    action_value: string;
} | {
    session_reference: string;
    queue_reference: string;
    job_reference: string;
    task_reference: string;
    action_reference: string;
    action_description: string;
    action_flow: 'verify';
    action_selector?: string;
    action_value?: string;
    action_address?: string;
} | {
    session_reference: string;
    queue_reference: string;
    job_reference: string;
    task_reference: string;
    action_reference: string;
    action_description: string;
    action_flow: 'wait-until-verified';
    action_selector?: string;
    action_value?: string;
    action_address?: string;
    action_delay: number;
} | {
    session_reference: string;
    queue_reference: string;
    job_reference: string;
    task_reference: string;
    action_reference: string;
    action_description: string;
    action_flow: 'custom';
    action_address: string;
    action_script: string;
}

export const ActionSchema = z.discriminatedUnion('action', [
    z.object({
        session_reference: z.string(),
        queue_reference: z.string(),
        job_reference: z.string(),
        task_reference: z.string(),
        action_reference: z.string(),
        action_description: z.string(),
        action_flow: z.literal(GOTO_ACTION),
        action_address: z.string(),
    }),
    z.object({
        session_reference: z.string(),
        queue_reference: z.string(),
        job_reference: z.string(),
        task_reference: z.string(),
        action_reference: z.string(),
        action_description: z.string(),
        action_flow: z.literal(CLICK_ACTION),
        action_selector: z.string(),
    }),
    z.object({
        session_reference: z.string(),
        queue_reference: z.string(),
        job_reference: z.string(),
        task_reference: z.string(),
        action_reference: z.string(),
        action_description: z.string(),
        action_flow: z.literal(SELECT_ACTION),
        action_selector: z.string(),
        action_value: z.string(),
    }),
    z.object({
        session_reference: z.string(),
        queue_reference: z.string(),
        job_reference: z.string(),
        task_reference: z.string(),
        action_reference: z.string(),
        action_description: z.string(),
        action_flow: z.literal(FILL_ACTION),
        action_selector: z.string(),
        action_value: z.string(),
    }),
    z.object({
        session_reference: z.string(),
        queue_reference: z.string(),
        job_reference: z.string(),
        task_reference: z.string(),
        action_reference: z.string(),
        action_description: z.string(),
        action_flow: z.literal(CUSTOM_ACTION),
        action_address: z.string(),
        action_script: z.string()
    }),
    z.object({
        session_reference: z.string(),
        queue_reference: z.string(),
        job_reference: z.string(),
        task_reference: z.string(),
        action_reference: z.string(),
        action_description: z.string(),
        action_flow: z.literal(VERIFY_ACTION),
        action_selector: z.string().optional(),
        action_value: z.string().optional(),
        action_address: z.string().optional(),
    }),
    z.object({
        session_reference: z.string(),
        queue_reference: z.string(),
        job_reference: z.string(),
        task_reference: z.string(),
        action_reference: z.string(),
        action_description: z.string(),
        action_flow: z.literal(WAIT_UNTIL_VERIFIED_ACTION),
        action_selector: z.string().optional(),
        action_value: z.string().optional(),
        action_address: z.string().optional(),
        action_delay: z.number().default(300),
    }),
]);

export const ExecuteTasksRequest = z.object({
    tasks: z.array(ActionSchema)
});
