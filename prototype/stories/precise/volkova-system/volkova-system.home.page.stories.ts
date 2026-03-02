import type { Meta, StoryObj } from "@storybook/html";

const meta: Meta = { title: "Precise/Volkova System/Home" };
export default meta;

type Story = StoryObj;

export const VolkovaSystemHome: Story = {
  render: () => `
    <div hx-get="/pages/volkova-system.home.page.html"
        hx-trigger="load"
        hx-swap="outerHTML">
    </div>
  `
};
