import type { Meta, StoryObj } from "@storybook/html";

const meta: Meta = { title: "Precise/Neilro Jhon Llaban/Home" };
export default meta;

type Story = StoryObj;

export const NeilroJhonLlabanHome: Story = {
  render: () => `
    <div hx-get="/stories/precise/neilrojhon-llaban/pages/neilrojhon-llaban.home-page.html"
        hx-trigger="load"
        hx-swap="outerHTML">
    </div>
  `
};
