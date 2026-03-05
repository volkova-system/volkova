import type { Meta, StoryObj } from "@storybook/html";

const meta: Meta = { title: "Concise/Complex/Label" };
export default meta;

type Story = StoryObj;

export const ColorRed: Story = {
  render: () => `
    <span hx-get="/stories/concise/complex/label/label.component.html"
        hx-trigger="load"
        hx-swap="outerHTML">
    </span>
  `
};
