import { z } from 'zod';

export const GOTO_ACTION = 'goto';
export const CLICK_ACTION = 'click';
export const SELECT_ACTION = 'select';
export const FILL_ACTION = 'fill';
export const VERIFY_ACTION = 'verify';
export const WAIT_UNTIL_VERIFIED_ACTION = 'wait-until-verified';
export const CUSTOM_ACTION = 'custom';

export type Action = {
    task_reference: string;
    task_description: string;
    action: 'goto';
    address: string;
} | {
    task_reference: string;
    task_description: string;
    action: 'click';
    selector: string;
} | {
    task_reference: string;
    task_description: string;
    action: 'select';
    selector: string;
    value: string;
} | {
    task_reference: string;
    task_description: string;
    action: 'fill';
    selector: string;
    value: string;
} | {
    task_reference: string;
    task_description: string;
    action: 'verify';
    selector: string;
    value: string;
    address: string;
} | {
    task_reference: string;
    task_description: string;
    action: 'wait-until-verified';
    selector: string;
    value: string;
    address: string;
    delay: number;
} | {
    task_reference: string;
    task_description: string;
    action: 'custom';
    address: string;
    script: string;
    delay: number;
}

export const ActionSchema = z.discriminatedUnion('action', [
    z.object({
        task_reference: z.string(),
        task_description: z.string(),
        action: z.literal(GOTO_ACTION),
        address: z.string(),
    }),
    z.object({
        task_reference: z.string(),
        task_description: z.string(),
        action: z.literal(CLICK_ACTION),
        selector: z.string(),
    }),
    z.object({
        task_reference: z.string(),
        task_description: z.string(),
        action: z.literal(SELECT_ACTION),
        selector: z.string(),
        value: z.string(),
    }),
    z.object({
        task_reference: z.string(),
        task_description: z.string(),
        action: z.literal(FILL_ACTION),
        selector: z.string(),
        value: z.string(),
    }),
    z.object({
        task_reference: z.string(),
        task_description: z.string(),
        action: z.literal(VERIFY_ACTION),
        selector: z.string(),
        value: z.string(),
        address: z.string(),
    }),
    z.object({
        task_reference: z.string(),
        task_description: z.string(),
        action: z.literal(WAIT_UNTIL_VERIFIED_ACTION),
        selector: z.string(),
        value: z.string(),
        address: z.string(),
        delay: z.number().default(0),
    }),
    z.object({
        task_reference: z.string(),
        task_description: z.string(),
        action: z.literal(CUSTOM_ACTION),
        address: z.string(),
        script: z.string(),
        delay: z.number().default(0),
    }),
]);

export const ExecuteTasksRequest = z.object({
    tasks: z.array(ActionSchema)
});
