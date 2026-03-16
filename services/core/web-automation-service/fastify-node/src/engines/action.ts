import { chromium } from 'playwright';
import { Action,
    GOTO_ACTION,
    CLICK_ACTION,
    SELECT_ACTION,
    FILL_ACTION,
    VERIFY_ACTION,
    WAIT_UNTIL_VERIFIED_ACTION,
    CUSTOM_ACTION
} from '@/models/action.js';

export async function executeTasks(tasks: Action[]) {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();
  const page = await context.newPage();

  try {
    for (const task of tasks) {
      try {
        switch (task.action) {
          case GOTO_ACTION:
            await page.goto(task.address);

            break;

          case CLICK_ACTION:
            await page.click(task.selector);

            break;

          case FILL_ACTION:
            await page.fill(task.selector, task.value);

            break;
        }
      } catch (error: unknown) {

        break;
      }
    }
  } finally {
    await browser.close();
  }
}
