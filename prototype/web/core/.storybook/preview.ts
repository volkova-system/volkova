import type { Preview } from "@storybook/html";

const preview: Preview = {
    parameters: { layout: "fullscreen" },
    decorators: [(story) => {
        document.body.classList.toggle('concise-component', true);
        return story();
    }]
};

export default preview;
