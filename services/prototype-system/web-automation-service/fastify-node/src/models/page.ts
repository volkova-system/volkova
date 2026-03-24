import { Browser, BrowserContext, Page } from "playwright"

export type StorageState = Awaited<ReturnType<BrowserContext['storageState']>>

export type PageState = {
    browser: Browser
    context: BrowserContext
    page: Page
    storage: StorageState | null
}
