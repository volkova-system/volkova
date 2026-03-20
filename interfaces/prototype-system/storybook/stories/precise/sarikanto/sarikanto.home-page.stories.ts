import type { Meta, StoryObj } from "@storybook/html";

const meta: Meta = { title: "Precise/Sarikanto/Home" };
export default meta;

type Story = StoryObj;

export const SarikantoHome: Story = {
  render: () => `
    <div hx-get="/stories/precise/sarikanto/pages/sarikanto.home-page.html"
        hx-trigger="load"
        hx-swap="outerHTML">
    </div>
  `
};
