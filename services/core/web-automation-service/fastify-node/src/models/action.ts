import { z } from 'zod';

export const GOTO_ACTION = 'goto';
export const CLICK_ACTION = 'click';
export const SELECT_ACTION = 'select';
export const FILL_ACTION = 'fill';
export const VERIFY_ACTION = 'verify';
export const WAIT_UNTIL_VERIFIED_ACTION = 'wait-until-verified';
export const CUSTOM_ACTION = 'custom';

export type Action = {
    queue_reference: string;
    job_reference: string;
    task_reference: string;
    action_reference: string;
    action_description: string;
    action_type: 'goto';
    action_address: string;
} | {
    queue_reference: string;
    job_reference: string;
    task_reference: string;
    action_reference: string;
    action_description: string;
    action_type: 'click';
    action_selector: string;
} | {
    queue_reference: string;
    job_reference: string;
    task_reference: string;
    action_reference: string;
    action_description: string;
    action_type: 'select';
    action_selector: string;
    action_value: string;
} | {
    queue_reference: string;
    job_reference: string;
    task_reference: string;
    action_reference: string;
    action_description: string;
    action_type: 'fill';
    action_selector: string;
    action_value: string;
} | {
    queue_reference: string;
    job_reference: string;
    task_reference: string;
    action_reference: string;
    action_description: string;
    action_type: 'verify';
    action_selector?: string;
    action_value?: string;
    action_address?: string;
} | {
    queue_reference: string;
    job_reference: string;
    task_reference: string;
    action_reference: string;
    action_description: string;
    action_type: 'wait-until-verified';
    action_selector?: string;
    action_value?: string;
    action_address?: string;
    action_delay: number;
} | {
    queue_reference: string;
    job_reference: string;
    task_reference: string;
    action_reference: string;
    action_description: string;
    action_type: 'custom';
    action_address: string;
    action_script: string;
}

export const ActionSchema = z.discriminatedUnion('action', [
    z.object({
        queue_reference: z.string(),
        job_reference: z.string(),
        task_reference: z.string(),
        action_reference: z.string(),
        action_description: z.string(),
        action_type: z.literal(GOTO_ACTION),
        action_address: z.string(),
    }),
    z.object({
        queue_reference: z.string(),
        job_reference: z.string(),
        task_reference: z.string(),
        action_reference: z.string(),
        action_description: z.string(),
        action_type: z.literal(CLICK_ACTION),
        action_selector: z.string(),
    }),
    z.object({
        queue_reference: z.string(),
        job_reference: z.string(),
        task_reference: z.string(),
        action_reference: z.string(),
        action_description: z.string(),
        action_type: z.literal(SELECT_ACTION),
        action_selector: z.string(),
        action_value: z.string(),
    }),
    z.object({
        queue_reference: z.string(),
        job_reference: z.string(),
        task_reference: z.string(),
        action_reference: z.string(),
        action_description: z.string(),
        action_type: z.literal(FILL_ACTION),
        action_selector: z.string(),
        action_value: z.string(),
    }),
    z.object({
        queue_reference: z.string(),
        job_reference: z.string(),
        task_reference: z.string(),
        action_reference: z.string(),
        action_description: z.string(),
        action_type: z.literal(CUSTOM_ACTION),
        action_address: z.string(),
        action_script: z.string()
    }),
    z.object({
        queue_reference: z.string(),
        job_reference: z.string(),
        task_reference: z.string(),
        action_reference: z.string(),
        action_description: z.string(),
        action_type: z.literal(VERIFY_ACTION),
        action_selector: z.string().optional(),
        action_value: z.string().optional(),
        action_address: z.string().optional(),
    }),
    z.object({
        queue_reference: z.string(),
        job_reference: z.string(),
        task_reference: z.string(),
        action_reference: z.string(),
        action_description: z.string(),
        action_type: z.literal(WAIT_UNTIL_VERIFIED_ACTION),
        action_selector: z.string().optional(),
        action_value: z.string().optional(),
        action_address: z.string().optional(),
        action_delay: z.number().default(300),
    }),
]);

export const ExecuteTasksRequest = z.object({
    tasks: z.array(ActionSchema)
});
