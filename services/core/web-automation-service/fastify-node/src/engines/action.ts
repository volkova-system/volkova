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
                switch (task.action) {
                    case GOTO_ACTION:
                        await page.goto(task.address)

                        break

                    case CLICK_ACTION:
                        await page.click(task.selector)

                        break

                    case SELECT_ACTION:
                        await page.selectOption(task.selector, task.value)

                        break

                    case FILL_ACTION:
                        await page.fill(task.selector, task.value)

                        break

                    case CUSTOM_ACTION:
                        if (task.address && task.address !== page.url()) {
                            throw new Error(
                                `page address does not match: ${ task.address }`
                            )
                        }

                        try{
                            if (!await page.evaluate<boolean>(task.script)) {
                                throw new Error(
                                    `custom script did not return true:
                                        ${ task.script }`
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
                        if (task.address && task.address !== page.url()) {
                            throw new Error(
                                `page address does not match: ${ task.address }`
                            )
                        }

                        if (task.selector) {
                            const element = await page.$(task.selector)

                            if (!element) {
                                throw new Error(
                                    `element not found: ${task.selector}`
                                )
                            }

                            if (task.value) {
                                const text = await element.textContent()

                                const value = await element.inputValue()

                                if (![text, value].includes(task.value)) {
                                    throw new Error(
                                        `element text or value does not match:
                                            ${ task.selector }`
                                    )
                                }
                            }
                        }

                        if( !task.address && !task.selector && !task.value ) {
                            throw new Error(
                                'action criteria are required to verify action'
                            )
                        }

                        break

                    case WAIT_UNTIL_VERIFIED_ACTION:
                        if (task.address && task.address !== page.url()) {
                            throw new Error(
                                `page address does not match: ${ task.address }`
                            )
                        }

                        if (task.selector) {
                            const element = await page.waitForSelector(
                                task.selector,
                                {
                                    state: 'visible',
                                    timeout: task.delay
                                }
                            )

                            if (!element) {
                                throw new Error(
                                    `element not found: ${ task.selector }`
                                )
                            }

                            if (task.value) {
                                const text = await element.textContent()

                                const value = await element.inputValue()

                                if (![text, value].includes(task.value)) {
                                    throw new Error(
                                        `element text or value does not match:
                                            ${ task.selector }`
                                    )
                                }
                            }
                        }

                        if( !task.address && !task.selector && !task.value ) {
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
