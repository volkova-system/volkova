import type { Meta, StoryObj } from "@storybook/html";

const meta: Meta = { title: "Concise Components/Typography" };
export default meta;

type Story = StoryObj;

export const Typography: Story = {
  render: () => `
    <main
        class="
            content-tree
            list
        "

        hx-get="/stories/typography-base.component.html"
        hx-trigger="load"
        hx-swap="innerHTML"
    >
    </main>
  `
};
