import type { StorybookConfig } from "@storybook/html-vite";

const config: StorybookConfig = {
    stories: [
        "../stories/**/*.stories.ts"
    ],
    framework: {
        name: "@storybook/html-vite",
        options: {}
    },
    addons: [],
    staticDirs: [
        "../public"
    ],
    viteFinal: async (viteConfig) => {
        // This the suggested tweak for Storybook to work with Windows properly
        viteConfig.server ??= {};
        viteConfig.server.watch = {
            usePolling: true,
            interval: 200
        };

        return viteConfig;
    }
};

export default config;
