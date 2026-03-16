import { chromium } from 'playwright';
import type { Browser, BrowserContext, Page, StorageState } from 'playwright';
import { Action,
    GOTO_ACTION,
    CLICK_ACTION,
    SELECT_ACTION,
    FILL_ACTION,
    VERIFY_ACTION,
    WAIT_UNTIL_VERIFIED_ACTION,
    CUSTOM_ACTION
} from '@/models/action.js';



export async function executeTasks(tasks: Action[],
    storageState: StorageState): Promise<PageState> {
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

                    case FILL_ACTION:
                        await page.fill(task.selector, task.value)

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
