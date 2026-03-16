import { Browser, BrowserContext, Page } from "playwright"

export type PageState = {
    browser: Browser
    context: BrowserContext
    page: Page
    storage: StorageState
}
