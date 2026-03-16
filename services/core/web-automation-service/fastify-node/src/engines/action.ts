import { chromium } from 'playwright';
import type { Browser, BrowserContext, Page } from 'playwright';
import {
    Action,
    GOTO_ACTION,
    CLICK_ACTION,
    SELECT_ACTION,
    FILL_ACTION,
    VERIFY_ACTION,
    WAIT_UNTIL_VERIFIED_ACTION,
    CUSTOM_ACTION
} from '@/models/action.js';
import { PageState, StorageState } from '@/models/page.js';

export async function executeTasks(tasks: Action[],
    storageState?: StorageState): Promise<PageState> {
    const browser: Browser = await chromium.launch({ headless: true })

    const context: BrowserContext = await browser.newContext({ storageState })

    const page: Page = await context.newPage()

    const pageState: PageState = {
        browser,
        context,
        page,
        storage: null
    }

    try {
        for (const task of tasks) {
            try {
                switch (task.action_type) {
                    case GOTO_ACTION:
                        await page.goto(task.action_address)

                        break

                    case CLICK_ACTION:
                        await page.click(task.action_selector)

                        break

                    case SELECT_ACTION:
                        await page.selectOption(
                            task.action_selector,
                            task.action_value
                        )

                        break

                    case FILL_ACTION:
                        await page.fill(task.action_selector, task.action_value)

                        break

                    case CUSTOM_ACTION:
                        if (task.action_address
                            && task.action_address !== page.url()) {
                            throw new Error(
                                `page address does not match:
                                    ${ task.action_address }`
                            )
                        }

                        try{
                            if (!await page
                                .evaluate<boolean>(task.action_script)) {
                                throw new Error(
                                    `custom script did not return true:
                                        ${ task.action_script }`
                                )
                            }
                        } catch (error: unknown) {
                            if (error instanceof Error) {
                                throw new Error(
                                    `custom script error: ${ error.message }`,
                                    { cause: error }
                                )

                            } else {
                                throw new Error(
                                    'custom script error', { cause: error }
                                )
                            }
                        }

                        break

                    case VERIFY_ACTION:
                        if (task.action_address
                            && task.action_address !== page.url()) {
                            throw new Error(
                                `page address does not match: ${ task.action_address }`
                            )
                        }

                        if (task.action_selector) {
                            const element = await page.$(task.action_selector)

                            if (!element) {
                                throw new Error(
                                    `element not found: ${task.action_selector}`
                                )
                            }

                            if (task.action_value) {
                                const text = await element.textContent()

                                const value = await element.inputValue()

                                if (![text, value].includes(task.action_value)) {
                                    throw new Error(
                                        `element text or value does not match:
                                            ${ task.action_selector }`
                                    )
                                }
                            }
                        }

                        if( !task.action_address
                            && !task.action_selector
                            && !task.action_value ) {
                            throw new Error(
                                'action criteria are required to verify action'
                            )
                        }

                        break

                    case WAIT_UNTIL_VERIFIED_ACTION:
                        if (task.action_address
                            && task.action_address !== page.url()) {
                            throw new Error(
                                `page address does not match:
                                    ${ task.action_address }`
                            )
                        }

                        if (task.action_selector) {
                            const element = await page.waitForSelector(
                                task.action_selector,
                                {
                                    state: 'visible',
                                    timeout: task.action_delay
                                }
                            )

                            if (!element) {
                                throw new Error(
                                    `element not found: ${ task.action_selector }`
                                )
                            }

                            if (task.action_value) {
                                const text = await element.textContent()

                                const value = await element.inputValue()

                                if (![text, value].includes(task.action_value)) {
                                    throw new Error(
                                        `element text or value does not match:
                                            ${ task.action_selector }`
                                    )
                                }
                            }
                        }

                        if( !task.action_address
                            && !task.action_selector
                            && !task.action_value ) {
                            throw new Error(
                                'action criteria are required to verify action'
                            )
                        }

                        break
                }
            } catch (error: unknown) {
                throw error
            }
        }
    } finally {
        pageState.storage = await context.storageState()

        await browser.close()
    }

    return pageState
}
